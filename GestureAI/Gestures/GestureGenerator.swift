//
//  GestureGenerator.swift
//  GestureAI
//
//  Created by Vladimír Slavík on 07.03.24.
//

import Foundation

import SwiftUI

class GestureGenerator: ObservableObject {
	weak var tracker: GlobalFrameTracker?

	init(tracker: GlobalFrameTracker) {
		self.tracker = tracker
	}

	func performGesture(for id: UUID, key: String? = nil, value: Float? = nil) {
		if let controlAnnotation = tracker?.annotations.first(where: { $0.id == id }) {
			switch controlAnnotation.type {
			case .button:
				print("Simulate button tap")
				simulateButtonTap(annotation: controlAnnotation)
			case .textField:
				guard let key = key else { return }
				print("Simulate text field input: \(key)")
				simulateTextFieldInput(annotation: controlAnnotation, text: key)
			case .slider:
				guard let value = value else { return }
				print("Simulate slider adjustment to \(value)")
				simulateSliderAdjustment(annotation: controlAnnotation, value: value)
			}
		} else {
			print("No matching control found")
		}
	}


	private func simulateButtonTap(annotation: ControlAnnotation) {
			// Here you would call whatever action the button is supposed to trigger
	}

	private func simulateTextFieldInput(annotation: ControlAnnotation, text: String) {
			// Here you would set the state bound to the text field's text to the new value
	}

	private func simulateSliderAdjustment(annotation: ControlAnnotation, value: Float) {
			// Here you would set the state bound to the slider's value to the new value
	}
}

