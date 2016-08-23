//
//  SKAutocompleteView.swift
//  SyntaxKit
//
//  Created by Palle Klewitz on 09.05.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

@available(*, deprecated:1.0, renamed:"AutocompleteView")
typealias SKAutocompleteView = AutocompleteView

internal class AutocompleteView: UITableView
{
	override func willMove(toSuperview newSuperview: UIView?)
	{
		self.layer.borderWidth = 1.0
		self.layer.borderColor = UIColor.gray.cgColor
		self.layer.cornerRadius = 3.0
		self.backgroundColor = UIColor.white
		self.frame.size.width = 400
		self.frame.size.height = 300
	}
}
