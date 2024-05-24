//
//  GlobalFrameTracker.swift
//  GestureAI
//
//  Created by Vladimír Slavík on 12.03.24.
//

import Foundation

class GlobalFrameTracker: ObservableObject {
	@Published var annotations: [ControlAnnotation] = []
	@Published var commands: [UUID: (ActionValue)->()] = [:]

	func updateFrame(_ annotation: ControlAnnotation, command: @escaping (ActionValue)->()) {
		annotations.append(annotation)
		commands[annotation.id] = command
	}

	func createControlsMap(in screen: String) -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted // For readability

		do {
			let jsonData = try encoder.encode(annotations.filter{ $0.screen == screen })
			if let jsonString = String(data: jsonData, encoding: .utf8) {
				return jsonString
			} else {
				return "Error: Could not encode JSON data to string."
			}
		} catch {
			return "Encoding error: \(error.localizedDescription)"
		}
	}

	func mapInstructions(screen: String) -> String {
  """
  You are now in the screen "\(screen.capitalized)"
  Forget previous mapping and use the following control mapping:
  \(createControlsMap(in: screen))
  On this prompt reply just with "OK - MAP".
  """
	}

	func defaultInstructions() -> String {
  """
  --- Instruction set ---
  You will receive commands related to an application interface of a shop. The commands are are in natural speech. Based on the command you should decide which control matches the command. I will talk to you in natural language and you will try to guess which control id from the control map it is. Then you will answer just with the id of that control, or addinional information described below.

  This is a detailed description related to map of interactive controls or elements in mobile application screens. More detailed map you will get later from the prompt that comes with "--- Control Map --- specifically for each screen".

  Controls are part of screens.
  Each control can be identified by its id.
  In different screens there are different controls with different ids.
  In that context the app's user uses commands and you have to guess the right control id and screen that matches the context of the user.

  Snipped from the ControlAnnotation struct that describe the control in the application:
  struct ControlAnnotation {
  let id: UUID
  let frame: CGRect
  let title: String?
  let image: String?
  let accessibility: String?
  let annotation: String
  let color: String?
  let type: ControlType
  let screen: String
  // ...
  }

  Example:
  {
  "screen" : "Detail",
  "color" : null,
  "accessibility" : null,
  "id" : "97439C4E-C8C7-4E37-A6C4-405A0B1C3A07",
  "frame" : [[-11, -15],[23,30]],
  "title" : null,
  "image" : null,
  "annotation" : "Back button leading from the item detail to the shop home page.",
  "type" : "button"
  }

  In the above example the json data describes a control of type button, with id 97439C4E-C8C7-4E37-A6C4-405A0B1C3A07 and the control is in the screen called Detail. For deciding if this control is the right one matching the context of the user's

  Example of my command and your answer: I would like to select car.
  Then you will find the best control id that matches this user's command context within the current scrren and return that:
  {
   "id": "B25CEC9E-9C0E-484E-B933-A67A5C9FC10F"
  }

  Example of my command and your answer: I would like to search (or buy a car).
  Your answer is the best match to this command: e.g. a search text field control id, and to return a possible subject (key) that is part of the command's context.
  {
   "id": "B25CEC9E-9C0E-484E-B933-A67A5C9FC10F"
   "key": "car" // item used in a text field
  }
  
  After not being satisfied with the search (either saying go back, clean the search), return
  {
   "id": "B25CEC9E-9C0E-484E-B933-A67A5C9FC10F"
   "key": "" // just empty string
  }

  or in case of a scroll bar control:

  {
  "id": "B25CEC9E-9C0E-484E-B933-A67A5C9FC10F"
  "key": "15.0" // e.g. distance on a scroll bar, or slider
  }

  or in case of a control that sets number of items to buy:

  {
  "id": "B25CEC9E-9C0E-484E-B933-A67A5C9FC10F"
  "key": "15" // e.g. number of items
  }

  The key value can be missing if that does not make sense to send any key value, only the id, like in case of a simple button. When a negative command is being requested like no, no, or go back, then send key with empty string. It can happend when the serach textfield is used.

  If you do not understand the context, even after several inputs from the user, then just reply OK and wait with the answer untill it makes sense to you what control the user wants to use.
  
  It can happen that user is changing topic as you are probably not the only agent the user interact with. Take your time with hasty replies. Then simply answer 'OK' and nothing else.

  In case that there is no button or menu related to a wanted item, and it seems that the user wants to search, then just use the search control id.back

  During the application use, we switch the screens. you should know, that the controls should be selected for the Detail screen, if we have moved to the Detail screen, and from the Main screen controls, when we moved to the Main screen.

  Do not apologise in case you are not sure. Just reply OK and nothing else. You will understand the context later and decide better for the control id.
  
  Do not reply answers similar to this: 
  - I'm glad you find that helpful! If you have any more requests or need assistance, feel free to let me know.
  or this:
  - You 're welcome! If you have any more questions in the future, feel free to ask. Have a great day!

  If you are asked to go back, it can happend as noted above with a text field, or also it can be an instruction to go back from a screen, like from the detail screen to the main screen.

  DO NOT ANSWER ANYTHING ELSE which does not fit in this instruction set!
  DO NOT APOLOGISE
  DO NOT ENGAGE IN A NORMAL CONVERSATION STYLE OF ANSWERS

  Just receive my commands and answer as described in this set.

  Reply on this specific instruction prompt just with "OK - INSTRUCTIONS".
  """
	}
}
