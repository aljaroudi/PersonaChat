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

        static var onboarding: String {
                """
                Welcome to PersonaChat! 🎉
                
                I'm your magical storytelling companion. Choose from different personas, each with their own unique personality and style:
                
                🧚‍♀️ **Luna** - A whimsical fairy who sprinkles wonder and cheer
                🛡️ **Sir Gallop** - A brave knight ready for kind quests
                🐒 **Bananas** - A silly monkey who loves giggles and fun
                🧜🏼‍♀️ **Aqua** - A calm mermaid guide to ocean adventures
                🤖 **Gizmo** - An upbeat robot inventor who loves to tinker
                🐱 **Whiskers** - A curious kitten ready to explore
                
                Simply type your message and I'll create an interactive story just for you! You can switch between personas anytime using the menu above.
                
                Ready to begin your adventure? Just tell me what kind of story you'd like to hear! ✨
                """
        }
    }


}

typealias Message = DataSchema.Message

enum MessageRole: String, Codable {
    case user
    case bot
}

let CURRENT_ONBOARDING_VERSION = "1.0"
