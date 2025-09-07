//
//  ChatView.swift
//  PersonaChat
//
//  Created by Mohammed on 8/12/25.
//

import SwiftUI
import SwiftData

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
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(.rect(cornerRadius: 20))
                    .padding()
                }
            }
        }
        .onChange(of: selectedPersonaID) { clearChat() }
        .navigationTitle(selectedPersona.emoji + " " + selectedPersona.name)
        .toolbarTitleMenu {
            Picker("Persona", selection: $selectedPersonaID) {
                ForEach(PERSONAS, id: \.id) { persona in
                    Text("\(persona.emoji)  \(persona.name)").tag(persona.id)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear Chat", systemImage: "square.and.pencil", action: clearChat)
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }

    @MainActor
    private func addMessage() {
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let message = Message(role: .user,text: text)
        modelContext.insert(message)
        try? modelContext.save()

        guard #available(iOS 26.0, *) else { return }

        let aiMessage = Message(role: .bot, text: "...")

        modelContext.insert(aiMessage)

        let stream = stream(messages, prompt: selectedPersona.fullPrompt)

        Task {
            for await msg in stream {
                aiMessage.text = msg
                try? modelContext.save()
            }
        }

        text = ""
        isTextFieldFocused = true

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

