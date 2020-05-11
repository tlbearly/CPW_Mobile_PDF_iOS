//
//  PDFMap.swift
//  MapViewer
//
//  Purpose: hold all the necessary info for a geo pdf map
//     Maps are stored in local documents directory so they can be taken offline, but still get backed up.
//
//
//  Created by Tammy Bearly on 4/15/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit
import PDFKit

class PDFMap {
    var displayName: String = "" // PDF display name, user can modify this
    var fileName: String = "" // PDF filename
    var fileURL: URL? // PDF filename and URL
    var thumbnail: UIImage?
    var bounds:[Double] = [0.0, 0.0, 0.0, 0.0]
    var modDate:Double = 0.0 // modification date
    var fileSize:String = "0 KB" // PDF file size
    
    // margins
    var marginTop: Double = 0.0
    var marginBottom: Double = 0.0
    var marginLeft: Double = 0.0
    var marginRight: Double = 0.0
    
    // mediabox (page size)
    var mediaBoxHeight: Double = 0.0
    var mediaBoxWidth: Double = 0.0
    
    var pdfWidth: Double = 0.0
    var pdfHeight: Double = 0.0
    
    // lat / long
    var lat1:Double = 0.0
    var lat2:Double = 0.0
    var long1:Double = 0.0
    var long2:Double = 0.0
    var latNow:Double = 0.0
    var longNow:Double = 0.0
    var latDiff: Double = 0.0
    var longDiff: Double = 0.0
    
    init?(fileName: String) {
        // Read each map from library. Files stored in documents directory.
        if fileName.isEmpty {
            return nil
        }
        
        //self.displayName = fileName
        self.fileName = fileName
        
        // strip off .pdf
        let index = fileName.firstIndex(of: ".") ?? fileName.endIndex
        self.displayName = String(fileName[..<index]) // without .pdf
        
        // Get URL
        // To enable “Open in place” add “Application supports iTunes file sharing” or “UIFileSharingEnabled” key with value “YES” in Info.plist and to enable “File sharing” add “LSSupportsOpeningDocumentsInPlace” or “Supports opening documents in place” key with value “YES” in Info.plist.
        // PDF Maps stored in Documents directory. User can access, copy, share, and delete. Gets backed up.
        
        guard let url = pathForDocumentDirectoryAsURL()?.appendingPathComponent(fileName) else {
            return nil
        }
        
        self.fileURL = url
        // Parse PDF return bounds (lat, long), viewport (margins), mediabox (page size).
        let pdf: [String:Any?] = PDFParser.parse(pdfUrl: self.fileURL!)
        print ("--")
        print ("-- RETURNED VALUES --")
        print ("PDF: \(self.displayName)")
        if ((pdf["error"]) != nil) {
            print(pdf["error"]!!)
            return
        }
        guard let bounds = pdf["bounds"]!! as? [Double] else {
            print("Error: cannot convert bounds to float array")
            return
        }
        print ("lat/long bounds: \(bounds)")
        guard let viewport = pdf["viewport"]!! as? [Float] else{
            print("Error: cannot convert viewport to float array")
            return
        }
        print ("viewport margins: \(viewport)")
        guard let mediabox = pdf["mediabox"]!! as? [Float] else {
            print("Error: cannot convert mediabox to float array")
            return
        }
        print ("mediabox page size: \(mediabox)")
        marginTop = Double(mediabox[3] - viewport[1])
        marginBottom = Double(viewport[3])
        marginLeft = Double(viewport[0])
        marginRight = Double(mediabox[2] - viewport[2])
        mediaBoxWidth = Double(mediabox[2] - mediabox[0])
        mediaBoxHeight = Double(mediabox[3] - mediabox[1])
        lat1 = bounds[0]
        long1 = bounds[1]
        lat2 = bounds[2]
        long2 = bounds[5]
        latDiff = (90.0 - lat1) - (90.0 - lat2)
        longDiff = (long2 + 180.0) - (long1 + 180.0)
        // mediaBox is page boundary
        pdfWidth = (mediaBoxWidth - (marginLeft + marginRight)) // don't need * zoom
        pdfHeight = (mediaBoxHeight - (marginTop + marginBottom))
        

        
        
        
        // Get thumbnail
        self.thumbnail = pdfThumbnail(url: url, width: 90, height: 90) ??  UIImage(imageLiteralResourceName: "pdf_icon")
        
        
        // Get modification date and file size
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.relativePath)
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

      let screenSize = CGSize(width: width, height: height)
      return page.thumbnail(of: screenSize, for: .mediaBox)
    }
    
    func pathForDocumentDirectoryAsURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    func pathForDocumentDirectoryAsString() -> [String]? {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    }
    
    func pathForAppSupportDirectoryAsUrl() -> URL? {
        var appSupportDirectory: URL?
        do {
            appSupportDirectory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        }catch {
            // failed to read directory - bad permissions, perhaps?
            return nil
        }
        return appSupportDirectory
    }
    
    func volumeCapacityForImportantUsage() -> Int64? {
        let documentDirectoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        var results: URLResourceValues?
        do {
            results = try documentDirectoryPath?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        } catch {
            return 0
        }
        return results?.volumeAvailableCapacityForImportantUsage
    }
    
}
