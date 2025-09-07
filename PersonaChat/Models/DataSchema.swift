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
            Message.self,
        ]
    }

    static var versionIdentifier = Schema.Version(1, 0, 0)

    @Model
    final class Message: Identifiable {
        private(set) var id: UUID
        private(set) var date: Date
        private(set) var role: MessageRole
        var text: String

        init(role: MessageRole, text: String) {
            self.id = .init()
            self.date = .now
            self.text = text
            self.role = role
        }
    }


}

typealias Message = DataSchema.Message

enum MessageRole: String, Codable {
    case user
    case bot
}
