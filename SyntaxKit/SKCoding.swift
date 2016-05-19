//
//  SKCoding.swift
//  SyntaxKit
//
//  Created by Palle Klewitz on 03.05.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Foundation

internal protocol SKEncoding
{
	init?(codingDictionary: NSDictionary)
	
	var codingDictionary: NSDictionary { get }
}

internal extension NSCoder
{
	func encodeValue(value: SKEncoding, forKey key: String? = nil)
	{
		if let key = key
		{
			self.encodeObject(value.codingDictionary, forKey: key)
		}
		else
		{
			self.encodeObject(value.codingDictionary)
		}
	}
	
	func decodeValue<Type : SKEncoding>(ofType type: Type.Type, forKey key: String? = nil) -> Type?
	{
		if let key = key, codingDictionary = self.decodeObjectForKey(key) as? NSDictionary
		{
			return Type.init(codingDictionary: codingDictionary)
		}
		else if let codingDictionary = self.decodeObject() as? NSDictionary
		{
			return Type.init(codingDictionary: codingDictionary)
		}
		return nil
	}
}

extension SKLanguageFeature : SKEncoding
{
	init?(codingDictionary: NSDictionary)
	{
		guard
			let key = codingDictionary["key"] as? String,
			let pattern = codingDictionary["pattern"] as? String,
			let color = codingDictionary["color"] as? UIColor,
			let colorKeyString = codingDictionary["colorkey"] as? String
		else { return nil }
		self.key = key
		self.pattern = pattern
		self.color = color
		self.colorKey = SKColorKey(rawValue: colorKeyString)
	}
	
	var codingDictionary: NSDictionary
	{
		var dictionary:[String : AnyObject] = [:]
		dictionary["key"] = key
		dictionary["pattern"] = pattern
		dictionary["color"] = color
		if let colorKey = colorKey
		{
			dictionary["colorkey"] = colorKey.rawValue
		}
		return dictionary
	}
}

extension SKLanguage : SKEncoding
{
	init?(codingDictionary: NSDictionary)
	{
		guard
			let name = codingDictionary["name"] as? String,
			let suffix = codingDictionary["suffix"] as? String,
			let appearanceDictionary = codingDictionary["appearance"] as? NSDictionary,
			let features = codingDictionary["features"] as? NSArray,
			let completionItems = codingDictionary["completionitems"] as? NSArray
		else { return nil }
		self.name = name
		self.suffix = suffix
		guard let appearance = SKAppearance(codingDictionary: appearanceDictionary) else { return nil }
		self.appearance = appearance
		self.features = features.flatMap
		{
			if let codingDictionary = $0 as? NSDictionary
			{
				return SKLanguageFeature(codingDictionary: codingDictionary)
			}
			else
			{
				return nil
			}
		}
		self.completionItems = completionItems.flatMap
		{
			if let codingDictionary = $0 as? NSDictionary
			{
				return SKLanguageAutocompletionItem(codingDictionary: codingDictionary)
			}
			else
			{
				return nil
			}
		}
	}
	
	var codingDictionary: NSDictionary
	{
		var dictionary:[String : AnyObject] = [:]
		
		dictionary["name"] = name
		dictionary["suffix"] = suffix
		dictionary["appearance"] = appearance.codingDictionary
		dictionary["features"] = features.map { $0.codingDictionary }
		dictionary["completionitems"] = completionItems.map { $0.codingDictionary }
		
		return dictionary
	}
}

extension SKAppearance : SKEncoding
{
	init?(codingDictionary: NSDictionary)
	{
		guard
			let font = codingDictionary["font"] as? UIFont,
			let colorTheme = codingDictionary["colortheme"] as? NSDictionary,
			let themeName = codingDictionary["name"] as? String
		else { return nil }
		self.font = font
		let colorThemeData = colorTheme.flatMap
		{ key, value -> (SKColorKey, UIColor)? in
			guard let key = key as? String, value = value as? UIColor, colorKey = SKColorKey(rawValue: key) else { return nil }
			return (colorKey, value)
		}
		self.colorTheme = [:]
		for (key, value) in colorThemeData
		{
			self.colorTheme[key] = value
		}
		self.themeName = themeName
	}
	
	var codingDictionary: NSDictionary
	{
		return [:]
	}
}

extension SKLanguageAutocompletionItem : SKEncoding
{
	init?(codingDictionary: NSDictionary)
	{
		guard
			let name = codingDictionary["name"] as? String,
			let itemDescription = codingDictionary["description"] as? String,
			let searchTags = codingDictionary["searchtags"] as? [String],
			let insertionText = codingDictionary["insertiontext"] as? String,
			let scope = codingDictionary["scope"] as? String?
		else { return nil }
		self.name = name
		self.itemDescription = itemDescription
		self.searchTags = searchTags
		self.insertionText = insertionText
		self.scope = scope
	}
	
	var codingDictionary: NSDictionary
	{
		var dictionary:[String:AnyObject] = [:]
		
		dictionary["name"] = name
		dictionary["description"] = itemDescription
		dictionary["searchtags"] = searchTags
		dictionary["insertiontext"] = insertionText
		dictionary["scope"] = scope
		
		return dictionary
	}
}
