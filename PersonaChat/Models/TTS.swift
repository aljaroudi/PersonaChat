//
//  TTS.swift
//  PersonaChat
//
//  Created by Mohammed on 9/18/25.
//

import AVFoundation

extension String {
    @MainActor
    func speak(rate: Float? = nil, language: String = "en-US") {
        let utterance = AVSpeechUtterance(string: self.withoutEmojis)

        // Find the highest-quality voice
        utterance.voice = .highestQualityVoice(for: language)

        if let rate = rate {
            utterance.rate = rate
        }
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }

    fileprivate var withoutEmojis: Self {
        unicodeScalars
            .filter { !$0.properties.isEmojiPresentation && !$0.properties.isEmoji }
            .map(String.init)
            .joined()
    }
}

extension AVSpeechSynthesisVoice {
    static func highestQualityVoice(for language: String) -> AVSpeechSynthesisVoice? {
        Self.speechVoices()
            .filter { $0.language == language }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
            .first ?? AVSpeechSynthesisVoice(language: language)
    }
}
