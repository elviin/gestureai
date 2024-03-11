//
//  OnlineShopView.swift
//  GestureAI
//
//  Created by Vladimír Slavík on 12.03.24.
//

import Foundation
import SwiftUI

struct OnlineShopView: View {
	@EnvironmentObject var webservice: WebService
	@EnvironmentObject var frameTracker: GlobalFrameTracker
	@State private var instructionsSent = false
	@State private var searchText = ""
	@State private var items = [
		Item(name: "Jacket", description: "Jacket which is perfect for winter times.", imageName: "Jacket"),
		Item(name: "Watches", description: "Watches to any kind of water.", imageName: "Watches"),
		Item(name: "Baggage", description: "Baggage that is perfect for your holiday.", imageName: "Baggage"),
		Item(name: "Shoes", description: "Description for Item 4", imageName: "Shoes"),
		Item(name: "Polo shirt", description: "Polo shirt does not need to be boring.", imageName: "Polo shirt"),
	]

	@State var path = NavigationPath()
	@State var selectedItem: Item? = nil
	@State private var isProgrammaticNavigationActive = false

	var body: some View {
		NavigationStack(path: $path) {
			VStack {
				TextField("Search...", text: $searchText)
					.padding()
					.border(Color.gray, width: 1)
					.padding([.leading, .trailing, .top])
					.annotate(label: "Text field dedicated for searching items. Usually after commands related to search, or general requests to buy something that is not available on front the page. ", command: { value in
						guard case let .string(text) = value else { return }
						searchText = text
					}, type: .textField, screen: "Main")

				ScrollView {
					LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
						ForEach(items.filter { $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }) { item in
							NavigationLink(value: item) {
								Button {
									path.append(item)
								} label: {
									VStack {
										Image(item.imageName)
											.resizable()
											.scaledToFit()
											.frame(height: 100)
										Text(item.name)
											.font(.caption)
									}
									.padding(.bottom)
								}
								.annotate(label: "Item in a grid that describe selected goods. One can tap the grid item in order to open an item detail. item name: \(item.name) item description:\(item.description)", command: { _ in
									path.append(item)
								}, type: .button, screen: "Main")
							}
						}
					}
				}
			}
			.navigationDestination(for: Item.self) { item in
				ItemDetailView(item: item)
			}
			.navigationBarTitle("LLM Online Shop")
				// Programmatic Navigation Trigger
				//			.background(
				//				NavigationLink(destination: ItemDetailView(item: selectedItem ?? items.first!), isActive: $isProgrammaticNavigationActive) {
				//					EmptyView()
				//				}
				//			)
		}
		.onAppear {
				// Initialise the annotations
			Task { @MainActor in
				try await Task.sleep(for: .seconds(1.0))
				do {
					if instructionsSent == false {
						instructionsSent = true

						webservice.deleteHistoryList()
						let response = try await webservice.sendMessage(text: frameTracker.defaultInstructions())
						print("ChatGPT: \(response)")
						let mapResponse = try await webservice.sendMessage(text: frameTracker.mapInstructions(screen: "Main"))
						print("ChatGPT: \(mapResponse)")
					}
					let mapResponse = try await webservice.sendMessage(text: "You are now in the screen called: Main. Reply just 'OK - MAIN SCREEN'.")
					print("ChatGPT: \(mapResponse)")
				} catch {
					print(error.localizedDescription)
				}
			}
		}
	}
}
