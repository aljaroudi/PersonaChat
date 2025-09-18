//
//  Transcribe.swift
//  PersonaChat
//
//  Created by Mohammed on 9/18/25.
//

import Speech
import AVFoundation

final class SpeechRecognizer {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func start(onUpdate: @escaping (String) -> Void, onFinish: (() -> Void)? = nil) {
        Task {
            guard await Self.requestAuth(), let recognizer, recognizer.isAvailable else {
                onFinish?()
                return
            }

            do {
                try configureSession()

                let r = SFSpeechAudioBufferRecognitionRequest()
                r.shouldReportPartialResults = true
                request = r

                let input = audioEngine.inputNode
                let format = input.outputFormat(forBus: 0)
                input.removeTap(onBus: 0)
                input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buf, _ in
                    self?.request?.append(buf)
                }

                audioEngine.prepare()
                try audioEngine.start()

                task = recognizer.recognitionTask(with: r) { result, error in
                    if let text = result?.bestTranscription.formattedString {
                        onUpdate(text)   // <-- callback with transcript
                    }
                    if result?.isFinal == true || error != nil {
                        self.stop()
                        onFinish?()
                    }
                }
            } catch {
                onFinish?()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private static func requestAuth() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
    }

    private func configureSession() throws {
        let s = AVAudioSession.sharedInstance()
        try s.setCategory(.record, mode: .measurement, options: .duckOthers)
        try s.setActive(true, options: .notifyOthersOnDeactivation)
    }
}
