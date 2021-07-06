//
//  ViewController.swift
//  MapViewer
//
//  Purpose: To show a splash screen.
//
//  Created by Tammy Bearly on 4/10/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }


    @IBAction func continueClicked(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

