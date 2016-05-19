//
//  SKAppearance.swift
//  SyntaxKit
//
//  Created by Palle Klewitz on 24.04.16.
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

import Foundation

//this class should not be initialized
//it only exists to allow for NSBundle(forClass: ClassForBundleLoading().dynamicType)
private class ClassForBundleLoading
{
	private init()
	{
		
	}
}

internal extension UIColor
{
	//TODO (Swift 2.3): Replace this with a failable initializer.
	//This is currently not possible because of https://bugs.swift.org/browse/SR-704
	class func color(withString string: String?) -> UIColor?
	{
		guard let hextString = string else { return nil }
		let start = hextString.startIndex
		guard hextString.characters.count == 7 && String(hextString[start]) == "#" else { return nil }
		
		let redRange = start.advancedBy(1) ... start.advancedBy(2)
		let greenRange = start.advancedBy(3) ... start.advancedBy(4)
		let blueRange = start.advancedBy(5) ... start.advancedBy(6)
		
		let redString = hextString[redRange]
		let greenString = hextString[greenRange]
		let blueString = hextString[blueRange]
		
		guard
			let red = Int(redString, radix: 16),
			let green = Int(greenString, radix: 16),
			let blue = Int(blueString, radix: 16)
		else { return nil }
		return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 255)
	}
	
	internal var colorString: String
	{
		var red:CGFloat = 0
		var green:CGFloat = 0
		var blue:CGFloat = 0
		self.getRed(&red, green: &green, blue: &blue, alpha: nil)
		return String.init(format: "#%02X%02X%02X")
	}
}

private extension NSUserDefaults
{
	subscript(key: String) -> String?
	{
		get
		{
			return self.stringForKey(key)
		}
		
		set (new)
		{
			self.setValue(new, forKey: key)
		}
	}
}

public let SKDefaultLightAppearance = "DefaultAppearanceLight"
public let SKDefaultDarkAppearance = "DefaultAppearanceDark"

public struct SKAppearance
{
	private static var didCheckForDefaultsLoaded = false
	
	private static func ColorForKey(themeName: String, key: SKColorKey) -> UIColor!
	{
		let customKey = "com.palleklewitz.SyntaxKit.\(themeName).\(key.rawValue)"
		let defaults = NSUserDefaults.standardUserDefaults()
		
		if let customColor = UIColor.color(withString: defaults[customKey])
		{
			return customColor
		}
		else
		{
			let defaultKey = "com.palleklewitz.SyntaxKit.\(SKDefaultLightAppearance).\(key.rawValue)"
			guard let defaultColor = UIColor.color(withString: defaults[defaultKey])
			else
			{
				if key == .Custom
				{
					return .whiteColor()
				}
				if let fallback = key.fallback
				{
					return ColorForKey(themeName, key: fallback)
				}
				else
				{
					return nil
				}
			}
			return defaultColor
		}
	}
	
	internal static func LoadDefaultSchemes()
	{
		if didCheckForDefaultsLoaded { return }
		ResetDefaultSchemes()
		LoadLightAppearance()
		LoadDarkAppearance()
		didCheckForDefaultsLoaded = true
	}
	
	internal static func ResetDefaultSchemes()
	{
		let defaults = NSUserDefaults.standardUserDefaults()
		SKColorKey.values.forEach { (key) in
			let defaultKeyLight = "com.palleklewitz.SyntaxKit.\(SKDefaultLightAppearance).\(key.rawValue)"
			let defaultKeyDark = "com.palleklewitz.SyntaxKit.\(SKDefaultDarkAppearance).\(key.rawValue)"
			defaults.removeObjectForKey(defaultKeyLight)
			defaults.removeObjectForKey(defaultKeyDark)
		}
	}
	
	private static func LoadLightAppearance()
	{
		let bundle = NSBundle(forClass: ClassForBundleLoading().dynamicType)
		guard
			let dataPath = bundle.pathForResource(SKDefaultLightAppearance, ofType: "strings"),
			let values = NSDictionary(contentsOfFile: dataPath)
		else { fatalError("Default Appearance could not be loaded.") }
		
		let defaults = NSUserDefaults.standardUserDefaults()
		
		for key in SKColorKey.values
		{
			guard let colorString = values[key.rawValue] as? String else
			{
				continue
			}
			defaults["com.palleklewitz.SyntaxKit.\(SKDefaultLightAppearance).\(key.rawValue)"] = colorString
		}
	}
	
	private static func LoadDarkAppearance()
	{
		let bundle = NSBundle(forClass: ClassForBundleLoading().dynamicType)
		guard
			let dataPath = bundle.pathForResource(SKDefaultDarkAppearance, ofType: "strings"),
			let values = NSDictionary(contentsOfFile: dataPath)
		else { fatalError("Default Appearance could not be loaded.") }
		
		let defaults = NSUserDefaults.standardUserDefaults()
		
		for key in SKColorKey.values
		{
			guard let colorString = values[key.rawValue] as? String
			else
			{
				continue
			}
			defaults["com.palleklewitz.SyntaxKit.\(SKDefaultDarkAppearance).\(key.rawValue)"] = colorString
		}
	}
	
	public let font: UIFont
	public internal(set) var colorTheme: [SKColorKey : UIColor]
	public let themeName: String
	
	public init(themeName: String)
	{
		let font = UIFont(name: "Menlo", size: 14.0)!
		self.font = font
		var colorTheme: [SKColorKey : UIColor] = [:]
		
		for key in SKColorKey.values
		{
			colorTheme[key] = SKAppearance.ColorForKey(themeName, key: key)
		}
		
		self.colorTheme = colorTheme
		self.themeName = themeName
	}
	
