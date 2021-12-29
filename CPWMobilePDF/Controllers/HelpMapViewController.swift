//
//  HelpMapViewController.swift
//  CPWMobilePDF
//
//  Created by Tammy Bearly on 12/27/21.
//  Copyright © 2021 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class HelpMapViewController: UIViewController {
    var maps:[PDFMap] = []
    var mapIndex:Int = -1
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        // pass variables to help map view
        guard let mapViewController = segue.destination as? MapViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        // pass the selected map name, thumbnail, etc to HelpMapViewController.swift
        mapViewController.maps = maps
        mapViewController.mapIndex = mapIndex
    }
}
