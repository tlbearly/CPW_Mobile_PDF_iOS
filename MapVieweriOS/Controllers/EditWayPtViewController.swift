//
//  EditWayPtViewController.swift
//  MapVieweriOS
//
//  Created by Tammy Bearly on 6/2/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class EditWayPtViewController: UIViewController {
    var wayPt:String = ""
    var desc:String = ""
    var latlong:String = ""
    var addDate:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let items = wayPt.components(separatedBy: "$")
        desc = items[0]
        latlong = items[1]
        addDate = items[2]
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
