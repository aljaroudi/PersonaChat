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
    _ messages: [Message],
    prompt: String
) -> AsyncStream<String> {

    let transcript = Transcript(
        entries: messages.asTranscript(with: prompt)
    )


    return AsyncStream { cont in

        let task = Task {
            do {
                let history = messages.map {
                    "\($0.role.rawValue): \($0.text)\n\n"
                }.joined()

                let session = LanguageModelSession(transcript: transcript)

                let stream = session.streamResponse(to: history, options: .init(temperature: 0.7))

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


fileprivate extension Array where Element == Message {
    func asTranscript(with instructions: String) -> Transcript {
        var entries: [Transcript.Entry] = [
            instructions.asInstructions
        ]

        for message in self {
            let seg: Transcript.Segment = .text(.init(content: message.text))
            switch message.role {
            case .user: entries.append(.prompt(.init(segments: [seg])))
            case .bot: entries.append(.response(.init(assetIDs: [], segments: [seg])))
            }
        }

        return Transcript(entries: entries)
    }
}

fileprivate extension String {
    var asInstructions: Transcript.Entry {
        .instructions(Transcript.Instructions(segments: [.text(.init(content: self))], toolDefinitions: []))
    }
}
