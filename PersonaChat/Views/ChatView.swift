//
//  ChatView.swift
//  PersonaChat
//
//  Created by Mohammed on 8/12/25.
//

import SwiftUI

struct ChatView: View {

    let chat: Chat

    @State
    private var text = ""

    var body: some View {
        ZStack {

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(chat.messages.sorted { $0.date < $1.date }) { message in

                        if message.role == .user {
                            HStack {
                                Spacer()
                                Text(message.text)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(.rect(cornerRadius: 20))
                            }
                            .padding()
                        } else {
                            Text(message.text)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 80)
            }
            VStack {
                Spacer()

                if #available(iOS 26.0, macOS 26.0, *) {
                    HStack {
                        TextField("Type a message...", text: $text)
                            .onSubmit(addMessage)

                        Button("Send", systemImage: "arrow.up.circle.fill") {
                            addMessage()
                        }
                        .imageScale(.large)
                        .labelStyle(.iconOnly)
                    }
                    .padding()
                    .glassEffect(.regular.interactive())
                    .padding()
                } else {
                    HStack {
                        TextField("Type a message...", text: $text)
                            .onSubmit(addMessage)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(.rect(cornerRadius: 20))
                    .padding()
                }
            }
        }
    }

    private func addMessage() {
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let message = Message(
            in: chat,
            role: .user,
            text: text
        )
        
        chat.messages.append(message)



//        AI
        if #available(iOS 26.0, *) {

            let aiMessage = Message(
                in: chat,
                role: .bot,
                text: "Loading..."
            )

            chat.messages.append(aiMessage)

            let stream = stream(chat.messages)

            Task {
                for await msg in stream {
                    aiMessage.text = msg
                    print("RESPONSE: \(msg)")
                }
            }
        } else {
            // Fallback on earlier versions
        }

    }
}

#Preview {
    let chat = Chat("Test")
    let msg: Message = .init(in: chat, role: .user, text: "Hi")
    chat.messages.append(msg)
    let reply: Message = .init(in: chat, role: .bot, text: "Hey!")
    chat.messages.append(reply)
    return ChatView(chat: chat)
}