	public mutating func setColor(color: UIColor, forKey key: SKColorKey)
	{
		let customKey = "com.palleklewitz.SyntaxKit.\(themeName).\(key.rawValue)"
		let defaults = NSUserDefaults.standardUserDefaults()
		defaults.setObject(color.colorString, forKey: customKey)
		colorTheme[key] = color
	}
	
	public func color(forKey key: SKColorKey) -> UIColor
	{
		return self.dynamicType.ColorForKey(self.themeName, key: key)
	}
	
	public subscript(key: SKColorKey) -> UIColor
	{
		get
		{
			return color(forKey: key)
		}
		
		set (new)
		{
			setColor(new, forKey: key)
		}
	}
	
	public mutating func load(fromStringsFileAtPath path: String)
	{
		guard let values = NSDictionary(contentsOfFile: path) else { return }
		for key in SKColorKey.values
		{
			guard let colorString = values[key.rawValue] as? String,
			let color = UIColor.color(withString: colorString)
				else
			{
				continue
			}
			
			self[key] = color
		}
	}
}

public enum SKColorKey : String
{
	case PlainText = "SKColorPlainTextKey"
	case Background = "SKColorBackgroundKey"
	
	case LineNumber = "SKColorLineNumberKey"
	case LineNumberBackground = "SKColorLineNumberBackgroundKey"
	
	case Keyword = "SKColorKeywordKey"
	case ControlCharacter = "SKColorControlCharacterKey"
	case Operator = "SKColorOperatorKey"
	case Annotation = "SKColorAnnotationKey"
	
	case Type = "SKColorTypeKey"
	case TypeDeclaration = "SKColorTypeDeclarationKey"
	case Generics = "SKColorGenericTypeKey"
	
	case Variable = "SKColorVariableKey"
	case Constant = "SKColorConstantKey"
	
	case InstanceVariable = "SKColorInstanceVariableKey"
	case InstanceVariableDeclaration = "SKColorInstanceVariableDeclarationKey"
	
	case StaticVariable = "SKColorStaticVariableKey"
	case StaticVariableDeclaration = "SKColorStaticVariableDeclarationKey"
	
	case GlobalVariable = "SKColorGlobalVariableKey"
	case GlobalVariableDeclaration = "SKColorGlobalVariableDeclarationKey"
	
	case Attribute = "SKColorAttributeKey"
	
	case FunctionCall = "SKColorFunctionCallKey"
	case FunctionDeclaration = "SKColorFunctionDeclarationKey"
	
	case StaticFunctionCall = "SKColorStaticFunctionCallKey"
	case StaticFunctionDeclaration = "SKColorStaticFunctionDeclarationKey"
	
	case GlobalFunctionCall = "SKColorGlobalFunctionCallKey"
	case GlobalFunctionDeclaration = "SKColorGlobalFunctionDeclarationKey"
	
	case String = "SKColorStringKey"
	case StringEscapeSequence = "SKColorStringEscapeSequenceKey"
	case StringFormatSequence = "SKColorStringFormatSequenceKey"
	
	case Character = "SKColorCharacterKey"
	case CharacterEscapeSequence = "SKColorCharacterEscapeSequence"
	
	case Number = "SKColorNumberKey"
	
	case Hyperlink = "SKColorHyperlinkKey"
	
	case Comment = "SKColorCommentKey"
	case CommentTag = "SKColorCommentTagKey"
	case MultilineComment = "SKColorMultilineCommentKey"
	case DocumentationComment = "SKColorDocumentationCommentKey"
	case MultilineDocumentationComment = "SKColorMultilineDocumentationCommentKey"
	case DocumentationCommentParameter = "SKColorDocumentationCommentParameterKey"
	case DocumentationCommentValue = "SKColorDocumentationCommentValueKey"
	
	case Class = "SKColorClassKey"
	case Identifier = "SKColorIdentifierKey"
	case Label = "SKColorLabelKey"
	case Selector = "SKColorSelectorKey"
	
	
	case Custom = "SKColorKeyCustom"
	
	
	static let values:[SKColorKey] = [.Annotation, .Attribute, .Background, .Background, .Character, .CharacterEscapeSequence, .Class, .Comment, .CommentTag, .Constant, .ControlCharacter, .DocumentationComment, .DocumentationCommentParameter, .DocumentationCommentValue, .FunctionCall, .FunctionDeclaration, .Generics, .GlobalVariable, .GlobalFunctionCall, .GlobalFunctionDeclaration, .GlobalVariableDeclaration, .Hyperlink, .Identifier, .InstanceVariable, .InstanceVariableDeclaration, .Keyword, .Label, .LineNumber, .LineNumberBackground, .MultilineComment, .MultilineDocumentationComment, .Number, .Operator, .PlainText, .Selector, .StaticFunctionCall, .StaticFunctionDeclaration, .StaticVariable, .StaticVariableDeclaration, .String, .StringEscapeSequence, .StringFormatSequence, .Type, .TypeDeclaration, .Variable]
	
	var fallback:SKColorKey?
	{
		switch self
		{
		case .LineNumberBackground:
			return .Background
		case .Class:
			return .Type
		case .CommentTag, .MultilineComment:
			return .Comment
		case .MultilineDocumentationComment, .DocumentationCommentParameter, .DocumentationCommentValue:
			return .DocumentationComment
		case .CharacterEscapeSequence:
			return .Character
		case .StringFormatSequence, .StringEscapeSequence:
			return .String
		case .PlainText, .Background:
			return .Custom
		default:
			return .PlainText
		}
	}
}

