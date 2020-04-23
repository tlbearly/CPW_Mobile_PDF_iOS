//
//  PDFMap.swift
//  MapViewer
//
//  Purpose: hold all the necessary info for a geo pdf map
//
//  Created by Tammy Bearly on 4/15/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit
import PDFKit

class PDFMap {
    var displayName: String = "" // PDF display name
    var fileName: String = "" // PDF filename in app directory
    var thumbnail: UIImage?
    var bounds:[Double] = [0.0, 0.0, 0.0, 0.0]
    var modDate:Double = 0.0 // modification date
    var fileSize:String = "0 KB" // PDF file size
    
    init?(fileName: String) {
        if fileName.isEmpty {
            return nil
        }
        
        self.displayName = fileName
        self.fileName = fileName
        
        // strip off .pdf
        let index = fileName.firstIndex(of: ".") ?? fileName.endIndex
        let pdfFileName = String(fileName[..<index]) // without .pdf
        
        // Get URL
        guard let pdfFileURL = Bundle.main.url(forResource: pdfFileName, withExtension: "pdf") else {
            return nil
        }
        
        // Get thumbnail
        self.thumbnail = pdfThumbnail(url: pdfFileURL, width: 90, height: 90) ??  UIImage(imageLiteralResourceName: "pdf_icon")
        
        
        // Get modification date and file size
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: pdfFileURL.relativePath)
            let date = attr[FileAttributeKey.modificationDate] as? Date
            self.modDate = date?.timeIntervalSince1970 ?? 0.0
            // PDF file size in KB or MB
            var size = attr[FileAttributeKey.size] as! Double
            var units = " KB"
            size = size / 1000.0
            if size >= 1000.0 {
                size = size / 1000.0
                units = " MB"
            }
            self.fileSize = String(format: "%.0f",size) + units
        }
        catch {
            return nil
        }
    }
    
    func pdfThumbnail(url: URL, width: Int = 90, height: Int = 90) -> UIImage? {
      guard let data = try? Data(contentsOf: url),
      let page = PDFDocument(data: data)?.page(at: 0) else {
        return nil
      }

      //let pageSize = page.bounds(for: .mediaBox)
      //let pdfScale = width / pageSize.width

      // Apply if you're displaying the thumbnail on screen
      //let scale = UIScreen.main.scale * pdfScale
      //let screenSize = CGSize(width: pageSize.width * scale,
      //                        height: pageSize.height * scale)

      let screenSize = CGSize(width: width, height: height)
      return page.thumbnail(of: screenSize, for: .mediaBox)
    }
}
