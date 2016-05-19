//
//  SKTextView.swift
//  SyntaxKit
//
//  Created by Palle Klewitz on 23.04.16.
//  Copyright © 2016 Palle Klewitz.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit

public class SKTextView: UITextView, NSTextStorageDelegate, UITextViewDelegate
{
	public var language: SKLanguage
	public var autoIndent: Bool = true
	public let lineNumberWidth: CGFloat
	
	private var autocompleteController: SKAutocompleteController
	
	private var inputHelperView: UIToolbar!
	
	private var inputTab: UIBarButtonItem!
	private var inputSemicolon: UIBarButtonItem!
	private var inputParentheses: UIBarButtonItem!
	private var inputAngleBrackets: UIBarButtonItem!
	private var inputSquareBrackets: UIBarButtonItem!
	private var inputCloseCurrentBracket: UIBarButtonItem!
	
	private var findMenuItem: UIMenuItem!
	private var findReplaceMenuItem: UIMenuItem!
	private var documentationMenuItem: UIMenuItem!

	public override init(frame: CGRect, textContainer: NSTextContainer?)
	{
		let bundle = NSBundle(forClass: self.dynamicType)
		let dataPath = bundle.pathForResource("Swift", ofType: "json")
		let data = NSData(contentsOfFile: dataPath!)
		let language = try! SKLanguage(fromData: data!)
		self.language = language
		
		let textStorage = NSTextStorage()
		let layoutManager = SKLayoutManager()
		let textContainer = NSTextContainer(size: CGSize(width: CGFloat.max, height: CGFloat.max))
		textContainer.widthTracksTextView = true
		
		lineNumberWidth = 30.0
		
		let exclusionPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: lineNumberWidth, height: CGFloat.max))
		textContainer.exclusionPaths = [exclusionPath]
		
		layoutManager.addTextContainer(textContainer)
		textStorage.addLayoutManager(layoutManager)
		
		let autocompleteView = SKAutocompleteView(frame: CGRectNull, style: .Plain)
		autocompleteController = SKAutocompleteController(withView: autocompleteView)
		
		super.init(frame: frame, textContainer: textContainer)
		
		self.addSubview(autocompleteView)
		self.bringSubviewToFront(autocompleteView)
		
		textStorage.delegate = self
		self.delegate = self
		
		self.font = UIFont(name: "Menlo", size: 14.0)
		opaque = false
		backgroundColor = UIColor.clearColor()
		autocorrectionType = .No
		autocapitalizationType = .None
		spellCheckingType = .No
		keyboardType = .ASCIICapable
		keyboardAppearance = .Dark
		indicatorStyle = .White
		bounces = true
		alwaysBounceVertical = true
		keyboardDismissMode = .Interactive
		dataDetectorTypes = []
		returnKeyType = .Default
		enablesReturnKeyAutomatically = false
		
		inputHelperView = UIToolbar(frame: CGRect(x: 0, y: frame.height - 44, width: frame.width, height: 44))
		inputHelperView.barStyle = .Black
		
		inputTab = UIBarButtonItem(title: "⇥", style: .Plain, target: self, action: #selector(inputItemPressed(_:)))
		inputTab.width = 50
		inputSemicolon = UIBarButtonItem(title: ";", style: .Plain, target: self, action: #selector(inputItemPressed(_:)))
		inputSemicolon.width = 50
		inputParentheses = UIBarButtonItem(title: "(...)", style: .Plain, target: self, action: #selector(inputItemPressed(_:)))
		inputParentheses.width = 50
		inputAngleBrackets = UIBarButtonItem(title: "{...}", style: .Plain, target: self, action: #selector(inputItemPressed(_:)))
		inputAngleBrackets.width = 50
		inputSquareBrackets = UIBarButtonItem(title: "[...]", style: .Plain, target: self, action: #selector(inputItemPressed(_:)))
		inputSquareBrackets.width = 50
		inputCloseCurrentBracket = UIBarButtonItem(title: ")", style: .Plain, target: self, action: #selector(inputItemPressed(_:)))
		inputCloseCurrentBracket.width = 50
		
		let fixedSpaceSemicolonParenthesis = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
		fixedSpaceSemicolonParenthesis.width = 40
		
		let fixedSpaceBracketClose = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
		fixedSpaceBracketClose.width = 20
		
		inputHelperView.items =
			[
				inputTab,
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
				inputSemicolon,
				fixedSpaceSemicolonParenthesis,
				inputParentheses,
				inputAngleBrackets,
				inputSquareBrackets,
				fixedSpaceBracketClose,
				inputCloseCurrentBracket
			]
		
		inputHelperView.items?.forEach
		{ item in
			let font = UIFont.systemFontOfSize(24.0)
			item.setTitleTextAttributes([NSFontAttributeName : font], forState: .Normal)
		}
		
		self.inputAccessoryView = inputHelperView
		
		findMenuItem = UIMenuItem(title: "Find other occurences", action: #selector(menuItemPressed))
		findReplaceMenuItem = UIMenuItem(title: "Find and replace", action: #selector(menuItemPressed))
		documentationMenuItem = UIMenuItem(title: "Show documentation", action: #selector(menuItemPressed))
		
		let menuItems = [findMenuItem, findReplaceMenuItem, documentationMenuItem]
		
		let defaultMenuItems = UIMenuController.sharedMenuController().menuItems
		UIMenuController.sharedMenuController().menuItems = (defaultMenuItems ?? []) + menuItems.map{$0!}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardDidChangeFrame(_:)), name: UIKeyboardDidChangeFrameNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIKeyboardDidHideNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
	}
	
	public required init?(coder aDecoder: NSCoder)
	{
		SKAppearance.LoadDefaultSchemes()
		let bundle = NSBundle(forClass: self.dynamicType)
		let dataPath = bundle.pathForResource("Java", ofType: "json")
		let data = NSData(contentsOfFile: dataPath!)
		let language = try! SKLanguage(fromData: data!)
		self.language = language
		
		lineNumberWidth = 30.0
		
		let autocompleteView = SKAutocompleteView(frame: CGRectNull, style: .Plain)
		autocompleteController = SKAutocompleteController(withView: autocompleteView)
		
		super.init(coder: aDecoder)
		
		self.addSubview(autocompleteView)
		
		textStorage.delegate = self
		self.delegate = self
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardDidChangeFrame(_:)), name: UIKeyboardDidChangeFrameNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIKeyboardDidHideNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
	}
	
	public override func encodeWithCoder(aCoder: NSCoder)
	{
		super.encodeWithCoder(aCoder)
		aCoder.encodeValue(language, forKey: "SKTextViewLanguage")
	}
	
	public func textStorage(textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int)
	{
		textStorage.removeAttribute(NSBackgroundColorAttributeName, range: NSRange(location: 0, length: textStorage.length))
		textStorage.addAttribute(NSForegroundColorAttributeName, value: language.appearance.colorTheme[SKColorKey.PlainText]!, range: NSRange(location: 0, length: textStorage.length))
		
		language.features.forEach
		{ feature in
			do
			{
				let color: UIColor
				
				if let colorKey = feature.colorKey
				{
					color = language.appearance.colorTheme[colorKey] ?? feature.color
				}
				else
				{
					color = feature.color
					print("Falling back to custom color for feature: \(feature.key)")
				}
				
				let expression = try NSRegularExpression(pattern: feature.pattern, options: [])
				expression.enumerateMatchesInString(self.textStorage.string, options: [], range: NSRange(location: 0, length: self.textStorage.length))
				{ result, flags, stop in
					guard let result = result else { return }
					self.textStorage.addAttribute(NSForegroundColorAttributeName, value: color, range: result.range)
				}
			}
			catch
			{
				print("Expression could not be evaluted. Error: \(error)")
			}
		}
		
		guard let expression = try? NSRegularExpression(pattern: "<#(.*?)#>", options: [])
			else
		{
			fatalError("Expression invalid")
		}
		expression.enumerateMatchesInString(textStorage.string, options: [], range: NSRange(location: 0, length: textStorage.length))
		{ result, flags, stop in
			guard let result = result else { return }
			self.textStorage.addAttribute(NSBackgroundColorAttributeName, value: UIColor(red: 0.5, green: 0.8, blue: 0.9, alpha: 0.5), range: result.range)
			self.textStorage.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: result.range)
//			let start = self.layoutManager.glyphIndexForCharacterAtIndex(result.range.location)
//			let second = self.layoutManager.glyphIndexForCharacterAtIndex(result.range.location+1)
//			let secondLast = self.layoutManager.glyphIndexForCharacterAtIndex(result.range.location+result.range.length-2)
//			let last = self.layoutManager.glyphIndexForCharacterAtIndex(result.range.location+result.range.length-1)
//			[start, second, secondLast, last].forEach
//			{
//				self.layoutManager.setNotShownAttribute(true, forGlyphAtIndex: $0)
//			}
//			self.layoutManager.invalidateDisplayForCharacterRange(result.range)
		}
	}
	
	public override var keyCommands: [UIKeyCommand]?
	{
		let newFileCommand = UIKeyCommand(input: "n", modifierFlags: [.Command], action: #selector(didExecuteKeyCommmand), discoverabilityTitle: "New...")
		let saveFileCommand = UIKeyCommand(input: "s", modifierFlags: [.Command], action: #selector(didExecuteKeyCommmand), discoverabilityTitle: "Save")
		
		let undoCommand = UIKeyCommand(input: "z", modifierFlags: [.Command], action: #selector(didExecuteKeyCommmand), discoverabilityTitle: "Undo")
		let redoCommand = UIKeyCommand(input: "z", modifierFlags: [.Command, .Shift], action: #selector(didExecuteKeyCommmand), discoverabilityTitle: "Redo")
		
		let cutCommand = UIKeyCommand(input: "x", modifierFlags: [.Command], action: #selector(didExecuteKeyCommmand), discoverabilityTitle: "Cut")
		let copyCommand = UIKeyCommand(input: "c", modifierFlags: [.Command], action: #selector(didExecuteKeyCommmand), discoverabilityTitle: "Copy")
		let pasteCommand = UIKeyCommand(input: "v", modifierFlags: [.Command], action: #selector(didExecuteKeyCommmand), discoverabilityTitle: "Paste")
		
		let selectAllCommand = UIKeyCommand(input: "a", modifierFlags: [.Command], action: #selector(didExecuteKeyCommmand), discoverabilityTitle: "Select All")
		
		let indentRightCommand = UIKeyCommand(input: "6", modifierFlags: [.Command], action: #selector(indentRight), discoverabilityTitle: "Indent Right")
		let indentLeftCommand = UIKeyCommand(input: "5", modifierFlags: [.Command], action: #selector(indentLeft), discoverabilityTitle: "Indent Left")
		
		let zoomInCommand = UIKeyCommand(input: "+", modifierFlags: [.Command], action: #selector(zoomIn), discoverabilityTitle: "Zoom In")
		let zoomOutCommand = UIKeyCommand(input: "-", modifierFlags: [.Command], action: #selector(zoomOut), discoverabilityTitle: "Zoom Out")
		
		let showCompletions = UIKeyCommand(input: " ", modifierFlags: [.Command], action: #selector(didExecuteKeyCommmand), discoverabilityTitle: "Show Completions")
		
		return (super.keyCommands ?? []) + [newFileCommand, saveFileCommand, undoCommand, redoCommand, cutCommand, copyCommand, pasteCommand, selectAllCommand, zoomInCommand, zoomOutCommand, indentLeftCommand, indentRightCommand, showCompletions]
	}
	
	@objc func didExecuteKeyCommmand(sender: UIKeyCommand)
	{
		
	}
	
	@objc func indentRight()
	{
		guard let newlineExpression = try? NSRegularExpression(pattern: "^(.*?)$", options: [.AnchorsMatchLines])
			else { fatalError("Could not create expression") }
		let newlines = newlineExpression.matchesInString(self.textStorage.string, options: [], range: NSRange(location: 0, length: self.selectedRange.location + self.selectedRange.length))
		let selectedLines = newlines
		.map {$0.range}
		.filter
		{
			NSIntersectionRange($0, self.selectedRange).length > 0
		}
		
		for range in selectedLines.reverse()
		{
			textStorage.insertAttributedString(NSAttributedString(string: "\t"), atIndex: range.location)
		}
		selectedRange.length += selectedLines.count
	}
	
	@objc func indentLeft()
	{
		guard let newlineExpression = try? NSRegularExpression(pattern: "^\t", options: [.AnchorsMatchLines])
			else { fatalError("Could not create expression") }
		let newlines = newlineExpression.matchesInString(self.textStorage.string, options: [], range: NSRange(location: 0, length: selectedRange.location + selectedRange.length))
		let affectedLines = newlines
		.map {$0.range}
		.filter
		{
			NSIntersectionRange($0, self.selectedRange).length > 0
		}
		for range in affectedLines.reverse()
		{
			textStorage.replaceCharactersInRange(NSRange(location: range.location, length: 1), withString: "")
		}
		selectedRange.length -= affectedLines.count
	}
	
	@objc func zoomIn()
	{
		guard let font = self.font else { return }
		self.font = font.fontWithSize(font.pointSize + 1.0)
	}
	
	@objc func zoomOut()
	{
		guard let font = self.font else { return }
		self.font = font.fontWithSize(font.pointSize - 1.0)
	}
	
	@objc func keyboardDidHide(notification: NSNotification)
	{
		guard let rect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue(), applicationFrame = self.window?.screen.bounds
			else { return }
		let keyboardHeight = applicationFrame.size.height - rect.origin.y
		self.contentInset = UIEdgeInsets(top: self.contentInset.top, left: self.contentInset.left, bottom: keyboardHeight, right: self.contentInset.right)
		self.scrollIndicatorInsets = UIEdgeInsets(top: self.scrollIndicatorInsets.top, left: self.scrollIndicatorInsets.left, bottom: keyboardHeight, right: self.scrollIndicatorInsets.right)
	}
	
	@objc func keyboardWillShow(notification: NSNotification)
	{
		guard let rect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue(), applicationFrame = self.window?.screen.bounds
			else { return }
		let keyboardHeight = applicationFrame.size.height - rect.origin.y
		self.contentInset = UIEdgeInsets(top: self.contentInset.top, left: self.contentInset.left, bottom: keyboardHeight, right: self.contentInset.right)
		self.scrollIndicatorInsets = UIEdgeInsets(top: self.scrollIndicatorInsets.top, left: self.scrollIndicatorInsets.left, bottom: keyboardHeight, right: self.scrollIndicatorInsets.right)
	}
	
	@objc func keyboardDidChangeFrame(notification: NSNotification)
	{
		guard let rect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue(), applicationFrame = self.window?.screen.bounds
			else { return }
		let keyboardHeight = applicationFrame.size.height - rect.origin.y
		self.contentInset = UIEdgeInsets(top: self.contentInset.top, left: self.contentInset.left, bottom: keyboardHeight, right: self.contentInset.right)
		self.scrollIndicatorInsets = UIEdgeInsets(top: self.scrollIndicatorInsets.top, left: self.scrollIndicatorInsets.left, bottom: keyboardHeight, right: self.scrollIndicatorInsets.right)
	}
	
	private var previousInsertedText: String?
	private var lastInsertedText: String!
	private var ignore: Bool = false
	
	public func textViewDidChange(textView: UITextView)
	{
		if ignore { return }
		switch lastInsertedText
		{
		case "{":
			ignore = true
			insertText("}")
			ignore = false
			selectedRange.location -= 1
			break
		case "\n":
			if let previousInsertedText = previousInsertedText
				where previousInsertedText == "{"
				|| previousInsertedText == "("
				|| previousInsertedText == "["
			{
				ignore = true
				let indentationLevel = self.indentationLevel(atLocation: selectedRange.location)
				insertText("\t".repeated(max(indentationLevel, 0)))
				insertText("\n")
				insertText("\t".repeated(max(indentationLevel-1, 0)))
				ignore = false
				selectedRange.location -= indentationLevel
			}
			else
			{
				let indentationLevel = self.indentationLevel(atLocation: selectedRange.location)
				ignore = true
				insertText("\t".repeated(max(indentationLevel, 0)))
				ignore = false
			}
			break
		case "(":
			ignore = true
			insertText(")")
			ignore = false
			selectedRange.location -= 1
			break
		case "[":
			ignore = true
			insertText("]")
			ignore = false
			selectedRange.location -= 1
			break
		case "\"":
			ignore = true
			insertText("\"")
			ignore = false
			selectedRange.location -= 1
			break
		case "'":
			ignore = true
			insertText("'")
			ignore = false
			selectedRange.location -= 1
			break
		case "*":
			ignore = true
			if (textStorage.string as NSString).substringWithRange(NSRange(location: selectedRange.location-2, length: 1)) == "/"
			{
				insertText("*/")
				selectedRange.location -= 2
			}
			ignore = false
			break
		default:
			break
		}
		
		previousInsertedText = lastInsertedText
	}
	
	public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
	{
		if !ignore
		{
			if textStorage.length > range.location
			{
				let nextCharacter = (textStorage.string as NSString).substringWithRange(NSRange(location: range.location, length: 1))
				switch (text, nextCharacter)
				{
				case ("}", "}"), ("]", "]"), (")", ")"), ("\"", "\""), ("'", "'"):
					selectedRange.location += 1
					return false
				case ("\t", _):
					guard let expression = try? NSRegularExpression(pattern: "<#(.*?)#>", options: [])
						else
					{
						fatalError("Expression invalid")
					}
					guard let match = expression.firstMatchInString(self.textStorage.string, options: [], range: NSRange(location: self.selectedRange.location + self.selectedRange.length, length: self.textStorage.length - self.selectedRange.location - self.selectedRange.length))
					else
					{
						break
					}
					selectedRange = match.range
					return false
				default:
					break
				}
			}
			
			lastInsertedText = text
		}
		else
		{
			lastInsertedText = ""
		}
		//TODO: detect tabs and ignore them if a placeholder exists.
		return true
	}
	
	func indentationLevel(atLocation location: Int) -> Int
	{
		
		//TODO: Search for quotes and stuff to ignore brackets if in a string.
		guard
			let increaseExpression = try? NSRegularExpression(pattern: "\\{|\\[|\\(", options: []),
			let decreaseExpression = try? NSRegularExpression(pattern: "\\}|\\]|\\)", options: [])
		else { fatalError("Invalid expression") }
		
		let textRange = NSRange(location: 0, length: location)
		
		let increasingMatchCount = increaseExpression.numberOfMatchesInString(textStorage.string, options: [], range: textRange)
		let decreasingMatchCount = decreaseExpression.numberOfMatchesInString(textStorage.string, options: [], range: textRange)
		
//		guard let increasingIfExpression = try? NSRegularExpression(pattern: "\\bif\\b.*[^{;]", options: [.DotMatchesLineSeparators, .AllowCommentsAndWhitespace])
//		else
//		{
//			fatalError("Invalid expression.")
//		}
//		
//		let increasingIfMatchCount = increasingIfExpression.numberOfMatchesInString(textStorage.string, options: [], range: textRange)
//		
		return increasingMatchCount - decreasingMatchCount /* + increasingIfMatchCount*/
	}
	
	@objc private func inputItemPressed(sender: UIBarButtonItem)
	{
		let insertion: String?
		switch sender
		{
		case inputTab:
			guard let expression = try? NSRegularExpression(pattern: "<#(.*?)#>", options: [])
				else
			{
				fatalError("Expression invalid")
			}
			guard let match = expression.firstMatchInString(self.textStorage.string, options: [], range: NSRange(location: self.selectedRange.location + self.selectedRange.length, length: self.textStorage.length - self.selectedRange.location - self.selectedRange.length))
				else
			{
				insertion = "\t"
				break
			}
			insertion = nil
			selectedRange = match.range
			break
		case inputSemicolon:
			insertion = ";"
			break
		case inputParentheses:
			insertion = "("
			break
		case inputAngleBrackets:
			insertion = "{"
			break
		case inputSquareBrackets:
			insertion = "["
			break
		case inputCloseCurrentBracket:
			guard selectedRange.location < textStorage.length else { return }
			let nextCharacter = (self.textStorage.string as NSString).substringWithRange(NSRange(location: self.selectedRange.location, length: 1))
			
			if [")", "}", "]", "\"", "'"].contains(nextCharacter)
			{
				selectedRange.location += 1
			}
			return
		default:
			insertion = nil
			break
		}
		
		guard let insertionText = insertion else { return }
		lastInsertedText = insertionText
		insertText(insertionText)
	}

	@objc private func menuItemPressed(sender: UIMenuItem)
	{
		
	}
	
	public func textViewDidChangeSelection(textView: UITextView)
	{
		guard let expression = try? NSRegularExpression(pattern: "<#(.*?)#>", options: [])
			else
		{
			fatalError("Expression invalid")
		}
		let result = expression.matchesInString(self.textStorage.string, options: [], range: NSRange(location: 0, length: self.textStorage.length))
		.filter
		{ result -> Bool in
			result.range.location < textView.selectedRange.location && result.range.location + result.range.length > textView.selectedRange.location + textView.selectedRange.length
		}.first
		if let range = result?.range
		{
			textView.selectedRange = range
		}
	}
}
