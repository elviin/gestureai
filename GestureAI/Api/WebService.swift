//
//  WebService.swift
//  GestureAI
//
//  Created by Vladimír Slavík on 06.03.24.
//

import Foundation
import ChatGPTSwift

struct Instruction: Decodable {
	let id: UUID
	let key: String?
}

struct Answer {
	let string: String
	let instruction: Instruction?
}

class WebService: ObservableObject {
	let offline = false
	let api = ChatGPTAPI(apiKey: "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") // example, create yours in Open AI API section

	public func sendMessage(text: String,
							model: String = ChatGPTAPI.Constants.defaultModel,
							systemText: String = ChatGPTAPI.Constants.defaultSystemText,
							temperature: Double = ChatGPTAPI.Constants.defaultTemperature) async throws -> Answer {
		guard !offline else {
			return Answer(string: "WebService: offline mode. To switch back to online, disable the offline property.", instruction: nil)
		}
		let answer = try await api.sendMessage(text: text, model: model, systemText: systemText, temperature: temperature)
		print("answer from GPT: \(answer)")
		let sanitatedAnswer = answer.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")

		guard let jsonData = sanitatedAnswer.data(using: .utf8) else {
			return Answer(string: sanitatedAnswer, instruction: nil)
		}
		guard let parsedInstruction = try? JSONDecoder().decode(Instruction.self, from: jsonData) else {
			return Answer(string: sanitatedAnswer, instruction: nil)
		}

		return Answer(string: "OK", instruction: parsedInstruction)
	}

	public func deleteHistoryList() {
		api.deleteHistoryList()
	}

	private static func isStringValidJson(_ string: String) -> Bool {
		guard let jsonData = string.data(using: String.Encoding.utf8) else { return false }
		return JSONSerialization.isValidJSONObject(jsonData)
	}
}
