//
//  ContentView.swift
//  GestureAI
//
//  Created by Vladimír Slavík on 15.02.24.
//

import SwiftUI
import ChatGPTSwift

class AppState: ObservableObject {
    @Published var needsRefresh: Bool = false
    @Published var defaultInstructionsSet: Bool = false
}

extension View {
	@ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
		if condition {
			transform(self)
		} else {
			self
		}
	}
}

struct ContentView: View {
	@State var lastSentence: String?
	@State var gesture: String?
    @StateObject var appState = AppState()
	@StateObject var webservice = WebService()
	@StateObject var speech2Text = Speech2Text()
	@StateObject var frameTracker = GlobalFrameTracker()
    var body: some View {
		ZStack {
			OnlineShopView()
				.environmentObject(frameTracker)
				.environmentObject(webservice)
                .environmentObject(appState)
		}
			.onReceive(speech2Text.$transcript) { sentence in
				guard !sentence.isEmpty else {
					return
				}
				guard lastSentence != sentence else {
					// avoid repeating requests to the chat API
					return
				}
				lastSentence = sentence
				print("Command: \(sentence)")
				Task {
					do {
						let response = try await webservice.sendMessage(text: sentence)
						print("ChatGPT: \(response)")
						if 	let instruction = response.instruction,
							let command = frameTracker.commands[instruction.id] {
                            if let key = instruction.key {
								command(.string(key))
							} else {
								command(.none)
							}
						}
					} catch {
						print(error.localizedDescription)
					}
				}
			}
			.onAppear {
				speech2Text.resetTranscript()
				speech2Text.startTranscribing()
			}
			.onDisappear {
				speech2Text.stopTranscribing()
			}
    }
}
