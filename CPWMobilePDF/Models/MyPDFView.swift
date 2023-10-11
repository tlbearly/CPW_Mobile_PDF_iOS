//
//  MyPDFView.swift
//  CPWMobilePDF
//
//  Created by Tammy Bearly on 9/27/23.
//  Copyright © 2023 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit
import PDFKit

class MyPDFView: PDFView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
    
}
