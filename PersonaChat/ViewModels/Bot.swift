//
//  LLMVM.swift
//  PersonaChat
//
//  Created by Mohammed on 9/10/25.
//

import LLM
import SwiftUI
import SwiftData

enum BotError: Error {
    case notFound, notLoaded, noOutput, persistenceFailed
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
        prompt: String,
        response: Message,
        history messages: [Message]
    ) async throws(BotError) {
        guard !isGenerating, !prompt.isEmpty else { 
            throw BotError.noOutput 
        }
        isGenerating = true
        defer { isGenerating = false }

        // Prepare data
        bot.history = messages.map { msg in
            (msg.role == .user ? .user : .bot, msg.text)
        }

        do {
            try context.save()
        } catch {
            throw .persistenceFailed
        }

        var sawAnyChunk = false

        // Stream response
        await bot.respond(to: prompt) { [self] stream in
            for await chunk in stream {
                sawAnyChunk = true
                response.text += chunk
                try? context.save()
            }
            return response.text
        }

        if !sawAnyChunk {
            throw BotError.noOutput
        }

        do {
            try context.save()
        } catch {
            throw .persistenceFailed
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
