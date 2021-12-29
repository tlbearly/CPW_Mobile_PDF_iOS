//
//  HelpMapNavigationController.swift
//  CPWMobilePDF
//
//  Created by Tammy Bearly on 12/29/21.
//  Copyright © 2021 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit
class HelpMapNavigationController: UINavigationController {
    var maps:[PDFMap] = []
    var mapIndex:Int = -1
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
