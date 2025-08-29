//
//  DataSchema.swift
//  PersonaChat
//
//  Created by Mohammed on 8/12/25.
//

import Foundation
import SwiftData

enum DataSchema: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [
            Chat.self,
            Message.self,
        ]
    }

    static var versionIdentifier = Schema.Version(1, 0, 0)

    @Model
    final class Chat: Identifiable {
        private(set) var id: UUID
        private(set) var date: Date
        private(set) var title: String

        @Relationship(deleteRule: .cascade, inverse: \Message.chat)
        var messages: [Message]

        init(_ title: String) {
            self.id = .init()
            self.date = .now
            self.title = title
            self.messages = []
        }

    }

    @Model
    final class Message: Identifiable {
        private(set) var id: UUID
        private(set) var date: Date
        private(set) var role: MessageRole
        var text: String

        // Relationship
        private(set) var chat: Chat

        init(in chat: Chat, role: MessageRole, text: String) {
            self.id = .init()
            self.date = .now
            self.text = text
            self.role = role
            self.chat = chat
        }
    }


}

typealias Chat = DataSchema.Chat
typealias Message = DataSchema.Message

enum MessageRole: String, Codable {
    case user
    case bot
}
