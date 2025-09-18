//
//  ChatView.swift
//  PersonaChat
//
//  Created by Mohammed on 8/12/25.
//

import SwiftUI
import SwiftData
import LLM

struct ChatView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \Message.date)
    private var messages: [Message]

    @State
    private var text = ""

    @FocusState
    private var isTextFieldFocused: Bool

    @AppStorage("selectedPersonaID")
    private var selectedPersonaID = PERSONAS.first?.id ?? "luna"

    @AppStorage("onboardingVersion")
    private var onboardingVersion: String?

    private var selectedPersona: Persona {
        PERSONAS.first { $0.id == selectedPersonaID } ?? PERSONAS[0]
    }

    /// Show onboarding message if it hasn't been shown and chat is empty (excluding the persona's initial message)
    private var shouldShowOnboarding: Bool {
        onboardingVersion != CURRENT_ONBOARDING_VERSION && messages.count == 1
    }

    @State
    private var bot: Bot?

    @State
    private var textFieldHeight: CGFloat = 0

    @State
    private var scrollTrigger: Int = 0

    @State
    private var hapticTrigger: Int = 0

    /// Text to speach mode
    @State
    private var tts = true

    @State
    private var isTranscribing = false

    private let transcribe = SpeechRecognizer()

    var body: some View {
        mainContent
            .background(backgroundView)
            .onChange(of: selectedPersonaID) {
                clearChat()
                bot?.set(persona: selectedPersona)
            }
            .navigationTitle(selectedPersona.emoji + " " + selectedPersona.name)
            .toolbarTitleMenu { personaPicker }
            .toolbar { toolbarContent }
            .toolbarTitleDisplayMode(.inline)
            .font(.custom(selectedPersona.fontName, size: 18, relativeTo: .body))
            .onChange(of: isTextFieldFocused) { _, isFocused in
                handleTextFieldFocus(isFocused)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
    }

    private var mainContent: some View {
        ZStack {
            chatScrollView
            inputArea
        }
    }

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(messages) { message in
                        MessageRow(message)
                            .tag(message.id)
                    }
                }
                .padding(.bottom, textFieldHeight + 20)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: bot?.isGenerating) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: textFieldHeight) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: scrollTrigger) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .task {
                await handleTask(proxy: proxy)
            }
        }
    }

    private var inputArea: some View {
        VStack {
            Spacer()
            inputField
        }
    }

    private var inputField: some View {
        HStack {
            TextField("Type a message...", text: $text)
                .onSubmit(addMessage)
                .focused($isTextFieldFocused)
                .submitLabel(.send)
                .textFieldStyle(.plain)
                .disabled((bot?.isGenerating ?? false))

            if bot?.isGenerating == true {
                Button("Stop", systemImage: "square.fill") {
                    bot?.stop()
                }.labelStyle(.iconOnly)
            } else {
                Button(
                    isTranscribing
                    ? "Stop"
                    : "Record",
                    systemImage: isTranscribing ? "square.fill" : "mic"
                ) {
                    transcribe.start { txt in
                        text = txt
                    } onFinish: {
                        isTranscribing = false
                    }
                    isTranscribing = true
                }
                .labelStyle(.iconOnly)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .padding()
        .background(textFieldHeightReader)
    }

    private var textFieldHeightReader: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    textFieldHeight = geometry.size.height
                }
                .onChange(of: geometry.size.height) { _, newHeight in
                    if newHeight > 0 {
                        textFieldHeight = newHeight
                    }
                }
        }
    }

    private var backgroundView: some View {
        ZStack {
            Image(selectedPersona.backgroundImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Rectangle()
                .fill(.ultraThickMaterial.opacity(0.95))
                .ignoresSafeArea()
        }
    }

    private var personaPicker: some View {
        Picker("Persona", selection: $selectedPersonaID) {
            ForEach(PERSONAS, id: \.id) { persona in
                Text("\(persona.emoji)  \(persona.name)")
                    .tag(persona.id)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
#if os(macOS)
        ToolbarItem {
            Picker("Persona", selection: $selectedPersonaID) {
                ForEach(PERSONAS, id: \.id) { persona in
                    Text("\(persona.emoji)  \(persona.name)")
                        .font(persona.font)
                        .tag(persona.id)
                }
            }
            .pickerStyle(.menu)
        }
#endif
        ToolbarItem(placement: .topBarLeading) {
            Button(
                "Speaker on",
                systemImage: tts ? "speaker.wave.2" : "speaker",
                action: { tts.toggle() }
            )
        }
        ToolbarItem {
            Button("Clear Chat", systemImage: "square.and.pencil", action: clearChat)
        }
    }

    @MainActor
    private func handleTask(proxy: ScrollViewProxy) async {
        // lazy init once we have a ModelContext in scope
        if bot == nil {
            bot = try! .init(context: modelContext) {
                hapticTrigger += 1
            }
        }

        // Show onboarding message with typing simulation
        if shouldShowOnboarding {
            await showOnboardingWithTyping()
            scrollToBottom(proxy: proxy)
        }
    }

    private func handleTextFieldFocus(_ isFocused: Bool) {
        guard isFocused else { return }
        // Scroll to bottom when text field is focused
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            scrollTrigger += 1
        }
    }

    @MainActor
    private func showOnboardingWithTyping() async {
        let onboardingMessage = Message(role: .bot, text: "")
        modelContext.insert(onboardingMessage)
        try? modelContext.save()

        // Simulate typing effect
        let fullText = Message.onboarding

        for i in 0...fullText.count {
            onboardingMessage.text = String(fullText.prefix(i))
            try? modelContext.save()

            scrollTrigger += 1
            hapticTrigger += 1

            // Vary typing speed for more realistic effect
            let delay = fullText[fullText.index(fullText.startIndex, offsetBy: min(i, fullText.count - 1))] == " " ? 0.05 : 0.03
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        onboardingVersion = CURRENT_ONBOARDING_VERSION
    }

    private func addMessage() {
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let prompt = Message(role: .user, text: text)
        let response = Message(role: .bot, text: "")
        modelContext.insert(prompt)
        modelContext.insert(response)
        do { try modelContext.save() }
        catch { return }

        // Clear text immediately
        text = ""

        Task {
            do {
                try await bot?.ask(
                    prompt: prompt.text,
                    response: response,
                    history: messages
                )
                isTextFieldFocused = true
            } catch {

                bot = try? .init(context: modelContext) {
                    hapticTrigger += 1
                }

                do {
                    try await bot?.ask(
                        prompt: prompt.text,
                        response: response,
                        history: messages
                    )
                } catch {
                    response.text += ".. Oops, something went wrong!"
                    try? self.modelContext.save()
                }
                response.text.speak()
            }
        }

    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = messages.last else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(last.id, anchor: .top)
            }
        }
    }

    @MainActor
    private func clearChat() {
        bot?.stop()
        try? modelContext.delete(model: Message.self)
        modelContext.insert(Message(
            role: .bot,
            text: selectedPersona.greeting
        ))
        try? modelContext.save()
    }
}


#Preview {
    NavigationStack {
        ChatView()
    }
}

