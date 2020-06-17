//
//  PushPin.swift
//  MapVieweriOS
//
//  Add an image annotation to a PDF
//
//  Created by Tammy Bearly on 3/2/20.
//  Copyright © 2020 Tammy Bearly. All rights reserved.
//  From example at:
//  https://pspdfkit.com/blog/2019/image-annotation-via-pdfkit/
//

import UIKit
import PDFKit

class PushPin: PDFAnnotation {
    var image: UIImage?
    
    convenience init(_ image: UIImage?, bounds: CGRect, properties: [AnyHashable : Any]?) {
        // pass an image and bounding rectangle
        self.init(bounds: bounds, forType: PDFAnnotationSubtype.stamp, withProperties: properties)
        self.image = image
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext){
        // Draw original content under the new content.
        //super.draw(with: box, in: context) // draws box with X
        
        // Drawing the image within the annotation's bounds.

        context.clear(bounds) // not clearing background????
        guard let cgImage = image?.cgImage else { return }
        context.draw(cgImage, in: bounds)
    }
}
