//
//  VoiceModel.swift
//  GestureAI
//
//  Created by Vladimír Slavík on 23.02.24.
//

import AVFoundation
import Combine
import Foundation
import Speech
import SwiftUI

class Speech2Text: ObservableObject {
	enum RecognizerError: Error {
		case nilRecognizer
		case notAuthorizedToRecognize
		case notPermittedToRecord
		case recognizerIsUnavailable

		var message: String {
			switch self {
			case .nilRecognizer: return "Can't initialize speech recognizer"
			case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
			case .notPermittedToRecord: return "Not permitted to record audio"
			case .recognizerIsUnavailable: return "Recognizer is unavailable"
			}
		}
	}

	@Published public var transcript: String = ""
	@MainActor private var pastResult: String = ""

	private var audioEngine: AVAudioEngine?
	private var request: SFSpeechAudioBufferRecognitionRequest?
	private var task: SFSpeechRecognitionTask?
	private let recognizer: SFSpeechRecognizer?

	private var restartTimer: Timer?

	init() {
		recognizer = SFSpeechRecognizer()

		guard recognizer != nil else {
			transcribe(RecognizerError.nilRecognizer)
			return
		}

		Task {
			do {
				guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
					throw RecognizerError.notAuthorizedToRecognize
				}
				guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
					throw RecognizerError.notPermittedToRecord
				}
			} catch {
				transcribe(error)
			}
		}
	}

	@MainActor func startTranscribing() {
		Task {
			transcribe()
			restartTimer?.invalidate() // Invalidate any existing timer
			restartTimer = Timer.scheduledTimer(withTimeInterval: 55, repeats: true) { [weak self] _ in
				self?.restartRecognition()
			}
		}
	}

	private func restartRecognition() {
			// Stop current recognition task
		reset()

			// Start a new recognition task
		transcribe()
	}

	@MainActor func resetTranscript() {
		Task {
			reset()
		}
	}

	@MainActor func stopTranscribing() {
		Task {
			reset() // This stops the current recognition task
			restartTimer?.invalidate() // Stops the timer
			restartTimer = nil
		}
	}

	private func transcribe() {
		guard let recognizer, recognizer.isAvailable else {
			self.transcribe(RecognizerError.recognizerIsUnavailable)
			return
		}

		do {
			let (audioEngine, request) = try Self.prepareEngine()
			self.audioEngine = audioEngine
			self.request = request
			self.task = recognizer.recognitionTask(with: request, resultHandler: { [weak self] result, error in
				self?.recognitionHandler(audioEngine: audioEngine, result: result, error: error)
			})
		} catch {
			self.reset()
			self.transcribe(error)
		}
	}


	private func reset() {
		task?.cancel()
		audioEngine?.stop()
		audioEngine = nil
		request = nil
		task = nil
	}

	private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
		let audioEngine = AVAudioEngine()

		let request = SFSpeechAudioBufferRecognitionRequest()
		request.shouldReportPartialResults = true
		// request.requiresOnDeviceRecognition = false
		request.taskHint = .dictation

		let audioSession = AVAudioSession.sharedInstance()
		try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
		try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
		let inputNode = audioEngine.inputNode

		let recordingFormat = inputNode.outputFormat(forBus: 0)
		inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
			request.append(buffer)
		}
		audioEngine.prepare()
		try audioEngine.start()

		return (audioEngine, request)
	}

	nonisolated private func recognitionHandler(audioEngine: AVAudioEngine, result: SFSpeechRecognitionResult?, error: Error?) {
		let receivedError = error != nil

		if receivedError {
			audioEngine.stop()
			audioEngine.inputNode.removeTap(onBus: 0)
		}

		if let result, result.bestTranscription.newSentenceStarted {
			Task { @MainActor in
				transcribe(result.bestTranscription.lastClosedSentence)
			}
		}
	}


	private func transcribe(_ message: String) {
		transcript = message
	}

	nonisolated private func transcribe(_ error: Error) {
		var errorMessage = ""
		if let error = error as? RecognizerError {
			errorMessage += error.message
		} else {
			errorMessage += error.localizedDescription
		}
		Task { @MainActor [errorMessage] in
			print("<< \(errorMessage) >>")
		}
	}
}

extension SFSpeechRecognizer {
	static func hasAuthorizationToRecognize() async -> Bool {
		await withCheckedContinuation { continuation in
			requestAuthorization { status in
				continuation.resume(returning: status == .authorized)
			}
		}
	}
}


extension SFTranscription {
	private static let intervalBetweenSentences: TimeInterval = 1.0

	var newSentenceStarted: Bool {
		let processed = Array(self.segments.reversed())
		guard processed.count > 1 else {
			return false
		}

		// print(processed.map { $0.substring }.joined(separator: " "))
		let last = processed[0]
		let previous = processed[1]

		var pause: TimeInterval = 0.0
		pause = last.timestamp - (previous.timestamp + previous.duration)
		if pause >= Self.intervalBetweenSentences, last.confidence > 0.0 {
			return true
		}
		return false
	}

	var lastClosedSentence: String {
		let processed = Array(self.segments.reversed())
		var wordsInSentenceReversed: [String] = []
		guard processed.count > 1 else {
			return ""
		}

		for (index, segment) in processed.enumerated() {
			wordsInSentenceReversed.append(segment.substring)

			let isFirstSegment = index == processed.count - 1
			var pause: TimeInterval = 0.0
			if isFirstSegment == false {
				let previousIndex = index + 1 // we are in reversed array
				let previousSegment = processed[previousIndex]
				pause = segment.timestamp - previousSegment.timestamp
			}

			// Once you come to a pause, stop seatching for older words.
			if (pause >= Self.intervalBetweenSentences && segment.confidence > 0.0) || isFirstSegment {
				break
			}
		}

		return wordsInSentenceReversed.reversed().joined(separator: " ")
	}
}

extension AVAudioSession {
	func hasPermissionToRecord() async -> Bool {
		await withCheckedContinuation { continuation in
			requestRecordPermission { authorized in
				continuation.resume(returning: authorized)
			}
		}
	}
}

