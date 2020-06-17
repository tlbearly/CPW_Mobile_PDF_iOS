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
    // PDF display name, user can modify this
    var displayName: String = "" {didSet {
            print("Map Name changed to \(displayName).")
        }}
    
    var fileName: String = "" // PDF filename
    var fileURL: URL? // PDF filename and URL
    var thumbnail: UIImage?
    private var bounds:[Double] = [0.0, 0.0, 0.0, 0.0]
    var modDate:Double = 0.0 // modification date
    var fileSize:String = "File size" // PDF file size
    var mapDist:String = "Dist. to map" // show distance to map (10 mi) or if on map, only show location icon
    var showLocationIcon:Bool = true // show location icon if on map
    
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
    
    
    init?(fileName: String, fileURL: URL, quick: Bool) throws {
        // Just set displayName to Loading..., check that fileName is not nil or "", check that fileURL exists.
        // Will be used to add to the maps list table and display a progress bar
        self.displayName = "Loading..."
        
        // Set file name
        guard let testFile = setFileName(fileName: fileName) else {
            throw AppError.pdfMapError.invalidFilename
        }
        self.fileName = testFile
        
        // Set file URL if the file exists
        guard let url = urlExists(url: fileURL) else {
            throw AppError.pdfMapError.pdfFileNotFound(file: fileURL.absoluteString)
        }
        self.fileURL = url
    }
    
    init?(fileName: String, fileURL: URL, progress: UIProgressView) throws {
        // Called after add map from file picker or download from website
        // called by MapListTableViewController.swift, unwindToMapsList, importMap
// NOT USED
        do {
            try setFileNameAndDisplayName(fileName: fileName)
        } catch let AppError {
            throw AppError
        }
        
        // copy url to app documents directory
        
    }
    
    init?(fileURL: URL) throws {
        // Import a new file from filepicker or downloaded from the web. Make sure it exists, is a pdf,
        // and then copy it to the app documents directory.
        guard let url = urlExists(url: fileURL) else {
            print("map does not exist. file: \(fileURL.absoluteString)")
            throw AppError.pdfMapError.pdfFileNotFound(file: fileURL.absoluteString)
        }
        self.fileURL = url
        
        
        // copy url to app documents
        // destination directory name
         guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
             print("Can't get documents directory.")
            throw AppError.pdfMapError.invalidDocumentDirectory
         }
         
        self.fileName = fileURL.lastPathComponent
        setDisplayName()
        var destURL = documentsURL.appendingPathComponent(self.fileName)
         
        var index = 0
        let fileManager = FileManager.default
        var name:String = ""
        while fileManager.fileExists(atPath: destURL.path){
            index += 1
            name = self.displayName + String(index) + ".pdf"
            destURL = documentsURL.appendingPathComponent(name)
        }
        
         do {
             try FileManager.default.copyItem(at:fileURL, to: destURL)
         }
         catch{
            print("ERROR: unable to copy file to the app documents directory")
            throw AppError.pdfMapError.pdfFileNotFound(file: fileURL.absoluteString)
         }
        self.fileName = name
        setDisplayName()
        self.fileURL = destURL
        
        // Parse PDF return bounds (lat, long), viewport (margins), mediabox (page size).
        do {
            try readPDF()
        } catch let AppError  {
            throw AppError
        }
        
        // Get thumbnail
        self.thumbnail = pdfThumbnail(url: url, width: 90, height: 90) ??  UIImage(imageLiteralResourceName: "pdf_icon")
        
        // get modification date and file size
        do {
            try getModDateFileSize(url: destURL)
        } catch let AppError {
            throw AppError
        }
        
        // Location: on map or distance to map in miles
        mapDist = distanceToMap()
        showLocationIcon = true
    }
    
    init?(fileName: String) throws {
        // Read each map from app documents directory.
        guard let testFile = setFileName(fileName: fileName) else {
            throw AppError.pdfMapError.invalidFilename
        }
        self.fileName = testFile
        
        setDisplayName()
        
        // Get URL
        // To enable “Open in place” add “Application supports iTunes file sharing” or “UIFileSharingEnabled” key with value “YES” in Info.plist and to enable “File sharing” add “LSSupportsOpeningDocumentsInPlace” or “Supports opening documents in place” key with value “YES” in Info.plist.
        // PDF Maps stored in Documents directory. User can access, copy, share, and delete. Gets backed up.
        
        guard let testUrl = getURLInDocumentsDirectory(fileName: self.fileName)
        else {
            print("documents directory does not exists.")
            throw AppError.pdfMapError.invalidDocumentDirectory
        }

        guard let url = urlExists(url: testUrl) else {
            print("map does not exist. file: \(testUrl.absoluteString)")
            throw AppError.pdfMapError.pdfFileNotFound(file: testUrl.absoluteString)
        }
        self.fileURL = url
        

        // Parse PDF return bounds (lat, long), viewport (margins), mediabox (page size).
        let pdf: [String:Any?] = PDFParser.parse(pdfUrl: self.fileURL!)
        print ("Import PDF: \(self.displayName)")
        if ((pdf["error"]) != nil) {
            print(pdf["error"]!!)
            switch pdf["error"] as! String {
            case "CannotOpePDF":
                throw AppError.pdfMapError.cannotOpenPDF
            case "PDFVersionTooLow":
                throw AppError.pdfMapError.pdfVersionTooLow
            case "CannotReadPDFDictionary":
                throw AppError.pdfMapError.cannotReadPDFDictionary
            default:
                // delete the file
               /* do {
                    print ("deleting file \(self.fileURL!)")
                    try FileManager.default.removeItem(at: self.fileURL!)
                } catch let error as NSError {
                    print("Error: \(error.domain)")
                }*/
                throw AppError.pdfMapError.unknownFormat
            }
            
        }
        guard let bounds = pdf["bounds"] as? [Double] else {
            print("Error: cannot convert bounds to float array")
            throw AppError.pdfMapError.cannotReadPDFDictionary
        }
       // print ("lat/long bounds: \(bounds)")
        guard let viewport = pdf["viewport"] as? [Float] else{
            print("Error: cannot convert viewport to float array")
            throw AppError.pdfMapError.cannotReadPDFDictionary
        }
       // print ("viewport margins: \(viewport)")
        guard let mediabox = pdf["mediabox"] as? [Float] else {
            print("Error: cannot convert mediabox to float array")
            throw AppError.pdfMapError.cannotReadPDFDictionary
        }
       // print ("mediabox page size: \(mediabox)")
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
        /*do {
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
            throw AppError.pdfMapError.invalidFilename
        }*/
        // get modification date and file size
        do {
            try getModDateFileSize(url: url)
        } catch let AppError {
            throw AppError
        }
        
        // Location: on map or distance to map in miles
        mapDist = "Dist. to Map"
        showLocationIcon = true
    }
    
    func setFileName(fileName: String?) -> String? {
        // make sure fileName is not nil or blank
        guard let name = fileName, !name.isEmpty else {
            return nil
        }
        return name
    }
    
    func getURLInDocumentsDirectory(fileName: String) -> URL? {
        // append the app documents directory to the front of the fileName. Return the url.
        guard let url = pathForDocumentDirectoryAsURL()?.appendingPathComponent(fileName) else {
            print("app documents directory does not exists.")
            return nil
        }
       return url
    }
    
    func urlExists(url: URL) -> URL? {
        // Check if url exists
        let fileManager = FileManager.default
        let filePath = url.path
        if fileManager.fileExists(atPath: filePath) {
            return url
        } else {
            return nil
        }
    }
    
    /*func setFileURL(fileURL: URL) throws {
        if UIApplication.shared.canOpenURL(fileURL as URL) {
            self.fileURL = fileURL
        } else {
            throw AppError.pdfMapError.pdfFileNotFound(file: fileURL.absoluteString)
        }
    }*/
    
    func setDisplayName() {
        // Set displayName, strip off .pdf
        let index = self.fileName.firstIndex(of: ".") ?? self.fileName.endIndex
        self.displayName = String(self.fileName[..<index])
    }
    
    func setFileNameAndDisplayName(fileName: String?) throws {
        // Assumes file is in app documents directory. Used when displaying maps list first time.
        // Set fileName
        guard let name = fileName, !name.isEmpty else {
            throw AppError.pdfMapError.invalidFilename
        }
        self.fileName = name
        
        // Set displayName, strip off .pdf
        let index = self.fileName.firstIndex(of: ".") ?? self.fileName.endIndex
        self.displayName = String(self.fileName[..<index]) // without .pdf
        
        // Set fileURL. Get URL to documents directory
        // To enable “Open in place” add “Application supports iTunes file sharing” or “UIFileSharingEnabled” key with value “YES” in Info.plist and to enable “File sharing” add “LSSupportsOpeningDocumentsInPlace” or “Supports opening documents in place” key with value “YES” in Info.plist.
        // PDF Maps stored in Documents directory. User can access, copy, share, and delete. Gets backed up.
        
        guard let url = pathForDocumentDirectoryAsURL()?.appendingPathComponent(self.fileName) else {
            throw AppError.pdfMapError.invalidDocumentDirectory
        }
        // must be a pdf!
        if url.pathExtension != "pdf" {
            throw AppError.pdfMapError.notPDF
        }
        if UIApplication.shared.canOpenURL(url as URL) {
            self.fileURL = url
        } else {
            throw AppError.pdfMapError.pdfFileNotFound(file: url.absoluteString)
        }
    }

    func readPDF() throws {
        // Parse PDF return bounds (lat, long), viewport (margins), mediabox (page size).
        let pdf: [String:Any?] = PDFParser.parse(pdfUrl: self.fileURL!)
        print ("Import PDF: \(self.displayName)")
       if ((pdf["error"]) != nil) {
           print(pdf["error"]!!)
           switch pdf["error"] as! String {
           case "CannotOpePDF":
               throw AppError.pdfMapError.cannotOpenPDF
           case "PDFVersionTooLow":
               throw AppError.pdfMapError.pdfVersionTooLow
           case "CannotReadPDFDictionary":
               throw AppError.pdfMapError.cannotReadPDFDictionary
           default:
               // delete the file
              /* do {
                   print ("deleting file \(self.fileURL!)")
                   try FileManager.default.removeItem(at: self.fileURL!)
               } catch let error as NSError {
                   print("Error: \(error.domain)")
               }*/
               throw AppError.pdfMapError.unknownFormat
           }
       }
       guard let bounds = pdf["bounds"] as? [Double] else {
           print("Error: cannot convert bounds to float array")
           throw AppError.pdfMapError.cannotReadPDFDictionary
       }
      // print ("lat/long bounds: \(bounds)")
       guard let viewport = pdf["viewport"] as? [Float] else{
           print("Error: cannot convert viewport to float array")
           throw AppError.pdfMapError.cannotReadPDFDictionary
       }
      // print ("viewport margins: \(viewport)")
       guard let mediabox = pdf["mediabox"] as? [Float] else {
           print("Error: cannot convert mediabox to float array")
           throw AppError.pdfMapError.cannotReadPDFDictionary
       }
      // print ("mediabox page size: \(mediabox)")
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
    }
    
    
    func pdfThumbnail(url: URL, width: Int = 90, height: Int = 90) -> UIImage? {
      guard let data = try? Data(contentsOf: url),
      let page = PDFDocument(data: data)?.page(at: 0) else {
        return nil
      }

      let screenSize = CGSize(width: width, height: height)
      return page.thumbnail(of: screenSize, for: .mediaBox)
    }
    
    func getModDateFileSize(url: URL) throws {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.relativePath)
            var date = attr[FileAttributeKey.modificationDate] as? Date
            if date == nil {
                date = attr[FileAttributeKey.creationDate] as? Date
            }
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
            print ("\(self.fileSize)")
        }
        catch {
            throw AppError.pdfMapError.invalidFilename
        }
    }
    
    func distanceToMap() -> String {
        // read current location, check if it is within the bounds of this map
        return "Dist. to Map"
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
