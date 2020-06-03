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
    @IBOutlet weak var wayPtDesc: UITextField!
    @IBOutlet weak var latLong: UILabel!
    @IBOutlet weak var addDate: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let items = wayPt.components(separatedBy: "$")
        wayPtDesc.text = items[0]
        latLong.text = items[1]
        addDate.text = items[2]
        
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    @IBAction func redBtnClicked(_ sender: Any) {
        print("red button clicked")
    }
    
    @IBAction func blueBtnClicked(_ sender: Any) {
        print("blue button clicked")
    }
    
    @IBAction func cyanBtnClicked(_ sender: Any) {
        print("cyan button clicked")
    }
    
    @IBAction func doneBtnClicked(_ sender: Any) {
        print("done button clicked")
        wayPt = wayPtDesc.text ?? "Way Pt Desc$"
        wayPt += "$"
        wayPt += latLong.text ?? "lat, long$"
        wayPt += "$"
        wayPt += addDate.text ?? "Date Added"
    }
    
    @IBAction func trashBtnClicked(_ sender: Any) {
        print("trash button clicked")
    }
}
