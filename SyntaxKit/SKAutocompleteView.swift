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

internal class SKAutocompleteView: UITableView
{
	override func willMoveToSuperview(newSuperview: UIView?)
	{
		self.layer.borderWidth = 1.0
		self.layer.borderColor = UIColor.grayColor().CGColor
		self.layer.cornerRadius = 3.0
		self.backgroundColor = UIColor.whiteColor()
		self.frame.size.width = 400
		self.frame.size.height = 300
	}
}