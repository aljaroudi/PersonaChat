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
    
    @State
    private var scrollProxy: ScrollViewProxy?
    
    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(messages) { message in
                        MessageRow(message)
                            .tag(message.id)
                    }
                }
                .padding(.bottom, 20)
            }
            .onAppear {
                scrollProxy = proxy
                proxy.scroll(to: messages.last?.id)
            }
        }
    }
    
    private var textInputView: some View {
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
        .background(backgroundMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .padding()
    }
    
    @ViewBuilder
    private var backgroundMaterial: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Color.clear
                .glassEffect(.regular.interactive())
        } else {
            ZStack {
                Color.clear
                Rectangle().fill(.ultraThinMaterial)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            chatScrollView
            textInputView
        }
        .onChange(of: messages.count) { _, _ in
            scrollProxy?.scroll(to: messages.last?.id)
        }
        .onChange(of: bot?.isGenerating) { _, newValue in
            if newValue {
                scrollProxy?.scroll(to: messages.last?.id)
            }
        }
        .background(
            ZStack {
                Image(selectedPersona.backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                Rectangle()
                    .fill(.ultraThickMaterial.opacity(0.95))
                    .ignoresSafeArea()
            }
        )
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
                    Text("\(persona.emoji)  \(persona.name)")
                        .tag(persona.id)
                }
            }
        }
        .toolbar {
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
            ToolbarItem {
                Button("Clear Chat", systemImage: "square.and.pencil", action: clearChat)
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .font(.custom(selectedPersona.fontName, size: 18, relativeTo: .body))
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

        // Clear text and scroll to bottom immediately
        text = ""
        // Scroll when message is completed
        defer {
            scrollProxy?.scrollTo(response.id)
        }
        
        Task {
            do {
                try await bot?.ask(
                    prompt: prompt.text,
                    response: response,
                    history: messages
                )
                isTextFieldFocused = true
            } catch {
                
                bot = try? .init(context: modelContext)
                
                do {
                    try await bot?.ask(
                        prompt: prompt.text,
                        response: response,
                        history: messages
                    )
                } catch {
                    showError = true
                }
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

fileprivate extension ScrollViewProxy {
    func scroll<ID>(to id: ID?) where ID: Hashable {
        guard let id else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.scrollTo(id, anchor: .bottom)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}

