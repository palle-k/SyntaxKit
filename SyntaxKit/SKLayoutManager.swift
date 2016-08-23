//
//  SKLayoutManager.swift
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
import UIKit

@available(*, deprecated:1.0, renamed:"LineNumberLayoutManager")
typealias SKLayoutManager = LineNumberLayoutManager

class LineNumberLayoutManager : NSLayoutManager
{
	fileprivate var lastParagraphNumber: Int = 0
	fileprivate var lastParagraphLocation: Int = 0
	internal let lineNumberWidth: CGFloat = 30.0
	
	override func processEditing(for textStorage: NSTextStorage, edited editMask: NSTextStorageEditActions, range newCharRange: NSRange, changeInLength delta: Int, invalidatedRange invalidatedCharRange: NSRange)
	{
		super.processEditing(for: textStorage, edited: editMask, range: newCharRange, changeInLength: delta, invalidatedRange: invalidatedCharRange)
		
		if invalidatedCharRange.location < lastParagraphLocation
		{
			lastParagraphLocation = 0
			lastParagraphNumber = 0
		}
	}
	
	override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint)
	{
		super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
		
		let font = UIFont(name: "Menlo", size: 10.0)!
		let color = UIColor.lightGray
		
		let attributes = [NSFontAttributeName : font, NSForegroundColorAttributeName : color]
		
		var numberRect = CGRect.zero
		var paragraphNumber = 0
		
		let ctx = UIGraphicsGetCurrentContext()
		ctx?.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
		ctx?.fill(CGRect(x: 0, y: 0, width: lineNumberWidth, height: self.textContainers[0].size.height))
		
		self.enumerateLineFragments(forGlyphRange: glyphsToShow)
		{ (rect, usedRect, textContainer, glyphRange, stop) in
			let charRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
			let paragraphRange = (self.textStorage!.string as NSString).paragraphRange(for: charRange)
			
			if charRange.location == paragraphRange.location
			{
				numberRect = CGRect(x: 0, y: rect.origin.y, width: self.lineNumberWidth, height: rect.size.height).offsetBy(dx: origin.x, dy: origin.y)
				paragraphNumber = self.paragraphNumber(forRange: charRange)
				let lineNumber = "\(paragraphNumber + 1)" as NSString
				let size = lineNumber.size(attributes: attributes)
				lineNumber.draw(in: numberRect.offsetBy(dx: numberRect.width - 4 - size.width, dy: (numberRect.height - size.height) * 0.5 + 1.0), withAttributes: attributes)
			}
		}
		
		if NSMaxRange(glyphsToShow) > self.numberOfGlyphs
		{
			let lineNumber = "\(paragraphNumber + 2)" as NSString
			let size = lineNumber.size(attributes: attributes)
			numberRect = numberRect.offsetBy(dx: 0, dy: numberRect.height)
			lineNumber.draw(in: numberRect.offsetBy(dx: numberRect.width - 4 - size.width, dy: (numberRect.height - size.height) * 0.5 + 1.0), withAttributes: attributes)
		}
	}
	
	fileprivate func paragraphNumber(forRange charRange: NSRange) -> Int
	{
		if charRange.location == lastParagraphLocation
		{
			return lastParagraphNumber
		}
		else if charRange.location < lastParagraphLocation
		{
			let string = textStorage!.string as NSString
			
			var paragraphNumber = lastParagraphNumber
			
			string.enumerateSubstrings(
				in: NSRange(
					location: charRange.location,
					length: lastParagraphLocation - charRange.location),
				options: [.byParagraphs, .substringNotRequired, .reverse])
			{ (substring, substringRange, enclosingRange, stop) in
				if enclosingRange.location <= charRange.location
				{
					stop.pointee = true
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
			
			string.enumerateSubstrings(
				in: NSRange(
					location: lastParagraphLocation,
					length: charRange.location - lastParagraphLocation),
				options: [.byParagraphs, .substringNotRequired])
			{ (substring, substringRange, enclosingRange, stop) in
				if enclosingRange.location >= charRange.location
				{
					stop.pointee = true
				}
				paragraphNumber += 1
			}
			lastParagraphNumber = paragraphNumber
			lastParagraphLocation = charRange.location
			return paragraphNumber
		}
	}
}
