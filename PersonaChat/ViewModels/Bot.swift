//
//  LLMVM.swift
//  PersonaChat
//
//  Created by Mohammed on 9/10/25.
//

import LLM
import SwiftUI
import SwiftData

enum BotError: Swift.Error {
    case notFound, notLoaded, noOutput, persistanceFailed
}

@MainActor
@Observable
final class Bot {
    var isGenerating = false

    private let bot: LLM
    private let context: ModelContext

    init(context: ModelContext) throws(BotError) {
        guard let url = Bundle.main.url(forResource: "gemma-3-1b-it-UD-Q3_K_XL", withExtension: "gguf")
        else { throw .notFound }

        guard let bot = LLM(from: url, template: Template(
            system: ("<start_of_turn>system\n", "<end_of_turn>\n"),
            user:   ("<start_of_turn>user\n",   "<end_of_turn>\n"),
            bot:    ("<start_of_turn>model\n",  "<end_of_turn>\n"),
            stopSequence: "<end_of_turn>",
            systemPrompt: GENERAL_SYSTEM_PROMPT
        ))
        else { throw .notLoaded }

        self.bot = bot
        self.context = context
    }

    func set(persona: Persona) {
        bot.template = persona.template
    }

    func ask(
        _ prompt: String,
        _ messages: [Message]
    ) async throws(BotError) -> Message {
        guard !isGenerating, !prompt.isEmpty else { 
            throw BotError.noOutput 
        }
        isGenerating = true
        defer { isGenerating = false }

        // Prepare data
        bot.history = messages.map { msg in
            (msg.role == .user ? .user : .bot, msg.text)
        }

        let userMessage = Message(role: .user, text: prompt)
        let assistant = Message(role: .bot, text: "")
        
        // Insert messages
        context.insert(userMessage)
        context.insert(assistant)

        print("History limit: \(bot.historyLimit)")


        do {
            try context.save()
        } catch {
            throw BotError.persistanceFailed
        }

        var sawAnyChunk = false

        // Stream response
        await bot.respond(to: prompt) { [self] stream in
            for await chunk in stream {
                sawAnyChunk = true
                assistant.text += chunk
                try? context.save()
            }
            return assistant.text
        }

        if !sawAnyChunk {
            throw BotError.noOutput
        }

        do {
            try context.save()
            return assistant
        } catch {
            throw BotError.persistanceFailed
        }
    }

    func stop() { bot.stop() }
}

private extension Persona {
    var template: Template {
        .init(
            system: ("<start_of_turn>system\n", "<end_of_turn>\n"),
            user:   ("<start_of_turn>user\n",   "<end_of_turn>\n"),
            bot:    ("<start_of_turn>model\n",  "<end_of_turn>\n"),
            stopSequence: "<end_of_turn>",
            systemPrompt: self.fullPrompt
        )
    }
}
