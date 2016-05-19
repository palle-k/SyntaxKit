//
//  SKAutocompleteController.swift
//  SyntaxKit
//
//  Created by Palle Klewitz on 09.05.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Foundation
import UIKit

public class SKAutocompleteController : NSObject, UITableViewDataSource, UITableViewDelegate
{
	internal private(set) var autocompleteView: SKAutocompleteView!
	
	init(withView view: SKAutocompleteView)
	{
		self.autocompleteView = view
		super.init()
	}
	
	public func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return 1
	}
	
	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return 0
	}
	
	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier("", forIndexPath: indexPath)
		return cell
	}
}