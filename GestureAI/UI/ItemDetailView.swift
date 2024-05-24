//
//  ItemDetailView.swift
//  GestureAI
//
//  Created by Vladimír Slavík on 12.03.24.
//

import Foundation
import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject var appState: AppState
	@EnvironmentObject var webservice: WebService
	@EnvironmentObject var frameTracker: GlobalFrameTracker
	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
	@State var instructionsSent = false
	var item: Item

	var body: some View {
		VStack {
			Image(item.imageName)
				.resizable()
				.scaledToFit()
				.frame(width: 200, height: 200)
			Text(item.name)
				.font(.headline)
			Text(item.description)
				.font(.subheadline)
		}
		.padding()
		.navigationBarTitle(Text(item.name), displayMode: .inline)
		.navigationBarBackButtonHidden(true) // Hide the default back button
		.toolbar(content: {
			ToolbarItem(placement: .navigationBarLeading) {
				Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
					Image(systemName: "chevron.backward")
						.aspectRatio(contentMode: .fit)
						.foregroundColor(.blue)
				}
				.annotate(label: "The main back button. You can use this button to go back from this detail screen.", command: { _ in 
                    self.presentationMode.wrappedValue.dismiss()
				}, type: .button, screen: "Detail")
			}
		})
		.onAppear {
			Task { @MainActor in
				try await Task.sleep(for: .seconds(1.0))
				do {
					if instructionsSent == false {
						instructionsSent = true

						let mapResponse = try await webservice.sendMessage(text: frameTracker.mapInstructions(screen: "Detail"))
						print("ChatGPT: \(mapResponse)")
					}
					let mapResponse = try await webservice.sendMessage(text: "You are now in the screen called: Detail. Reply just 'OK - DETAIL SCREEN'.")
					print("ChatGPT: \(mapResponse)")
				} catch {
					print(error.localizedDescription)
				}
			}
		}
        .onDisappear {
            // Signal that we need to refresh the llm context to the main screen.
            appState.needsRefresh = true
        }
	}
}
