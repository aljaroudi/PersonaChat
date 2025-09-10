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
        _ messages: [Message],
        onComplete: (@MainActor @Sendable (_ msg: Message) -> Void)? = nil,
        onError: (@MainActor @Sendable (_ err: BotError) -> Void)? = nil
    ) {
        guard !isGenerating, !prompt.isEmpty else { return }
        isGenerating = true

        bot.history = messages.map { msg in
            (msg.role == .user ? .user : .bot, msg.text)
        }

        context.insert(Message(role: .user, text: prompt))

        let assistant = Message(role: .bot, text: "")
        context.insert(assistant)

        Task { [weak self] in
            guard let self else { return }

            defer {
                Task { @MainActor in
                    self.isGenerating = false
                }
            }

            var sawAnyChunk = false
            // Stream
            await bot.respond(to: prompt) { stream in
                for await chunk in stream {
                    sawAnyChunk = true
                    await MainActor.run {
                        assistant.text += chunk
                        try? self.context.save()
                    }
                }
                return assistant.text
            }

            if !sawAnyChunk {
                await MainActor.run { onError?(.noOutput) }
                return
            }

            await MainActor.run {

                do { try self.context.save() }
                catch { onError?(.persistanceFailed) }
                onComplete?(assistant)
            }
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
