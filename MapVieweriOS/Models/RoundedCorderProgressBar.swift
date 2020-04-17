//
//  roundedCorderProgressBar.swift
//  MapViewer
//
//  Created by Brittney Bearly on 4/15/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//
// From: https://stackoverflow.com/questions/31259993/change-height-of-uiprogressview-in-swift

import UIKit

class RoundedCornerProgressBar: UIProgressView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maskLayerPath = UIBezierPath(roundedRect: bounds, cornerRadius: 10.0)
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskLayerPath.cgPath
        layer.mask = maskLayer
    }
}
