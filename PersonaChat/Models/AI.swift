//
//  AI.swift
//  PersonaChat
//
//  Created by Mohammed on 8/12/25.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
func stream(
    _ messages: [Message]
) -> AsyncStream<String> {

    AsyncStream { cont in

        let task = Task {
            do {
                let history = messages.map {
                    "\($0.role.rawValue): \($0.text)\n\n"
                }.joined()

                let model = SystemLanguageModel.default
                let session = LanguageModelSession(model: model)

                let stream = session.streamResponse(to: history)

                for try await token in stream {
                    cont.yield(token.content)
                }

                cont.finish()
            } catch let error {
                cont.yield("Error: \(error.localizedDescription)")
                cont.finish()
            }
        }

        cont.onTermination = { _ in task.cancel() }

    }
}
