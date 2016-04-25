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

public struct SKLanguageFeature
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
		if let colorKey = attributes["color"] as? String where colorKey != SKColorKey.Custom.rawValue
		{
			self.colorKey = SKColorKey(rawValue: colorKey)!
			self.color = UIColor.blackColor()
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
			self.color = UIColor.blackColor()
			self.colorKey = nil
		}
	}
	
	let key: String
	let pattern: String
	let color: UIColor
	let colorKey: SKColorKey?
}

public struct SKLanguageAutocompletionItem
{
	init(withAttributes attributes: NSDictionary) throws
	{
		guard
			let name			= attributes["name"]			as? String,
			let itemDescription = attributes["description"]		as? String,
			let searchName		= attributes["search-name"]		as? String,
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
		self.searchName		 = searchName
		self.insertionText	 = insertionText
		self.scope = scope
	}
	
	let name: String
	let itemDescription: String?
	let searchName: String
	let insertionText: String
	let scope: String?
}

public struct SKLanguage
{
	
	let name: String
	let suffix: String
	let appearance: SKAppearance
	let features: [SKLanguageFeature]
	let completionItems: [SKLanguageAutocompletionItem]
	
	
	public init(fromData data: NSData) throws
	{
		let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
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
		{ feature -> SKLanguageFeature in
			return try SKLanguageFeature(withAttributes: feature)
		}
		completionItems = try completionAttributes.flatMap
		{
			$0 as? NSDictionary
		}.map
		{ item -> SKLanguageAutocompletionItem in
			return try SKLanguageAutocompletionItem(withAttributes: item)
		}
		appearance = SKAppearance(themeName: attributes["appearance"] as? String ?? SKDefaultDarkAppearance)
	}
}


extension SKLanguageFeature : Equatable {}

public func == (left: SKLanguageFeature, right: SKLanguageFeature) -> Bool
{
	guard left.key == right.key			else { return false }
	guard left.pattern == right.pattern else { return false }
	guard left.color == right.color		else { return false }
	return true
}

extension SKLanguageAutocompletionItem : Equatable {}

public func == (left: SKLanguageAutocompletionItem, right: SKLanguageAutocompletionItem) -> Bool
{
	guard left.name == right.name						else { return false }
	guard left.itemDescription == right.itemDescription else { return false }
	guard left.searchName == right.searchName			else { return false }
	guard left.insertionText == right.insertionText		else { return false }
	guard left.scope == right.scope						else { return false }
	return true
}

extension SKLanguage : Equatable {}

public func == (left: SKLanguage, right: SKLanguage) -> Bool
{
	guard left.name == right.name else { return false }
	guard left.suffix == right.suffix else { return false }
	guard left.features == right.features else { return false }
	guard left.completionItems == right.completionItems else { return false }
	return true
}

internal extension String
{
	func repeated(times: Int) -> String
	{
		guard times >= 0
			else { fatalError("The string must be repeated at least zero times.") }
		return [String](count: times, repeatedValue: self).reduce("", combine: +)
	}
}
