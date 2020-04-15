//
//  Map.swift
//  MapViewer
//
//  Created by Brittney Bearly on 4/15/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class PDFMap {
    var name: String
    var thumbnail: UIImage?
    var bounds:[Double] = [0.0, 0.0, 0.0, 0.0]
    
    init?(name: String, thumbnail: UIImage?) {
        if name.isEmpty {
            return nil
        }
        if thumbnail == nil {
            self.thumbnail = UIImage(imageLiteralResourceName: "pdf_icon")
        }
        else {
            self.thumbnail = thumbnail
        }
        self.name = name
    }
}
