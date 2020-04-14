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
        // Do any additional setup after loading the view.
    }


    @IBAction func continueClicked(_ sender: UIButton) {
        // example to pass variables
        //   let mapListVC:MapListViewController = MapListViewController()
        // mapListVC.myValue = someValue
        self.performSegue(withIdentifier: "goToMapList", sender: self)
        
    }
}

