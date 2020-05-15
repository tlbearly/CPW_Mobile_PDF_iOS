//
//  MapListViewController.swift
//  MapViewer
//
//  Created by Tammy Bearly on 4/10/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//
// From: https://developer.apple.com/library/archive/referencelibrary/GettingStarted/DevelopiOSAppsSwift/CreateATableView.html


// NOT USED
import UIKit
var showSplashView:Bool = true

class MapListViewController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // show splash screen the first time
        if (showSplashView == true) {
            print("show splash screen now")
            showSplashView = false
            self.performSegue(withIdentifier: "goToSplash", sender: self.superclass)
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        super.prepare(for: segue, sender: sender) // gotoSplash
    }


    
    
}
