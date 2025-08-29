//
//  PersonaChatApp.swift
//  PersonaChat
//
//  Created by Mohammed on 8/29/25.
//

import SwiftUI
import SwiftData

@main
struct PersonaChatApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(DataSchema.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ChatsView()
        }
        .modelContainer(sharedModelContainer)
    }
}
