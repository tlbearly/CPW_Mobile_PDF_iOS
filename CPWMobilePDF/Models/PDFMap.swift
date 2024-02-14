//
//  PDFMap.swift
//  CPWMobilePDF
//
//  Purpose: hold all the necessary info for a geo pdf map
//     Maps are stored in local documents directory so they can be taken offline, but still get backed up.
//
//
//  Created by Tammy Bearly on 4/15/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//
// Uses NSCoding to store persistent data pdfMaps and waypoints
// v1.0.6 support NSSecureCoding

import UIKit
import PDFKit
import os.log

class PDFMap: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    //MARK: Properties
    // PDF display name, user can modify this
    var displayName: String = ""
    var fileName: String = "" // PDF filename
    var fileURL: URL? // PDF filename and URL in app documents dir
    var thumbnail: UIImage?
    var bounds:[Double] = [0.0, 0.0, 0.0, 0.0]
    var modDate:Double = 0.0 // modification date
    var fileSize:String = "" // PDF file size
    var mapDist:String = "" // show distance to map (10 mi) or if on map, only show location icon
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
    
    var wayPtArray: [WayPt] = []
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    // creates a maps folder in the user's documents folder (for this app) to store all the data
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("maps")

    
    //MARK: Types
    struct PropertyKey {
        static let displayName = "displayName"
        static let fileName = "fileName"
        static let fileURL = "fileURL"
        static let thumbnail = "thumbnail"
        static let bounds1 = "bounds1"
        static let bounds2 = "bounds2"
        static let bounds3 = "bounds3"
        static let bounds4 = "bounds4"
        static let modDate = "modDate"
        static let fileSize = "fileSize"
        static let marginTop = "marginTop"
        static let marginBottom = "marginBottom"
        static let marginLeft = "marginLeft"
        static let marginRight = "marginRight"
        static let mediaBoxHeight = "mediaBoxHeight"
        static let mediaBoxWidth = "mediaBoxWidth"
        static let pdfWidth = "pdfWidth"
        static let pdfHeight = "pdfHeight"
        static let lat1 = "lat1"
        static let lat2 = "lat2"
        static let long1 = "long1"
        static let long2 = "long2"
        static let latDiff = "latDiff"
        static let longDiff = "longDiff"
        static let wayPtArray = "wayPtArray"
    }
    
    // MARK: init read from database
    init(displayName: String, fileName: String, fileURL: URL,thumbnail: UIImage, bounds1: Double, bounds2: Double, bounds3: Double, bounds4: Double, modDate: Double, fileSize: String, marginTop: Double, marginBottom: Double, marginLeft: Double, marginRight: Double, mediaBoxWidth:Double, mediaBoxHeight: Double, pdfWidth: Double, pdfHeight: Double, lat1: Double, lat2: Double, long1: Double, long2: Double, latDiff: Double, longDiff: Double, wayPtArray: [WayPt]){
        self.displayName = displayName
        self.fileName = fileName
        self.fileURL = fileURL
        self.thumbnail = thumbnail
        self.bounds[0] = bounds1
        self.bounds[1] = bounds2
        self.bounds[2] = bounds3
        self.bounds[3] = bounds4
        self.modDate = modDate
        self.fileSize = fileSize
        self.marginTop = marginTop
        self.marginBottom = marginBottom
        self.marginLeft = marginLeft
        self.marginRight = marginRight
        self.mediaBoxWidth = mediaBoxWidth
        self.mediaBoxHeight = mediaBoxHeight
        self.pdfWidth = pdfWidth
        self.pdfHeight = pdfHeight
        self.lat1 = lat1
        self.lat2 = lat2
        self.long1 = long1
        self.long2 = long2
        self.latDiff = latDiff
        self.longDiff = longDiff
        self.wayPtArray = wayPtArray
    }
    
    init?(fileName: String, fileURL: URL, quick: Bool) throws {
        // MARK: init Loading...
        super.init()
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
        self.fileSize = "File size..."
        self.mapDist = "Miles to map..."
        self.thumbnail = UIImage(imageLiteralResourceName: "pdf_icon")
    }
    
    init?(fileURL: URL) throws {
        // MARK: init import
        super.init()
        // Import a new file from filepicker or downloaded from the web. Make sure it exists, that it is a pdf,
        // and then copy it to the app documents directory.
        
        // does the fileURL exist?
        guard let url = urlExists(url: fileURL) else {
            print("map does not exist. file: \(fileURL.absoluteString)")
            throw AppError.pdfMapError.pdfFileNotFound(file: fileURL.absoluteString)
        }
        self.fileURL = url
        
        // copy url to app documents
        // destination directory name
         /*guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
             print("Can't get documents directory.")
            throw AppError.pdfMapError.invalidDocumentDirectory
         }*/
        
        // Make sure there is enough space
        let availBytes:Int64 = volumeCapacityForImportantUsage() ?? 0
        do {
            let size = try getFileSize(url: url)
            if (availBytes < size){
                print ("Not enough space on local directory to save file.")
                throw AppError.pdfMapError.diskFull
            }
        } catch {
            print ("Cannot get file size.")
            throw AppError.pdfMapError.mapNil
        }
        
        
        self.fileName = fileURL.lastPathComponent
        setDisplayName()
        
        // Copy file to app documents directory
        var destURL = PDFMap.DocumentsDirectory.appendingPathComponent(self.fileName)
        var index = 0
        let fileManager = FileManager.default
        var name:String = ""
        while fileManager.fileExists(atPath: destURL.path){
            index += 1
            name = self.displayName + String(index) + ".pdf"
            destURL = PDFMap.DocumentsDirectory.appendingPathComponent(name)
            self.fileName = name
        }
        do {
             try FileManager.default.copyItem(at:fileURL, to: destURL)
        }
        catch let error{
            print("ERROR: unable to copy file to the app documents directory. \(error)")
            throw AppError.pdfMapError.pdfFileNotFound(file: fileURL.absoluteString)
        }
        
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
            try getModDateFileSize(url: destURL, now: true)
        } catch let AppError {
            throw AppError
        }
        
        // Location: on map or distance to map in miles
        mapDist = distanceToMap()
        showLocationIcon = true
    }
    
    init?(fileName: String) throws {
        // MARK: init load
        super.init()
        // Read each map from app documents directory.
        guard let testFile = setFileName(fileName: fileName) else {
            throw AppError.pdfMapError.invalidFilename
        }
        self.fileName = testFile
        
        setDisplayName()
        
        // Get URL
        // To enable “Open in place” add “Application supports iTunes file sharing” or “UIFileSharingEnabled” key with value “YES” in Info.plist and to enable “File sharing” add “LSSupportsOpeningDocumentsInPlace” or “Supports opening documents in place” key with value “YES” in Info.plist.
        // PDF Maps stored in Documents directory. User can access, copy, share, and delete. Gets backed up.
        
        let testUrl = PDFMap.DocumentsDirectory.appendingPathComponent(self.fileName)
        
        guard let url = urlExists(url: testUrl) else {
            print("map does not exist. file: \(testUrl.absoluteString)")
            throw AppError.pdfMapError.pdfFileNotFound(file: testUrl.absoluteString)
        }
        self.fileURL = url
        

        // Read the database for lat long values
        
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
            try getModDateFileSize(url: url)
        } catch let AppError {
            throw AppError
        }
        
        // Location: on map or distance to map in miles
        mapDist = distanceToMap()
        showLocationIcon = false
    }
    
    func setFileName(fileName: String?) -> String? {
        // MARK: setFileName
        // make sure fileName is not nil or blank
        guard let name = fileName, !name.isEmpty else {
            return nil
        }
        return name
    }
    
    func getThumbnail() -> UIImage {
        guard let img:UIImage = self.thumbnail else {
            return UIImage(imageLiteralResourceName: "pdf_icon")
        }
        return img
    }
    
    /*(func getURLInDocumentsDirectory(fileName: String) -> URL {
        // MARK: getURLInDocumentsDir
        // append the app documents directory to the front of the fileName. Return the url.
       let url = PDFMap.DocumentsDirectory.appendingPathComponent(fileName)
       return url
    }*/
    
    func urlExists(url: URL) -> URL? {
        // MARK: urlExists
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
        // MARK: setDisplayName
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
        
        let url = PDFMap.DocumentsDirectory.appendingPathComponent(self.fileName)
        
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
        // MARK: readPDF
        // Parse PDF return bounds (lat, long), viewport (margins), mediabox (page size).
        let pdf: [String:Any?] = PDFParser.parse(pdfUrl: self.fileURL!)
//        print ("Import PDF: \(self.displayName)")
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
       guard let mediabox = pdf["mediabox"] as? [Float] else {
            print("Error: cannot convert mediabox to float array")
            throw AppError.pdfMapError.cannotReadPDFDictionary
        }
        // print ("mediabox page size: \(mediabox)")
        
        // Lat/Long
        guard let bounds = pdf["bounds"] as? [Double] else {
           print("Error: cannot convert bounds to float array")
           throw AppError.pdfMapError.cannotReadPDFDictionary
        }
        // print ("lat/long bounds: \(bounds)")
        
        // Margins
        // viewport x1,y1 is lower-left
        // viewport x2,y2 is upper-right in Adobe PDF documentation
        // but the origin is user specified [25 570 768 48]
        // or sometimes: [25 48 768 570]
        guard let viewport = pdf["viewport"] as? [Float] else{
           print("Error: cannot convert viewport to float array")
           throw AppError.pdfMapError.cannotReadPDFDictionary
        }
        // 5-12-22 Make sure viewport is in correct order
        if(viewport[1] < viewport[3]) {
            marginTop = Double(mediabox[3] - viewport[3])
            marginBottom = Double(viewport[1])
        }else{
            marginTop = Double(mediabox[3] - viewport[1])
            marginBottom = Double(viewport[3])
        }
        if (viewport[0] < viewport[2]){
            marginLeft = Double(viewport[0])
            marginRight = Double(mediabox[2] - viewport[2])
        }else{
            marginLeft = Double(viewport[2])
            marginRight = Double(mediabox[2] - viewport[0])
        }
        // print ("viewport margins: \(viewport)")
       
        mediaBoxWidth = Double(mediabox[2] - mediabox[0])
        mediaBoxHeight = Double(mediabox[3] - mediabox[1])
        // 5-12-22 Find smallest values for lat1/long1 and largest values for lat2/long2
        lat1 = Double(bounds[0])
        long1 = Double(bounds[1])
        lat2 = Double(bounds[0])
        long2 = Double(bounds[1])
        for latlong in bounds {
            // handle longitude
            if (Double(latlong) < 0){
                if (Double(latlong) < long1) {
                    long1 = Double(latlong)
                }
                if (Double(latlong) > long2){
                    long2 = Double(latlong)
                }
            }
            // handle latitude
            else{
                if (Double(latlong) < lat1) {
                    lat1 = Double(latlong)
                }
                if (Double(latlong) > lat2){
                    lat2 = Double(latlong)
                }
            }
        }
        
        latDiff = lat2 - lat1
        longDiff = long2 - long1
        // mediaBox is page boundary
        pdfWidth = (mediaBoxWidth - (marginLeft + marginRight)) // don't need * zoom
        pdfHeight = (mediaBoxHeight - (marginTop + marginBottom))
    }
    
    
    func pdfThumbnail(url: URL, width: Int = 90, height: Int = 90) -> UIImage? {
      // MARK: pdfThumbnail
      guard let data = try? Data(contentsOf: url),
      let page = PDFDocument(data: data)?.page(at: 0) else {
        return nil
      }

      let screenSize = CGSize(width: width, height: height)
      return page.thumbnail(of: screenSize, for: .mediaBox)
    }
    
    func getFileSize(url: URL) throws -> Int64 {
        // MARK: getFileSize
        // return file size in bytes
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.relativePath)
            // PDF file size in KB or MB or GB
            let size = attr[FileAttributeKey.size] as! Int64
            return size
        }
        catch {
            throw AppError.pdfMapError.invalidFilename
        }
    }
    
    func getModDateFileSize(url: URL, now: Bool = false) throws {
        // MARK: getModDateFileSize
        // Set the modification date, date imported
        // Set the file size as string with units
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.relativePath)
            if (now){
                self.modDate = Date().timeIntervalSinceReferenceDate
            }
            else {
                var date = attr[FileAttributeKey.modificationDate] as? Date
                if date == nil {
                    date = attr[FileAttributeKey.creationDate] as? Date
                }
                self.modDate = date?.timeIntervalSince1970 ?? 0.0
            }
            // PDF file size in KB or MB or GB
            var size = attr[FileAttributeKey.size] as! Double
            var units = " KB"
            size = size / 1000.0
            if size >= 1000.0 {
                size = size / 1000.0
                units = " MB"
            }
            if size >= 1000.0 {
                size = size / 1000.0
                units = " GB"
            }
            self.fileSize = String(format: "%.0f",size) + units
            //print ("\(self.fileSize)")
        }
        catch {
            throw AppError.pdfMapError.invalidFilename
        }
    }
    
    func distanceToMap() -> String {
        // MARK: distanceToMap
        // read current location, check if it is within the bounds of this map
        return "Dist. to Map"
    }
    
    /*func pathForDocumentDirectoryAsURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }*/
    
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
        // Check available disk space in app documents dir. for important resources (app needs to function)
        // returns available space in bytes
        let documentDirectoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        var results: URLResourceValues?
        do {
            results = try documentDirectoryPath?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        } catch {
            return 0
        }
        return results?.volumeAvailableCapacityForImportantUsage
    }
    
    // MARK: NSCoding
    func encode(with coder: NSCoder) {
        // write persistent data
        //print("writing \(self.fileName)")
        coder.encode(displayName, forKey: PropertyKey.displayName)
        coder.encode(fileName, forKey: PropertyKey.fileName)
        coder.encode(fileURL!.path, forKey: PropertyKey.fileURL)
        coder.encode(thumbnail, forKey: PropertyKey.thumbnail)
        coder.encode(bounds[0], forKey: PropertyKey.bounds1)
        coder.encode(bounds[1], forKey: PropertyKey.bounds2)
        coder.encode(bounds[2], forKey: PropertyKey.bounds3)
        coder.encode(bounds[3], forKey: PropertyKey.bounds4)
        coder.encode(modDate, forKey: PropertyKey.modDate)
        coder.encode(fileSize, forKey: PropertyKey.fileSize)
        coder.encode(marginTop, forKey: PropertyKey.marginTop)
        coder.encode(marginBottom, forKey: PropertyKey.marginBottom)
        coder.encode(marginLeft, forKey: PropertyKey.marginLeft)
        coder.encode(marginRight, forKey: PropertyKey.marginRight)
        coder.encode(mediaBoxHeight, forKey: PropertyKey.mediaBoxHeight)
        coder.encode(mediaBoxWidth, forKey: PropertyKey.mediaBoxWidth)
        coder.encode(pdfWidth, forKey: PropertyKey.pdfWidth)
        coder.encode(pdfHeight, forKey: PropertyKey.pdfHeight)
        coder.encode(lat1, forKey: PropertyKey.lat1)
        coder.encode(lat2, forKey: PropertyKey.lat2)
        coder.encode(long1, forKey: PropertyKey.long1)
        coder.encode(long2, forKey: PropertyKey.long2)
        coder.encode(latDiff, forKey: PropertyKey.latDiff)
        coder.encode(longDiff, forKey: PropertyKey.longDiff)
        
        // MARK: add waypoints
        coder.encode(wayPtArray, forKey: PropertyKey.wayPtArray)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // read persistent data (imported maps) via NSCoding
        
        // The display name is required. If we cannot decode a display name string, the initializer should fail.
        /*guard let displayName = aDecoder.decodeObject(forKey: PropertyKey.displayName) as? String else { os_log("Unable to decode the display name for a PDF Map object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let fileName = aDecoder.decodeObject(forKey: PropertyKey.fileName) as? String else {
            os_log("Unable to decode the file name for a PDF Map object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let fileURLStr = aDecoder.decodeObject(forKey: PropertyKey.fileURL) as? String else {
            os_log("Unable to decode the map URL for a PDF Map object.", log: OSLog.default, type: .debug)
            return nil
        }
        let fileURL = URL(fileURLWithPath: fileURLStr)
        
        // Because thumbnail is an optional property of PDFMap, just use conditional cast.
        guard let thumbnail = aDecoder.decodeObject(forKey: PropertyKey.thumbnail) as? UIImage else {
            os_log("Unable to decode the thumbnail for a PDF Map object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let bounds1 = aDecoder.decodeDouble(forKey: PropertyKey.bounds1)
        let bounds2 = aDecoder.decodeDouble(forKey: PropertyKey.bounds2)
        let bounds3 = aDecoder.decodeDouble(forKey: PropertyKey.bounds3)
        let bounds4 = aDecoder.decodeDouble(forKey: PropertyKey.bounds4)
        let modDate = aDecoder.decodeDouble(forKey: PropertyKey.modDate)
        guard let fileSize = aDecoder.decodeObject(forKey: PropertyKey.fileSize) as? String else { return nil }
        let marginTop = aDecoder.decodeDouble(forKey: PropertyKey.marginTop)
        let marginBottom = aDecoder.decodeDouble(forKey: PropertyKey.marginBottom)
        let marginLeft = aDecoder.decodeDouble(forKey: PropertyKey.marginLeft)
        let marginRight = aDecoder.decodeDouble(forKey: PropertyKey.marginRight)
        let mediaBoxHeight = aDecoder.decodeDouble(forKey: PropertyKey.mediaBoxHeight)
        let mediaBoxWidth = aDecoder.decodeDouble(forKey: PropertyKey.mediaBoxWidth)
        let pdfWidth = aDecoder.decodeDouble(forKey: PropertyKey.pdfWidth)
        let pdfHeight = aDecoder.decodeDouble(forKey: PropertyKey.pdfHeight)
        let lat1 = aDecoder.decodeDouble(forKey: PropertyKey.lat1)
        let lat2 = aDecoder.decodeDouble(forKey: PropertyKey.lat2)
        let long1 = aDecoder.decodeDouble(forKey: PropertyKey.long1)
        let long2 = aDecoder.decodeDouble(forKey: PropertyKey.long2)
        let latDiff = aDecoder.decodeDouble(forKey: PropertyKey.latDiff)
        let longDiff = aDecoder.decodeDouble(forKey: PropertyKey.longDiff)
        
        // MARK: add waypoints
        let wayPtArray = aDecoder.decodeObject(forKey: PropertyKey.wayPtArray) as? [WayPt] ?? []
        */
        
        // update to use secure coding 8/16/23
        // The display name is required. If we cannot decode a display name string, the initializer should fail.
        guard let displayName = aDecoder.decodeObject(forKey: PropertyKey.displayName) as? String else { os_log("Unable to decode the display name for a PDF Map object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let fileName = aDecoder.decodeObject(forKey: PropertyKey.fileName) as? String else {
            os_log("Unable to decode the file name for a PDF Map object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let fileURLStr = aDecoder.decodeObject(forKey: PropertyKey.fileURL) as? String else {
            os_log("Unable to decode the map URL for a PDF Map object.", log: OSLog.default, type: .debug)
            return nil
        }
        let fileURL = URL(fileURLWithPath: fileURLStr)
        
        // Because thumbnail is an optional property of PDFMap, just use conditional cast.
        guard let thumbnail = aDecoder.decodeObject(forKey: PropertyKey.thumbnail) as? UIImage else {
            os_log("Unable to decode the thumbnail for a PDF Map object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let bounds1 = aDecoder.decodeDouble(forKey: PropertyKey.bounds1)
        let bounds2 = aDecoder.decodeDouble(forKey: PropertyKey.bounds2)
        let bounds3 = aDecoder.decodeDouble(forKey: PropertyKey.bounds3)
        let bounds4 = aDecoder.decodeDouble(forKey: PropertyKey.bounds4)
        let modDate = aDecoder.decodeDouble(forKey: PropertyKey.modDate)
        guard let fileSize = aDecoder.decodeObject(forKey: PropertyKey.fileSize) as? String else { return nil }
        let marginTop = aDecoder.decodeDouble(forKey: PropertyKey.marginTop)
        let marginBottom = aDecoder.decodeDouble(forKey: PropertyKey.marginBottom)
        let marginLeft = aDecoder.decodeDouble(forKey: PropertyKey.marginLeft)
        let marginRight = aDecoder.decodeDouble(forKey: PropertyKey.marginRight)
        let mediaBoxHeight = aDecoder.decodeDouble(forKey: PropertyKey.mediaBoxHeight)
        let mediaBoxWidth = aDecoder.decodeDouble(forKey: PropertyKey.mediaBoxWidth)
        let pdfWidth = aDecoder.decodeDouble(forKey: PropertyKey.pdfWidth)
        let pdfHeight = aDecoder.decodeDouble(forKey: PropertyKey.pdfHeight)
        let lat1 = aDecoder.decodeDouble(forKey: PropertyKey.lat1)
        let lat2 = aDecoder.decodeDouble(forKey: PropertyKey.lat2)
        let long1 = aDecoder.decodeDouble(forKey: PropertyKey.long1)
        let long2 = aDecoder.decodeDouble(forKey: PropertyKey.long2)
        let latDiff = aDecoder.decodeDouble(forKey: PropertyKey.latDiff)
        let longDiff = aDecoder.decodeDouble(forKey: PropertyKey.longDiff)
        
        // MARK: add waypoints
        if #available(iOS 14.0, *) {
            let wayPtArray = aDecoder.decodeArrayOfObjects(ofClasses: [WayPt.self, NSString.self, NSNumber.self], forKey: PropertyKey.wayPtArray) as? [WayPt] ?? []
            // Must call designated initializer.
            self.init(displayName: displayName, fileName: fileName, fileURL: fileURL,thumbnail: thumbnail, bounds1: bounds1, bounds2: bounds2, bounds3: bounds3, bounds4: bounds4, modDate: modDate, fileSize: fileSize, marginTop: marginTop, marginBottom: marginBottom, marginLeft: marginLeft, marginRight: marginRight, mediaBoxWidth:mediaBoxWidth, mediaBoxHeight: mediaBoxHeight, pdfWidth: pdfWidth, pdfHeight: pdfHeight, lat1: lat1, lat2: lat2, long1: long1, long2: long2, latDiff: latDiff, longDiff: longDiff, wayPtArray: wayPtArray)
        } else {
            // Fallback on earlier versions
            let wayPtArray = aDecoder.decodeObject(forKey: PropertyKey.wayPtArray) as? [WayPt] ?? []
            // Must call designated initializer.
            self.init(displayName: displayName, fileName: fileName, fileURL: fileURL,thumbnail: thumbnail, bounds1: bounds1, bounds2: bounds2, bounds3: bounds3, bounds4: bounds4, modDate: modDate, fileSize: fileSize, marginTop: marginTop, marginBottom: marginBottom, marginLeft: marginLeft, marginRight: marginRight, mediaBoxWidth:mediaBoxWidth, mediaBoxHeight: mediaBoxHeight, pdfWidth: pdfWidth, pdfHeight: pdfHeight, lat1: lat1, lat2: lat2, long1: long1, long2: long2, latDiff: latDiff, longDiff: longDiff, wayPtArray: wayPtArray)
        }
    }
}
