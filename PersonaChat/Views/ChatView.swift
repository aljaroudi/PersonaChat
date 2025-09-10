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

    private var selectedPersona: Persona {
        PERSONAS.first { $0.id == selectedPersonaID } ?? PERSONAS[0]
    }

    @State
    private var bot: Bot?

    @State
    private var showError = false

    var body: some View {
        ZStack {

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(messages) { message in
                            MessageRow(message)
                                .tag(message.id)
                        }
                    }
                    .padding(.bottom, 80)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }
            VStack {
                Spacer()

                if #available(iOS 26.0, macOS 26.0, *) {
                    HStack {
                        TextField("Type a message...", text: $text)
                            .onSubmit(addMessage)
                            .focused($isTextFieldFocused)
                            .submitLabel(.send)
                            .textFieldStyle(.plain)
                            .disabled(bot?.isGenerating ?? false)

                        if bot?.isGenerating == true {
                            Button("Stop", systemImage: "square.fill") {
                                bot?.stop()
                            }.labelStyle(.iconOnly)
                        }
                    }
                    .padding()
                    .glassEffect(.regular.interactive())
                    .padding()
                } else {
                    HStack {
                        TextField("Type a message...", text: $text)
                            .onSubmit(addMessage)
                            .focused($isTextFieldFocused)
                            .submitLabel(.send)
                            .textFieldStyle(.plain)
                            .disabled(bot?.isGenerating ?? false)

                        if bot?.isGenerating == true {
                            Button("Stop", systemImage: "square.fill") {
                                bot?.stop()
                            }.labelStyle(.iconOnly)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(.rect(cornerRadius: 20))
                    .padding()
                }
            }
        }
        .onChange(of: selectedPersonaID) {
            clearChat()
            bot?.set(persona: selectedPersona)
        }
        .task {
            // lazy init once we have a ModelContext in scope
            if bot == nil {
                bot = try! .init(context: modelContext)
            }
        }
        .alert("Error responding", isPresented: $showError) {}
        .navigationTitle(selectedPersona.emoji + " " + selectedPersona.name)
        .toolbarTitleMenu {
            Picker("Persona", selection: $selectedPersonaID) {
                ForEach(PERSONAS, id: \.id) { persona in
                    Text("\(persona.emoji)  \(persona.name)").tag(persona.id)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Clear Chat", systemImage: "square.and.pencil", action: clearChat)
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }

    private func addMessage() {
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        bot?.ask(
            text,
            messages,
            onComplete: { _ in
                isTextFieldFocused = true
            },
            onError: { _ in
                showError = true
            }
        )
        text = ""
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = messages.last else { return }
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(last.id, anchor: .bottom)
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

