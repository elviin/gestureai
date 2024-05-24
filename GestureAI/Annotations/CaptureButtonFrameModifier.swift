//
//  CaptureButtonFrameModifier.swift
//  GestureAI
//
//  Created by Vladimír Slavík on 12.03.24.
//

import Foundation
import SwiftUI

struct CaptureButtonFrameModifier: ViewModifier {
	@EnvironmentObject var frameTracker: GlobalFrameTracker
	let title: String?
	let image: String?
	let accessibility: String?
	let annotation: String
	let color: UIColor?
	let type: ControlType
	let screen: String
	let command: (ActionValue)->()

	func body(content: Content) -> some View {
		content
			.if((accessibility != nil)) {view in
				view.accessibilityLabel(Text(accessibility ?? ""))
			}
			.background(GeometryReader { geometry in
				Color.clear
					.onAppear {
						let controlAnnotation = ControlAnnotation(id: UUID(), frame: geometry.frame(in: .global),
																  title: title, image: image, accessibility: accessibility,
																  annotation: annotation, color: color?.accessibilityName, type: type, screen: screen)
                        print("annotation: frame=\(controlAnnotation.frame) annotation: \(controlAnnotation.annotation) title=\(controlAnnotation.title ?? "")")
						frameTracker.updateFrame(controlAnnotation, command: command)
					}
			})
	}
}

enum ControlType: String, Codable {
	case button
	case slider
	case textField
}


struct ControlAnnotation: Identifiable, Equatable, Codable {
	let id: UUID
	let frame: CGRect
	let title: String?
	let image: String?
	let accessibility: String?
	let annotation: String
	let color: String?
	let type: ControlType
	let screen: String


	init(id: UUID, frame: CGRect, title: String?, image: String?, accessibility: String?, annotation: String, color: String?, type: ControlType, screen: String) {
		self.id = id
		self.frame = CGRect(x: Int(frame.origin.x), y: Int(frame.origin.y), width: Int(frame.width), height: Int(frame.height))
		self.title = title
		self.image = image
		self.accessibility = accessibility
		self.annotation = annotation
		self.color = color
		self.type = type
		self.screen = screen
	}

	private enum ColorCodingError: Error {
		case encodingError
	}

	static func == (lhs: Self, rhs: Self) -> Bool {
		assert(lhs.type == rhs.type
			   && lhs.annotation == rhs.annotation
			   && CGRectEqualToRect(lhs.frame, rhs.frame))
		return lhs.id == rhs.id
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

			// Encode all properties directly encodable
		try container.encode(id, forKey: .id)
		try container.encode(frame, forKey: .frame)
		try container.encode(title, forKey: .title)
		try container.encode(image, forKey: .image)
		try container.encode(accessibility, forKey: .accessibility)
		try container.encode(annotation, forKey: .annotation)
		try container.encode(type, forKey: .type)
		try container.encode(color, forKey: .color)
		try container.encode(screen, forKey: .screen)
	}
}

enum ActionValue {
	case none
	case string(String)
	case int(Int)
	case double(Double)
}

extension View {
	func annotate(label: String, command: @escaping (ActionValue)->(), type: ControlType, screen: String, title: String? = nil, image: String? = nil, accessibility: String? = nil, color: UIColor? = nil) -> some View{
		modifier(CaptureButtonFrameModifier(title: title, image: image, accessibility: accessibility, annotation: label, color: color, type: type, screen: screen, command: command))
	}
}
