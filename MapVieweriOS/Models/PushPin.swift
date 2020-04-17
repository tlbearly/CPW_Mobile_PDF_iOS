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
    
/*    func addAction(linkAnnotation:PDFAnnotation, myPage:PDFPage){
        //PDFAnnotation PDFAction and PDFDestination
        // Create an action that allows the user to open a URL
        let appleURL = URL(string: "http://apple.com")
        let actionURL = PDFActionURL(url: appleURL!)
        linkAnnotation.action = actionURL
        // Create an action that allows the user to jump to a PDFDestination
        let destination = PDFDestination(page: myPage, at: CGPoint(x: 35, y: 275))
        let actionGoTo = PDFActionGoTo(destination: destination)
        linkAnnotation.action = actionGoTo
    }*/
}
