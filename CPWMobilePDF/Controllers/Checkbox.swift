//
//  Checkbox.swift
//  CPWMobilePDF
//
//  Created by Tammy Bearly on 1/24/22.
//  Copyright © 2022 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class CheckBox: UIButton{
    // Images
    let checkedImage = UIImage(named: "checkbox_checked")! as UIImage
    let uncheckedImage = UIImage(named: "checkbox_blank")! as UIImage
    
    // Bool property
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                self.setImage(UIImage(named: "checkbox_checked")! as UIImage, for: UIControl.State.normal)
            } else {
                self.setImage(UIImage(named: "checkbox_blank")! as UIImage, for: UIControl.State.normal)
            }
        }
    }
    
    @objc func buttonClicked(_ sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
    
    override func awakeFromNib() {
        // never used!!
        self.addTarget(self, action: #selector(buttonClicked), for: UIControl.Event.touchUpInside)
        self.isChecked = false
    }
}
