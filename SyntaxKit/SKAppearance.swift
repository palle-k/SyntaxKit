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
	fileprivate init()
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
		
		let redRange = hextString.characters.index(start, offsetBy: 1) ... hextString.characters.index(start, offsetBy: 2)
		let greenRange = hextString.characters.index(start, offsetBy: 3) ... hextString.characters.index(start, offsetBy: 4)
		let blueRange = hextString.characters.index(start, offsetBy: 5) ... hextString.characters.index(start, offsetBy: 6)
		
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

private extension UserDefaults
{
	subscript(key: String) -> String?
	{
		get
		{
			return self.string(forKey: key)
		}
		
		set (new)
		{
			self.setValue(new, forKey: key)
		}
	}
}

public let DefaultLightAppearance = "DefaultAppearanceLight"
public let DefaultDarkAppearance = "DefaultAppearanceDark"


@available(*, deprecated:1.0, renamed:"DefaultLightAppearance")
public let SKDefaultLightAppearance = DefaultLightAppearance

@available(*, deprecated:1.0, renamed:"DefaultDarkAppearance")
public let SKDefaultDarkAppearance = DefaultDarkAppearance

@available(*, deprecated:1.0, renamed:"Appearance")
public typealias SKAppearance = Appearance

public struct Appearance
{
	fileprivate static var didCheckForDefaultsLoaded = false
	
	fileprivate static func ColorForKey(_ themeName: String, key: ColorKey) -> UIColor!
	{
		let customKey = "com.palleklewitz.SyntaxKit.\(themeName).\(key.rawValue)"
		let defaults = UserDefaults.standard
		
		if let customColor = UIColor.color(withString: defaults[customKey])
		{
			return customColor
		}
		else
		{
			let defaultKey = "com.palleklewitz.SyntaxKit.\(DefaultLightAppearance).\(key.rawValue)"
			guard let defaultColor = UIColor.color(withString: defaults[defaultKey])
			else
			{
				if key == .Custom
				{
					return .white
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
		let defaults = UserDefaults.standard
		ColorKey.values.forEach { (key) in
			let defaultKeyLight = "com.palleklewitz.SyntaxKit.\(DefaultLightAppearance).\(key.rawValue)"
			let defaultKeyDark = "com.palleklewitz.SyntaxKit.\(DefaultDarkAppearance).\(key.rawValue)"
			defaults.removeObject(forKey: defaultKeyLight)
			defaults.removeObject(forKey: defaultKeyDark)
		}
	}
	
	fileprivate static func LoadLightAppearance()
	{
		let bundle = Bundle(for: type(of: ClassForBundleLoading()))
		guard
			let dataPath = bundle.path(forResource: DefaultLightAppearance, ofType: "strings"),
			let values = NSDictionary(contentsOfFile: dataPath)
		else { fatalError("Default Appearance could not be loaded.") }
		
		let defaults = UserDefaults.standard
		
		for key in ColorKey.values
		{
			guard let colorString = values[key.rawValue] as? String else
			{
				continue
			}
			defaults["com.palleklewitz.SyntaxKit.\(DefaultLightAppearance).\(key.rawValue)"] = colorString
		}
	}
	
	fileprivate static func LoadDarkAppearance()
	{
		let bundle = Bundle(for: type(of: ClassForBundleLoading()))
		guard
			let dataPath = bundle.path(forResource: DefaultDarkAppearance, ofType: "strings"),
			let values = NSDictionary(contentsOfFile: dataPath)
		else { fatalError("Default Appearance could not be loaded.") }
		
		let defaults = UserDefaults.standard
		
		for key in ColorKey.values
		{
			guard let colorString = values[key.rawValue] as? String
			else
			{
				continue
			}
			defaults["com.palleklewitz.SyntaxKit.\(DefaultDarkAppearance).\(key.rawValue)"] = colorString
		}
	}
	
	public let font: UIFont
	public internal(set) var colorTheme: [ColorKey : UIColor]
	public let themeName: String
	
	public init(themeName: String)
	{
		let font = UIFont(name: "Menlo", size: 14.0)!
		self.font = font
		var colorTheme: [ColorKey : UIColor] = [:]
		
		for key in ColorKey.values
		{
			colorTheme[key] = Appearance.ColorForKey(themeName, key: key)
		}
		
		self.colorTheme = colorTheme
		self.themeName = themeName
	}
	
	public mutating func setColor(_ color: UIColor, forKey key: ColorKey)
	{
		let customKey = "com.palleklewitz.SyntaxKit.\(themeName).\(key.rawValue)"
		let defaults = UserDefaults.standard
		defaults.set(color.colorString, forKey: customKey)
		colorTheme[key] = color
	}
	
	public func color(forKey key: ColorKey) -> UIColor
	{
		return type(of: self).ColorForKey(self.themeName, key: key)
	}
	
	public subscript(key: ColorKey) -> UIColor
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
		for key in ColorKey.values
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

@available(*, deprecated:1.0, renamed:"ColorKey")
public typealias SKColorKey = ColorKey

public enum ColorKey : String
{
	case PlainText = "SKColorPlainTextKey"
	case Background = "SKColorBackgroundKey"
	
	case LineNumber = "SKColorLineNumberKey"
	case LineNumberBackground = "SKColorLineNumberBackgroundKey"
	
	case Keyword = "SKColorKeywordKey"
	case ControlCharacter = "SKColorControlCharacterKey"
	case Operator = "SKColorOperatorKey"
	case Annotation = "SKColorAnnotationKey"
	
	case `Type` = "SKColorTypeKey"
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
	
	
	static let values:[ColorKey] = [.Annotation, .Attribute, .Background, .Background, .Character, .CharacterEscapeSequence, .Class, .Comment, .CommentTag, .Constant, .ControlCharacter, .DocumentationComment, .DocumentationCommentParameter, .DocumentationCommentValue, .FunctionCall, .FunctionDeclaration, .Generics, .GlobalVariable, .GlobalFunctionCall, .GlobalFunctionDeclaration, .GlobalVariableDeclaration, .Hyperlink, .Identifier, .InstanceVariable, .InstanceVariableDeclaration, .Keyword, .Label, .LineNumber, .LineNumberBackground, .MultilineComment, .MultilineDocumentationComment, .Number, .Operator, .PlainText, .Selector, .StaticFunctionCall, .StaticFunctionDeclaration, .StaticVariable, .StaticVariableDeclaration, .String, .StringEscapeSequence, .StringFormatSequence, .Type, .TypeDeclaration, .Variable]
	
	var fallback:ColorKey?
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

