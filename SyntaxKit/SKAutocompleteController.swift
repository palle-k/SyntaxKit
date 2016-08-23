//
//  SKAutocompleteController.swift
//  SyntaxKit
//
//  Created by Palle Klewitz on 09.05.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Foundation
import UIKit

@available(*, deprecated:1.0, renamed:"AutocompleteController")
public typealias SKAutocompleteController = AutocompleteController

open class AutocompleteController : NSObject, UITableViewDataSource, UITableViewDelegate
{
	internal fileprivate(set) var autocompleteView: AutocompleteView!
	
	init(withView view: AutocompleteView)
	{
		self.autocompleteView = view
		super.init()
	}
	
	open func numberOfSections(in tableView: UITableView) -> Int
	{
		return 1
	}
	
	open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return 0
	}
	
	open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "", for: indexPath)
		return cell
	}
}
