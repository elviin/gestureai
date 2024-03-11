//
//  Item.swift
//  GestureAI
//
//  Created by Vladimír Slavík on 12.03.24.
//

import Foundation

struct Item: Identifiable, Equatable , Hashable{
	var id = UUID()
	var name: String
	var description: String
	var imageName: String

	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.id == rhs.id
	}
}
