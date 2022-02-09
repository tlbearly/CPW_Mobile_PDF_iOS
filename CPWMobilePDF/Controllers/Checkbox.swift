//
//  Checkbox.swift
//  CPWMobilePDF
//
//  Created by Tammy Bearly on 1/24/22.
//  Copyright © 2022 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class CheckBox: UIButton {
    // Images
    let checkedImage = UIImage(named: "checkbox_checked")! as UIImage
    let uncheckedImage = UIImage(named: "checkbox_blank")! as UIImage
    
    // Bool property
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                self.setImage(checkedImage, for: UIControl.State.normal)
            } else {
                self.setImage(uncheckedImage, for: UIControl.State.normal)
            }
        }
    }
    
    @objc func buttonClicked(_ sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
    
    override func awakeFromNib() {
        self.addTarget(self, action: #selector(buttonClicked), for: UIControl.Event.touchUpInside)
        self.isChecked = false
    }
}
