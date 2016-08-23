//
//  SKLanguage.swift
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

import Foundation


@available(*, deprecated:1.0, renamed:"LanguageFeature")
public typealias SKLanguageFeature = LanguageFeature

public struct LanguageFeature
{
	init(withAttributes attributes: NSDictionary) throws
	{
		guard
			let key		= attributes["key"]		as? String,
			let pattern = attributes["pattern"] as? String
		else
		{
			let error = NSError(domain: "com.palleklewitz.SyntaxKit.SKLanguage.InvalidFormat", code: 1, userInfo: nil)
			print(error)
			throw error
		}
		self.key = key
		self.pattern = pattern
		if let colorKey = attributes["color"] as? String , colorKey != ColorKey.Custom.rawValue
		{
			self.colorKey = ColorKey(rawValue: colorKey)!
			self.color = UIColor.black
		}
		else if
			let red		= attributes["red"]		as? Double,
			let green	= attributes["green"]	as? Double,
			let blue	= attributes["blue"]	as? Double
		{
			self.color = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
			self.colorKey = nil
		}
		else
		{
			self.color = UIColor.black
			self.colorKey = nil
		}
	}
	
	let key: String
	let pattern: String
	let color: UIColor
	let colorKey: ColorKey?
}


@available(*, deprecated:1.0, renamed:"LanguageAutocompletionItem")
public typealias SKLanguageAutocompletionItem = LanguageAutocompletionItem

public struct LanguageAutocompletionItem
{
	init(withAttributes attributes: NSDictionary) throws
	{
		guard
			let name			= attributes["name"]			as? String,
			let itemDescription = attributes["description"]		as? String,
			let searchTags		= attributes["search-tags"]		as? NSArray as? [String],
			let insertionText	= attributes["insertion-text"]	as? String,
			let scope			= attributes["scope"]			as? String?
		else
		{
			let error = NSError(domain: "com.palleklewitz.SyntaxKit.SKLanguage.InvalidFormat", code: 2, userInfo: nil)
			print(error)
			throw error
		}
		self.name			 = name
		self.itemDescription = itemDescription
		self.searchTags		 = searchTags
		self.insertionText	 = insertionText
		self.scope = scope
	}
	
	let name: String
	let itemDescription: String?
	let searchTags: [String]
	let insertionText: String
	let scope: String?
}


@available(*, deprecated:1.0, renamed:"Language")
public typealias SKLanguage = Language

public struct Language
{
	
	let name: String
	let suffix: String
	let appearance: Appearance
	let features: [LanguageFeature]
	let completionItems: [LanguageAutocompletionItem]
	
	
	public init(fromData data: Data) throws
	{
		let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
		guard
			let attributes			 = json						 as? NSDictionary,
			let name				 = attributes["name"]		 as? String,
			let suffix				 = attributes["suffix"]		 as? String,
			let featureAttributes	 = (attributes["features"]	 as? NSArray),
			let completionAttributes = (attributes["completion"] as? NSArray)
		else
		{
			let error = NSError(domain: "com.palleklewitz.SyntaxKit.SKLanguage.InvalidFormat", code: 0, userInfo: nil)
			print(error)
			throw error
		}
		self.name	  = name
		self.suffix	  = suffix
		features	  = try featureAttributes.flatMap
		{
			$0 as? NSDictionary
		}.map
		{ feature -> LanguageFeature in
			return try LanguageFeature(withAttributes: feature)
		}
		completionItems = try completionAttributes.flatMap
		{
			$0 as? NSDictionary
		}.map
		{ item -> LanguageAutocompletionItem in
			return try LanguageAutocompletionItem(withAttributes: item)
		}
		appearance = Appearance(themeName: attributes["appearance"] as? String ?? DefaultDarkAppearance)
	}
}

extension LanguageFeature : Equatable {}

public func == (left: LanguageFeature, right: LanguageFeature) -> Bool
{
	guard left.key == right.key			else { return false }
	guard left.pattern == right.pattern else { return false }
	guard left.color == right.color		else { return false }
	return true
}

extension LanguageAutocompletionItem : Equatable {}

public func == (left: LanguageAutocompletionItem, right: LanguageAutocompletionItem) -> Bool
{
	guard left.name == right.name						else { return false }
	guard left.itemDescription == right.itemDescription else { return false }
	guard left.searchTags == right.searchTags			else { return false }
	guard left.insertionText == right.insertionText		else { return false }
	guard left.scope == right.scope						else { return false }
	return true
}

extension Language : Equatable {}

public func == (left: Language, right: Language) -> Bool
{
	guard left.name == right.name else { return false }
	guard left.suffix == right.suffix else { return false }
	guard left.features == right.features else { return false }
	guard left.completionItems == right.completionItems else { return false }
	return true
}

internal extension String
{
	func repeated(_ times: Int) -> String
	{
		guard times >= 0
			else { fatalError("The string must be repeated at least zero times.") }
		return [String](repeating: self, count: times).reduce("", +)
	}
}
