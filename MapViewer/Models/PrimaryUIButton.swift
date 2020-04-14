//
//  PrimaryUIButton.swift
//  MapViewer
//
//  Created by Tammy Bearly on 4/10/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class PrimaryUIButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    // Storyboard calls this
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    
    private func setupButton(){
        setShadow()
        setTitleColor(.white, for: .normal)
        //setTitle(theTitle, for: .normal)
        
        backgroundColor     = UIColor.lightGray
        titleLabel?.font    = UIFont(name: "AvenirNext-DemiBold", size: 18)
        layer.cornerRadius  = 20
        layer.borderWidth   = 2
        layer.borderColor   = UIColor.darkGray.cgColor
    }
    private func setShadow(){
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOffset  = CGSize(width: 0.0, height: 0.2)
        layer.shadowRadius  = 2
        layer.shadowOpacity = 0.5
        clipsToBounds       = true
        layer.masksToBounds = false
    }
    
    // Resize button to fit label and add padding
    override var intrinsicContentSize: CGSize {
        get {
            if let thisSize = self.titleLabel?.intrinsicContentSize {
                return CGSize(width: thisSize.width + self.contentEdgeInsets.left + self.contentEdgeInsets.right + 40, height: thisSize.height + self.contentEdgeInsets.top + self.contentEdgeInsets.bottom + 20)
            }
            return super.intrinsicContentSize
        }
    }
}
