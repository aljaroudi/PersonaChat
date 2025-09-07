//
//  MessageRow.swift
//  PersonaChat
//
//  Created by Mohammed on 9/7/25.
//

import SwiftUI

struct MessageRow: View {

    let message: Message

    init(_ message: Message) {
        self.message = message
    }

    var body: some View {
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
            MaybeMarkdown(message.text)
                .padding(.horizontal)
        }
    }
}

#Preview {
    MessageRow(Message(role: .user, text: "Hello, world!"))
}
