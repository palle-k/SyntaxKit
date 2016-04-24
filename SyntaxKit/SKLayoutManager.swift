//
//  SKLayoutManager.swift
//  SyntaxKit
//
//  Created by Palle Klewitz on 24.04.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Foundation
import UIKit

class SKLayoutManager : NSLayoutManager
{
	private var lastParagraphNumber: Int = 0
	private var lastParagraphLocation: Int = 0
	internal let lineNumberWidth: CGFloat = 30.0
	
	override func processEditingForTextStorage(textStorage: NSTextStorage, edited editMask: NSTextStorageEditActions, range newCharRange: NSRange, changeInLength delta: Int, invalidatedRange invalidatedCharRange: NSRange)
	{
		super.processEditingForTextStorage(textStorage, edited: editMask, range: newCharRange, changeInLength: delta, invalidatedRange: invalidatedCharRange)
		
		if invalidatedCharRange.location < lastParagraphLocation
		{
			lastParagraphLocation = 0
			lastParagraphNumber = 0
		}
	}
	
	override func drawBackgroundForGlyphRange(glyphsToShow: NSRange, atPoint origin: CGPoint)
	{
		super.drawBackgroundForGlyphRange(glyphsToShow, atPoint: origin)
		
		let font = UIFont(name: "Menlo", size: 10.0)!
		let color = UIColor.lightGrayColor()
		
		let attributes = [NSFontAttributeName : font, NSForegroundColorAttributeName : color]
		
		var numberRect = CGRectZero
		var paragraphNumber = 0
		
		let ctx = UIGraphicsGetCurrentContext()
		CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().colorWithAlphaComponent(0.1).CGColor)
		CGContextFillRect(ctx, CGRect(x: 0, y: 0, width: lineNumberWidth, height: self.textContainers[0].size.height))
		
		self.enumerateLineFragmentsForGlyphRange(glyphsToShow)
		{ (rect, usedRect, textContainer, glyphRange, stop) in
			let charRange = self.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
			let paragraphRange = (self.textStorage!.string as NSString).paragraphRangeForRange(charRange)
			
			if charRange.location == paragraphRange.location
			{
				numberRect = CGRectOffset(CGRectMake(0, rect.origin.y, self.lineNumberWidth, rect.size.height), origin.x, origin.y)
				paragraphNumber = self.paragraphNumber(forRange: charRange)
				let lineNumber = "\(paragraphNumber + 1)" as NSString
				let size = lineNumber.sizeWithAttributes(attributes)
				lineNumber.drawInRect(CGRectOffset(numberRect, CGRectGetWidth(numberRect) - 4 - size.width, (CGRectGetHeight(numberRect) - size.height) * 0.5 + 1.0), withAttributes: attributes)
			}
		}
		
		if NSMaxRange(glyphsToShow) > self.numberOfGlyphs
		{
			let lineNumber = "\(paragraphNumber + 2)" as NSString
			let size = lineNumber.sizeWithAttributes(attributes)
			numberRect = CGRectOffset(numberRect, 0, CGRectGetHeight(numberRect))
			lineNumber.drawInRect(CGRectOffset(numberRect, CGRectGetWidth(numberRect) - 4 - size.width, (CGRectGetHeight(numberRect) - size.height) * 0.5 + 1.0), withAttributes: attributes)
		}
	}
	
	private func paragraphNumber(forRange charRange: NSRange) -> Int
	{
		if charRange.location == lastParagraphLocation
		{
			return lastParagraphNumber
		}
		else if charRange.location < lastParagraphLocation
		{
			let string = textStorage!.string as NSString
			
			var paragraphNumber = lastParagraphNumber
			
			string.enumerateSubstringsInRange(
				NSRange(
					location: charRange.location,
					length: lastParagraphLocation - charRange.location),
				options: [.ByParagraphs, .SubstringNotRequired, .Reverse])
			{ (substring, substringRange, enclosingRange, stop) in
				if enclosingRange.location <= charRange.location
				{
					stop.memory = true
				}
				paragraphNumber -= 1
			}
			lastParagraphNumber = paragraphNumber
			lastParagraphLocation = charRange.location
			return paragraphNumber
		}
		else
		{
			let string = textStorage!.string as NSString
			
			var paragraphNumber = lastParagraphNumber
			
			string.enumerateSubstringsInRange(
				NSRange(
					location: lastParagraphLocation,
					length: charRange.location - lastParagraphLocation),
				options: [.ByParagraphs, .SubstringNotRequired])
			{ (substring, substringRange, enclosingRange, stop) in
				if enclosingRange.location >= charRange.location
				{
					stop.memory = true
				}
				paragraphNumber += 1
			}
			lastParagraphNumber = paragraphNumber
			lastParagraphLocation = charRange.location
			return paragraphNumber
		}
	}
}