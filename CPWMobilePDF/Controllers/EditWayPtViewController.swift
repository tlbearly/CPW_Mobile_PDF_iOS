//
//  EditWayPtViewController.swift
//  CPW Mobile PDF
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
    @IBOutlet weak var pushPin: UIImageView!
    var x:Float = 0.0
    var y:Float = 0.0
    
    var pushPinImg:String = "cyan_pin"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let items = wayPt.components(separatedBy: "$")
        wayPtDesc.text = items[0]
        latLong.text = items[1]
        addDate.text = items[2]
        pushPinImg = items[3]
        pushPin.image = UIImage(named: pushPinImg)
        x = Float(items[4]) ?? 0.0
        y = Float(items[5]) ?? 0.0
    }
    
    // preserve orientation
    override open var shouldAutorotate: Bool {
        // do not auto rotate
        return false
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
       
    }
    
    @IBAction func redBtnClicked(_ sender: Any) {
        //print("red button clicked")
        pushPinImg = "red_pin"
        pushPin.image = UIImage(named: pushPinImg)
    }
    
    @IBAction func blueBtnClicked(_ sender: Any) {
        //print("blue button clicked")
        pushPinImg = "blue_pin"
        pushPin.image = UIImage(named: pushPinImg)
    }
    
    @IBAction func cyanBtnClicked(_ sender: Any) {
        //print("cyan button clicked")
        pushPinImg = "cyan_pin"
        pushPin.image = UIImage(named: pushPinImg)
    }
}
