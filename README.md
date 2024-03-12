# gestureai
The project implements an iOS application that integrates SFSpeechRecognizer together with ChatGPT functionality. You can control or command the application with your natural language. 

### The speech to text recognition
An SFTranscription extension is used to add two new variables to recognise sentences in natural speech: newSentenceStarted, lastClosedSentence. The time between two sentences is set to 1 second.

### Example of the annotation
Example code of the annotation that could be later a candidate for an SDK:

```swift

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
.annotate(label: "Item in a grid that describe selected goods. ... item name: \(item.name) item description:\(item.description)", command: { _ in
	path.append(item)
}, type: .button, screen: "Main")

```

### Example of the json map
The json map is used for gpt to be able to select the right control based on its ID.

```swift
  {
    "screen" : "Detail",
    "color" : null,
    "accessibility" : null,
    "id" : "97439C4E-C8C7-4E37-A6C4-405A0B1C3A07",
    "title" : null,
    "image" : null,
    "annotation" : "Back button leading from the item detail to the shop home page.",
    "type" : "button"
  }
```


