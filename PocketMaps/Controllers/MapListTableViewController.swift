//
//  MapListTableViewController.swift
//  MapViewer
//
//  Created by Tammy Bearly on 4/15/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//
// Show list of imported maps
//
// From: https://developer.apple.com/library/archive/referencelibrary/GettingStarted/DevelopiOSAppsSwift/CreateATableView.html
//
// long press on a table row https://stackoverflow.com/questions/3924446/long-press-on-uitableview

import UIKit
import CoreLocation // current location
import os.log

class MapListTableViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var msgLabel: UILabel!
    @IBOutlet weak var addBtn: UIBarButtonItem!
    
    //MARK: Properties
    private var sortBy = "name" // user selected sort method
    private var importing = false
    private var showMap = false
    private var importFileName:String = ""
    private var currentMapName:String = ""
    private var documentsURL:URL? = nil
    private var latNow:Double = 0.0
    private var longNow:Double = 0.0
    private var progress:Float = 0.0
    var locationManager = CLLocationManager()
    
    // MARK: - Data source
    var maps = [PDFMap]()
    
    // more drop down menu
    var moreBtn:UIBarButtonItem!
    let moreMenuTransparentView = UIView();
    let moreMenuTableview = UITableView();
    var dataSource = [String]()
    let sortByLabels = ["Name        ","Date          ","Size           ", "Proximity  "]
    let upArrow = "\u{2E0D}\u{2E0C}"
    let downArrow = "\u{2E0C}\u{2E0D}"
    let checkMark = "\u{2713}"
    let mapListTitle = "Imported Maps"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // populate more drop down menu for sorting
        let selectedSort = checkMark + " " + sortByLabels[0] + downArrow
        let sp = "    "
        dataSource = [selectedSort,sp + sortByLabels[1], sp + sortByLabels[2], sp + sortByLabels[3]]
        moreMenuTableview.delegate = self
        moreMenuTableview.dataSource = self
        moreMenuTableview.register(CellClass.self, forCellReuseIdentifier: "Cell")
        
        // get path to documents/app directory
        documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if (documentsURL == nil) {
           displayError(theError: AppError.pdfMapError.invalidDocumentDirectory, title: "Fatal Error")
           return
        } else {
        
            // This does not allow clicking on a cell to show map!!!!!
            //self.tableView.isEditing = true // shows delete & rearange buttons in each row
            
            // Uncomment the following line to preserve selection between presentations
            // self.clearsSelectionOnViewWillAppear = false

            // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
            self.navigationItem.leftBarButtonItem = self.editButtonItem
            
            moreBtn = UIBarButtonItem(image: (UIImage(named: "more")), style: .plain, target: self, action: #selector(onClickMore))
            
            self.navigationItem.rightBarButtonItems = [moreBtn, addBtn]
            
            // load maps
            if let savedMaps = loadMaps() {
                maps += savedMaps
            }
            else {
                maps = []
            }
            showMsg() // if no maps imported
            
            // sort list
            sortList(type: sortBy)
            
            // start location services to calc. distance to map or on map
            setupLocationServices()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if importing {
            // AddMapsViewController returned to unwindToMapsList function
            importing = false
            importMap()
        }
        // if done importing and returned from displaying the map, now show the list
        else if showMap {
            showMap = false
            // sort table by user preference
            sortList(type: sortBy) // reloads the data too!
            scrollToCurrentMapName()
        }
        // returned from displaying map
        else {
            // way points could have changed. Reload maps database
            maps = loadMaps() ?? []
            // calculate distance to each map
            if (maps.count > 0){
                for i in 0...maps.count-1 {
                    maps[i].mapDist = getDistToMap(map: maps[i])
                    //print(maps[i].displayName)
                }
                sortList(type: sortBy) // reloads the data too!
            }
            showMsg() // if no imported maps
        }
    }
    
    // MARK: Actions
    
    @IBAction func unwindToMapsList(sender: UIStoryboardSegue){
        // MARK: unwindToMapsList
        // Called from AddMapsViewController when user selects a file from file picker or downloads from a website.
        // Import new map
        //if let sourceViewController = sender.source as? AddMapsViewController, let map = sourceViewController.map {
        // Show cell with progress bar as loads
        if let sourceViewController = sender.source as? AddMapsViewController, let theFileName = sourceViewController.fileName,
            let fileURL = sourceViewController.fileURL {
            // Make sure file exists and just set displayname to Loading...
            do {
                let map = try PDFMap(fileName: theFileName, fileURL: fileURL, quick: true)
                if (map != nil){
                    maps += [map!]
                    progress = 0.4
                    //print ("unwind total rows: \(maps.count)")
                    self.tableView.reloadData()
                    scrollToBottom()
                    importing = true
                    importFileName = theFileName
                    showMsg() // hide no maps message
                } else {
                    displayError(theError: AppError.pdfMapError.mapNil)
                }
            } catch {
                displayError(theError: error)
            }
        }
    }
    
    // MARK: Private Methods
    
    private func displayError(theError: Error, title: String="Map Import Failed") {
         // MARK: displayError
         var msg:String
         switch theError {
         case AppError.pdfMapError.invalidDocumentDirectory:
             msg = "Cannot read from or write to the app documents directory. Your imported maps are stored here."
         case AppError.pdfMapError.invalidFilename:
             msg = "Invalid Filename."
         case AppError.pdfMapError.notPDF:
             msg = "Map file must be a PDF file."
         case AppError.pdfMapError.pdfFileNotFound(let file):
             msg = "Map file not found.\n\n\(file)"
         case AppError.pdfMapError.mapNil:
             msg = "Could not create map object, returned nil."
         case AppError.pdfMapError.cannotOpenPDF:
             msg = "Cannot read the map file."
         case AppError.pdfMapError.cannotReadPDFDictionary:
             msg = "Map file may not be geo referrenced or it is in an unknown format. Cannot read the spatial referrence data."
         case AppError.pdfMapError.pdfVersionTooLow:
             msg = "Map file is not geo referrenced."
         case AppError.pdfMapError.unknownFormat:
             msg = "Map file may not be geo referrenced or it is in an unknown format."
         case AppError.pdfMapError.cannotDelete:
             msg = "Cannot delete the map file."
         case AppError.pdfMapError.cannotRename(let file):
             msg = "Error trying to rename the file. \n\n\(file)"
         case AppError.pdfMapError.fileAlreadyExists(let file):
             msg = "The destination file already exists.\n\n\(file)"
         case AppError.pdfMapError.mapNameBlank:
             msg = "Map name cannot be blank."
         case AppError.pdfMapError.mapNameDuplicate:
             msg = "Map name already exists."
         case AppError.pdfMapError.diskFull:
             msg = "Local disk is full. Remove some pictures, data, or apps."
         case AppError.pdfMapError.cannotSelectRow:
             msg = "Table was in the process of loading, cannot show the map."
         case AppError.pdfMapError.mapSaveFail:
            msg = "Failed to save maps."
         default:
             msg = "Unknow error occured."
         }
         let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
         self.present(alert, animated: true)
         return
     }
    
    private func importMap(){
        // MARK: importMap
        // Import a map and show progress bar. Called by unwindToMapsList

        //
        // MARK: TODO progress
        //--- have PDFMap send progress percent and update progressView
        
        // get the row that was just added
        let map = maps[maps.count-1] // mapName of Loading...
        
        do {
            // Copy the pdf to the app documents directory, parse the pdf for lat/long, and store info in a database
            let map2 = try PDFMap(fileURL: map.fileURL!) // import map
            maps[maps.count-1] = map2!
            saveMaps() // save in NSCoding (database)
            showMap = true
            currentMapName = map2!.displayName
            // when the table reloads it will display the map in didEndDisplaying cell
            progress = 0.9
            self.tableView.reloadData()
            scrollToBottom()
            
            // show the map
            /*
             let indexPath = IndexPath(row: maps.count-1, section: 0)
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.bottom)
            self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: indexPath)*/
        } catch {
            displayError(theError: error)
            maps.remove(at: maps.count-1)
            var indexPath:IndexPath
            // if the cell is visible, delete it
            let cells = self.tableView.visibleCells as! Array<MapListTableViewCell>
            for cell in cells {
                if cell.loadingProgress.isHidden == false {
                    if self.tableView.indexPath(for: cell) != nil {
                        indexPath = self.tableView.indexPath(for: cell)!
                        // Delete the row from the data source
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        break
                    }
                }
            }
            showMsg()
            return
        }
    }
    
    private func saveMaps() {
        // Archive the maps array
        if #available (iOS 12.0,*){
            //'archiveRootObject(_:toFile:)' was deprecated in iOS 12.0: Use +archivedDataWithRootObject:requiringSecureCoding:error: and -writeToURL:options:error: instead
            do {
                let dataToBeArchived = try NSKeyedArchiver.archivedData(withRootObject: maps, requiringSecureCoding: false)
                try dataToBeArchived.write(to: PDFMap.ArchiveURL)
                //os_log("Maps successfully saved.", log: OSLog.default, type: .debug)
            } catch {
                displayError(theError: AppError.pdfMapError.mapSaveFail)
            }
        }
        else{
            let isSuccessfullSave = NSKeyedArchiver.archiveRootObject(maps, toFile: PDFMap.ArchiveURL.path)
            if isSuccessfullSave {
                //os_log("Maps successfully saved.", log: OSLog.default, type: .debug)
            }
            else {
                os_log("Failed to save maps.", log: OSLog.default, type: .error)
                displayError(theError: AppError.pdfMapError.mapSaveFail)
            }
        }
    }
    
    private func loadMaps() -> [PDFMap]? {
        // MARK: loadMaps
        
        // Read data from local storage NSCoding
        // Return array of maps or nil
        if #available (iOS 12.0,*){
            if let archivedData = try? Data(contentsOf: PDFMap.ArchiveURL),
               let myObject = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedData)) as? [PDFMap] {
                return myObject
            }
            else {
                return nil
            }
        }else {
            return NSKeyedUnarchiver.unarchiveObject(withFile: PDFMap.ArchiveURL.path) as? [PDFMap]
        }
        
        
        
        // old - read all pdfs in directory
        
        // Load all PDF files found in the local documents directory. PDFMap gets the file modification
        // date and parses the file for thumbnail. When the map is loaded in MapViewController,
        // it calls PDFParser to get lat/long bounds, mediabox, and viewport
        
        // get pdf files in app documents directory
        /*var dirContents: [URL]? = nil
        do {
            dirContents = try FileManager.default.contentsOfDirectory(at: documentsURL!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        }catch {
            displayError(theError: AppError.pdfMapError.invalidDocumentDirectory)
            return nil
        }
          
        if dirContents != nil {
            // only load pdf files
            let pdfFiles = dirContents!.filter{ $0.pathExtension == "pdf" }
            
            // load pdf files into maps array
            for pdf in pdfFiles.enumerated() {
                do {
                    let map = try PDFMap(fileName:
                    pdf.element.lastPathComponent)
                    if map != nil {
                        maps += [map!]
                    }
                } catch {
                    displayError(theError: error)
                }
            }
        }
        showMsg()
        return maps*/
    }
    
    // MARK: Location funcs
    
    func setupLocationServices() {
        // MARK: setupLocationServices
        // Check for location permission. Display button if permission is needed. Start updating
        // user location.
        locationManager.desiredAccuracy=kCLLocationAccuracyBest
        let status = CLLocationManager.authorizationStatus()
        //print("location status ",status)
        switch status {
        case .notDetermined:
            // display location permissions request
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
            self.updateLocation() // initial
            // update location every 2 seconds
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                self.updateLocation()
            }
            
        case .denied, .restricted:
            let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable Location Services in Settings, Privacy, Location Services.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            self.updateLocation() // initial
            // update location every 2 seconds
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                self.updateLocation()
            }
            
        default:
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            self.updateLocation()
            // update location every 2 seconds
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                self.updateLocation()
            }
        }
    }

    // get current location
    func updateLocation() {
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
           CLLocationManager.authorizationStatus() == .authorizedAlways) {
            guard let currentLoc = locationManager.location else {
                latNow = 0.0
                longNow = 0.0
                return
            }
            var needRefresh:Bool = false
            if (latNow == 0.0) {
                needRefresh = true
            }
            latNow = currentLoc.coordinate.latitude
            longNow = currentLoc.coordinate.longitude
            if needRefresh {
                self.tableView.reloadData()
            }
        }
    }
    
    func  distance_on_unit_sphere(lat1: Double, long1:Double, lat2:Double, long2:Double) -> Double {

       // Convert latitude and longitude to
       // spherical coordinates in radians.
        let degrees_to_radians:Double = Double.pi/180.0

       // phi = 90 - latitude
       let phi1 = (90.0 - lat1)*degrees_to_radians
       let phi2 = (90.0 - lat2)*degrees_to_radians

       // theta = longitude
       let theta1 = long1*degrees_to_radians
       let theta2 = long2*degrees_to_radians

       // Compute spherical distance from spherical coordinates.

       // For two locations in spherical coordinates
       // (1, theta, phi) and (1, theta, phi)
       // cosine( arc length ) =
       //    sin phi sin phi' cos(theta-theta') + cos phi cos phi'
       // distance = rho * arc length

       let cosine = (sin(phi1) * sin(phi2) * cos(theta1 - theta2) + cos(phi1) * cos(phi2))
       let arc = acos( cosine )

       // Remember to multiply arc by the radius of the earth
       // in your favorite set of units to get length.
       return arc * 3963 // 3,962 is the radius of earth in miles
    }
    
    func showMsg() {
        // MARK: showMsg no maps
        // if there are no imported maps, show a message to add some
        if (maps.count == 0) {
            var newFrame: CGRect = msgLabel.frame
            newFrame.size.height = 80
            msgLabel.frame = newFrame
            msgLabel.isHidden = false
            self.editButtonItem.isEnabled = false
            setEditing(false, animated: true)
        }
        else {
            var newFrame: CGRect = msgLabel.frame
            newFrame.size.height = 0
            msgLabel.frame = newFrame
            msgLabel.isHidden = true
            self.editButtonItem.isEnabled = true
            setEditing(false, animated: true)
        }
    }
    
    
    // MARK: More Menu
    func addMoreMenuTransparentView(frames:CGRect){
        let window = UIApplication.shared.keyWindow
        let y:Int = Int(self.navigationController?.navigationBar.frame.maxY ?? 0) + Int(self.tableView.contentOffset.y)
        moreMenuTransparentView.frame = window?.frame ?? self.view.frame
        moreMenuTransparentView.frame.origin.y = CGFloat(y) //+= self.tableView.contentOffset.y + 60
        self.view.addSubview(moreMenuTransparentView)
        
        //moreMenuTableview.frame = CGRect(x: frames.origin.x, y: self.tableView.contentOffset.y + 60.0, width: frames.width, height: 0)
        self.view.addSubview(moreMenuTableview)
        moreMenuTableview.layer.cornerRadius = 5
        self.title = "Sort By"
        
        moreMenuTransparentView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        moreMenuTableview.reloadData()
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(removeMoreMenuTransparentView))
        moreMenuTransparentView.addGestureRecognizer(tapgesture)
        moreMenuTransparentView.alpha = 0
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.moreMenuTransparentView.alpha = 0.5
            self.moreMenuTableview.frame = CGRect(x: 0, y: y, width: Int(frames.width), height: self.dataSource.count * 50)
        }, completion: nil)
        moreBtn.isEnabled = false // gray out ... button
    }
    @objc func removeMoreMenuTransparentView(){
        self.title = mapListTitle
        let frames = self.view.frame
        // remove more button drop down menu view
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.moreMenuTransparentView.alpha = 0.0
            self.moreMenuTableview.frame = CGRect(x: frames.origin.x, y: self.tableView.contentOffset.y + 60, width: frames.width, height: 0)
        }, completion: nil)
        moreBtn.isEnabled = true
    }

    @objc func onClickMore(_ sender:Any){
        addMoreMenuTransparentView(frames: self.view.frame)
    }
    func sortList(type: String = "name"){
        // MARK: sortList
        //print("sorting by \(type)")
        switch type {
        // by file imported date, newest first
        case "date":
            maps = maps.sorted(by: {
                $0.modDate > $1.modDate
            })
        // by file imported date, newest last
        case "reverseDate":
            maps = maps.sorted(by: {
                $0.modDate < $1.modDate
            })
        // by filename a-z
        case "name":
            maps = maps.sorted(by: {
                $0.fileName.lowercased() < $1.fileName.lowercased()
            })
        // by filename z-a
        case "namereverse":
            maps = maps.sorted(by:{
                $0.fileName.lowercased() > $1.fileName.lowercased()
            })
        // file size ## MB or ## KB    0KB-100MB
        case "size":
            maps = maps.sorted(by:{
                var a:Int?
                var b:Int?
                let aArr = $0.fileSize.split(separator: " ")
                let bArr = $1.fileSize.split(separator: " ")
                if ($0.fileSize.lowercased().contains("mb")) {
                    a = Int(aArr[0])
                    if (a != nil){
                        a = a! * 1000
                    }
                    else{
                        return false
                    }
                }
                else {
                    a = Int(aArr[0])
                    if (a != nil){
                        a = a!
                    }
                    else{
                        // error no filesize
                        return false
                    }
                }
                if ($1.fileSize.lowercased().contains("mb")) {
                    b = Int(bArr[0])
                    if (b != nil){
                        b = b! * 1000
                    }
                    else {
                        return false
                    }
                }
                else {
                    b = Int(bArr[0])
                    if (b != nil){
                        b = b!
                    }
                    else{
                        // error no filesize
                        return false
                    }
                }
                return a! < b!
            })
        // file size ## MB or ## KB  100MB-0KB
        case "sizereverse":
            maps = maps.sorted(by:{
                var a:Int?
                var b:Int?
                let aArr = $0.fileSize.split(separator: " ")
                let bArr = $1.fileSize.split(separator: " ")
                if ($0.fileSize.lowercased().contains("mb")) {
                    a = Int(aArr[0])
                    if (a != nil){
                        a = a! * 1000
                    }
                    else{
                        return false
                    }
                }
                else {
                    a = Int(aArr[0])
                    if (a != nil){
                        a = a!
                    }
                    else{
                        // error no filesize
                        return false
                    }
                }
                if ($1.fileSize.lowercased().contains("mb")) {
                    b = Int(bArr[0])
                    if (b != nil){
                        b = b! * 1000
                    }
                    else {
                        return false
                    }
                }
                else {
                    b = Int(bArr[0])
                    if (b != nil){
                        b = b!
                    }
                    else{
                        // error no filesize
                        return false
                    }
                }
                return a! > b!
            })
            
        // proximity ## mi SW or icon 0 - 100mi etc
        case "proximity":
            maps = maps.sorted(by:{
                var a:Float?
                var b:Float?
                let aArr = $0.mapDist.split(separator: " ")
                let bArr = $1.mapDist.split(separator: " ")
                if ($0.mapDist.lowercased().contains("mi")) {
                    a = Float(aArr[0])
                    if (a != nil){
                        a = a!
                    }
                    else{
                        return false
                    }
                }
                else {
                    a = 0
                }
                if ($1.mapDist.lowercased().contains("mi")) {
                    b = Float(bArr[0])
                    if (b != nil){
                        b = b!
                    }
                    else {
                        return false
                    }
                }
                else {
                    b = 0
                }
                // check if current location is on the map
                // make it negative so it is smaller than other maps that are the same distance away
                // but not on the map. Subtract from 1000 and make it negaive so it keeps the proper order
                if (latNow >= $1.lat1 && latNow <= $1.lat2 && longNow >= $1.long1 && longNow <= $1.long2) {
                    b = (1000 - b!) * -1
                }
                if (latNow >= $0.lat1 && latNow <= $0.lat2 && longNow >= $0.long1 && longNow <= $0.long2) {
                    a = (1000 - a!) * -1
                }
                return a! < b!
            })
            
        // proximity ## mi SW or icon 100mi - 0mi etc
        case "proximityreverse":
            maps = maps.sorted(by:{
                var a:Float?
                var b:Float?
                let aArr = $0.mapDist.split(separator: " ")
                let bArr = $1.mapDist.split(separator: " ")
                if ($0.mapDist.lowercased().contains("mi")) {
                    a = Float(aArr[0])
                    if (a != nil){
                        a = a!
                    }
                    else{
                        return false
                    }
                }
                else {
                    a = 0
                }
                if ($1.mapDist.lowercased().contains("mi")) {
                    b = Float(bArr[0])
                    if (b != nil){
                        b = b!
                    }
                    else {
                        return false
                    }
                }
                else {
                    b = 0
                }
                // check if current location is on the map
                // make it negative so it is smaller than other maps that are the same distance away
                // but not on the map. Subtract from 1000 and make it negaive so it keeps the proper order
                if (latNow >= $1.lat1 && latNow <= $1.lat2 && longNow >= $1.long1 && longNow <= $1.long2) {
                    b = (1000 - b!) * -1
                }
                if (latNow >= $0.lat1 && latNow <= $0.lat2 && longNow >= $0.long1 && longNow <= $0.long2) {
                    a = (1000 - a!) * -1
                }
                return a! > b!
            })
            
        // by file name a-z
        default:
            maps = maps.sorted(by:{
                $0.fileName.lowercased() < $1.fileName.lowercased()
            })
        }
        self.tableView.reloadData()
        sortBy = type
    }
    
    
    // Set visible cells to enable editing of map name and allow deleting
    override func setEditing(_ editing: Bool, animated: Bool) {
        // show delete button, map name editable
        // MARK: setEditing
        super.setEditing(editing, animated: animated)
        let cells = self.tableView.visibleCells as! Array<MapListTableViewCell>
        if (editing) {
            // Edit button pushed. Highlight map name text box and make editable.
            tableView.isScrollEnabled = false
            addBtn.isEnabled = false
            moreBtn.isEnabled = false
            for cell in cells {
                cell.mapName.isEnabled = true // editable
                cell.mapName.delegate = self
                cell.mapName.addTarget(self, action: #selector(self.saveCurrentMapName(_:)), for: UIControl.Event.editingDidBegin)
                cell.mapName.addTarget(self, action: #selector(self.endEditingMapName(_:)), for: UIControl.Event.editingDidEnd)
                cell.mapName.backgroundColor = .init(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
                cell.mapName.borderStyle = UITextField.BorderStyle.roundedRect
            }
        }
        else if (importing){
            return
        }
        else {
            // Done button pushed. Update all map names. Set map name text boxes to un-editable
            tableView.isScrollEnabled = true
            addBtn.isEnabled = true
            moreBtn.isEnabled = true
            for cell in cells {
                cell.mapName.isEnabled = false
                cell.mapName.backgroundColor = .white
                cell.mapName.borderStyle = UITextField.BorderStyle.none
                // search for cell where map name has changed and filenames match. Filename must be unique.
                for i in 0...maps.count-1 {
                    if (maps[i].fileName == cell.fileName.text &&
                        cell.mapName.text != nil &&
                        maps[i].displayName != cell.mapName.text){
                        // save new display name, filename, and URL
                        maps[i].displayName = cell.mapName.text!
                        maps[i].fileName = cell.mapName.text! + ".pdf"
                        cell.fileName.text = maps[i].fileName
                        maps[i].fileURL = documentsURL!.appendingPathComponent(cell.fileName.text!)
                    }
                }
            }
            saveMaps()
            self.tableView.reloadData()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // MARK: hide keyboard
        // hide keyboard on enter key pressed
        self.view.endEditing(true)
        textField.resignFirstResponder() // hide keyboard
        setEditing(true, animated: true) // refresh list of currently viewed cells with mapName textField editable
        return true
    }
    @objc func endEditingMapName(_ textField: UITextField){
        // MARK: endEditing
        // enter key clicked in mapName text field
        let mapName:String = textField.text ?? "" // if nil set to blank
        // no change, return
        if (mapName == currentMapName){
            return
        }
        // blank map name, reset and return
        if (mapName == "") {
            textField.text = currentMapName // reset map Name if blank
             displayError(theError: AppError.pdfMapError.mapNameBlank, title: "Invalid Map Name")
             return
        }
        // Make sure this name is unique
        var count = 0
        for  i in 0...maps.count-1 {
            if (mapName.lowercased() == maps[i].displayName.lowercased()) {
                count += 1
            }
        }
        // Multiple same names found, reset and return
        if (count > 0){
            textField.text = currentMapName // reset map Name if already exists
            displayError(theError: AppError.pdfMapError.mapNameDuplicate, title: "Invalid Map Name")
            return
        }
        // remove .pdf from the end of map name
        if (mapName.suffix(4) == ".pdf") {
            let start = mapName.startIndex
            let end = mapName.index(mapName.endIndex, offsetBy: -4)
            let range = start..<end
            textField.text = String(mapName[range])
         }
        // rename file
        let sourceURL = documentsURL!.appendingPathComponent(currentMapName + ".pdf")
        let destURL = documentsURL!.appendingPathComponent(textField.text! + ".pdf")
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: sourceURL.path){
            if !fileManager.fileExists(atPath: destURL.path) {
               // rename file
                do {
                    try fileManager.moveItem(at: sourceURL, to: destURL)
                    //("\(sourceURL.lastPathComponent) renamed to \(destURL.lastPathComponent)")
                } catch {
                    displayError(theError: AppError.pdfMapError.cannotRename(file: destURL.path), title: "Cannot Rename Map File")
                    textField.text = currentMapName // reset map name
                    return
                }
            } else {
                // destination file already exists
                displayError(theError: AppError.pdfMapError.fileAlreadyExists(file: textField.text! + ".pdf"), title: "Cannot Rename File")
                textField.text = currentMapName // reset map name
                return
            }
        } else {
            // source file does not exist!!!
            displayError(theError: AppError.pdfMapError.pdfFileNotFound(file: currentMapName + ".pdf"), title: "Cannot Rename File")
            textField.text = currentMapName // reset map name
            return
        }
        setEditing(true, animated: true) // refresh list of currently viewed cells with mapName textField editable
    }
    @objc func saveCurrentMapName(_ mapName: UITextField){
        // Save old map name in case they change it to one that already exists.
        currentMapName = mapName.text ?? ""
        //print ("current Map Name = \(currentMapName)")
    }
    
    func scrollToBottom(){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.maps.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    func scrollToCurrentMapName(){
        DispatchQueue.main.async {
            var indexPath:IndexPath
            for i in 0...self.maps.count-1 {
                if self.maps[i].displayName == self.currentMapName {
                    indexPath = IndexPath(row: i, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    break
                }
            }
        }
    }

    //
    // MARK: Get Distance to Map
    //
    func getDistToMap(map:PDFMap) -> String {
        var dist:Double = 0.0
        var direction = ""
        if latNow > map.lat1 {
            direction = "S"
        }
        else if latNow  > map.lat2 {
            direction = ""
        }
        else {
            direction = "N"
        }
        if longNow < map.long1 {
            direction += "E"
        }
        else if longNow > map.long2 {
            direction += "W"
        }

        switch direction {
        case "S":
            dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat2, long2: longNow)
        case "N":
            dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat1, long2: longNow)
        case "E":
            dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: latNow, long2: map.long2)
        case "W":
            dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: latNow, long2: map.long1)
        case "SE":
            dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat2, long2: map.long2)
        case "SW":
           dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat1, long2: map.long2)
        case "NE":
            dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat2, long2: map.long1)
        case "NW":
            dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat1, long2: map.long1)
        default:
            dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat1, long2: map.long1)
        }
        let distStr = String(format: "%.1f", dist)
        return "\(distStr) mi. \(direction)"
    }
    
    //
    // MARK: Table Functions
    //
    override func numberOfSections(in tableView: UITableView) -> Int {
           // return the number of sections
           return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows
        if tableView == self.moreMenuTableview {
            return dataSource.count
        } else {
            return maps.count
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.moreMenuTableview {
            return 50
        }
        else {
            return tableView.rowHeight
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // MARK: cellForRowAt
        
        if tableView == self.moreMenuTableview {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = dataSource[indexPath.row]
            return cell
        }
        else {
            // update the table with distance to map
            let cellIdentifier = "MapListTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MapListTableViewCell else {
                fatalError("The dequeued cell is not an instance of MapListTableViewCell.")
            }
        
            // Fetches the appropriate map for the data source layout.
            let map = maps[indexPath.row]
            // reset map name editing to done. Sometimes if scroll it is still in editing mode grey textbox
            cell.mapName.isEnabled = false
            cell.mapName.backgroundColor = .white
            cell.mapName.borderStyle = UITextField.BorderStyle.none
            
            // show progress bar
            if (map.displayName == "Loading..."){//cell.mapName.text == "Loading..." && map.displayName == "Loading...") {
                // scroll to cell that was just loaded after importing the map
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                cell.loadingProgress.isHidden = false
                cell.mapName.text = "Loading..."
                cell.pdfImage.image = map.getThumbnail()
                cell.fileSize.text = "File size..."
                cell.distToMap.text = "Miles to map..."
                cell.locationIcon.isHidden = true
                cell.loadingProgress.setProgress(progress, animated: true)
                return cell

                
            } else {
                cell.loadingProgress.isHidden = true
            }
            
            cell.fileSize.text = map.fileSize
            // distance to map
            if latNow == 0.0 {
                cell.distToMap.text = "Miles to map..."
            }
            // on map, show location icon
            else if (latNow >= map.lat1 && latNow <= map.lat2 && longNow >= map.long1 && longNow <= map.long2) {
                cell.distToMap.text = ""
                cell.locationIcon.isHidden = false
            }
            // off map show distance to map
            else {
                cell.locationIcon.isHidden = true
                var dist:Double = 0.0
                var direction = ""
                if latNow > map.lat1 {
                    direction = "S"
                }
                else if latNow  > map.lat2 {
                    direction = ""
                }
                else {
                    direction = "N"
                }
                if longNow < map.long1 {
                    direction += "E"
                }
                else if longNow > map.long2 {
                    direction += "W"
                }

                switch direction {
                case "S":
                    dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat2, long2: longNow)
                case "N":
                    dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat1, long2: longNow)
                case "E":
                    dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: latNow, long2: map.long2)
                case "W":
                    dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: latNow, long2: map.long1)
                case "SE":
                    dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat2, long2: map.long2)
                case "SW":
                   dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat1, long2: map.long2)
                case "NE":
                    dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat2, long2: map.long1)
                case "NW":
                    dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat1, long2: map.long1)
                default:
                    dist = distance_on_unit_sphere(lat1: latNow, long1: longNow, lat2: map.lat1, long2: map.long1)
                }
                
                let distStr = String(format: "%.1f", dist)
                cell.distToMap.text = "\(distStr) mi. \(direction)"
                map.mapDist = cell.distToMap.text!
            }
            
            
            //print ("row:\(indexPath.row)  \(cell.mapName.text!)  \(map.displayName)")
            
            cell.mapName.text = map.displayName
            cell.fileName.text = map.fileName
            cell.mapName.placeholder = "Map Name"
            cell.pdfImage.image = map.thumbnail
           //print("\(map.displayName) \(map.modDate)")
            
            return cell
        }
    }
    
    func sortByDataUpdate(arrow:String, index:Int){
        for i in 0...self.dataSource.count-1 {
            if (i == index){
                self.dataSource[i] = checkMark + " " + sortByLabels[i] + arrow
            }
            else {
                self.dataSource[i] = "    " + sortByLabels[i]
            }
        }
    }
    
    // Used to show the map after importing a new map
    // Not called while in edit mode
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // MARK: didSelectRowAt
        // Cell clicked on
        
        // Sort Table By Chosen Row
        if (tableView == self.moreMenuTableview){
            guard let cell = tableView.cellForRow(at: indexPath) else {
                displayError(theError: AppError.pdfMapError.cannotSelectRow)
                return
            }
            var reverse = false
            let label = cell.textLabel?.text
            if (label!.contains(upArrow)){
                //display A-Z, old-new, small-big
                reverse = false
                sortByDataUpdate(arrow:downArrow, index:indexPath.row)
                //dataSource[indexPath.row] = self.sortByLabels[indexPath.row] + downArrow
                //cell.textLabel?.text = dataSource[indexPath.row]
                self.moreMenuTableview.reloadData()
            }
            else if (label!.contains(downArrow)){
                // display Z-A, new-old, big-small
                reverse = true
                sortByDataUpdate(arrow:upArrow, index:indexPath.row)
                //dataSource[indexPath.row] = self.sortByLabels[indexPath.row] + upArrow
                //cell.textLabel?.text = dataSource[indexPath.row]
                self.moreMenuTableview.reloadData()
            }
            else {
                // display A-Z, old-new, small-big
                reverse = false
                sortByDataUpdate(arrow:downArrow, index:indexPath.row)
            }
            
            if (dataSource[indexPath.row].contains("Name")){
                if (reverse){
                    sortList(type: "namereverse")
                } else {
                    sortList(type: "name")
                }
            }
            else if (dataSource[indexPath.row].contains("Date")){
                if (reverse){
                    sortList(type: "datereverse")
                } else {
                    sortList(type: "date")
                }
            }
            else if (dataSource[indexPath.row].contains("Size")){
                if (reverse){
                    sortList(type: "sizereverse")
                } else {
                    sortList(type: "size")
                }
            }
            else if (dataSource[indexPath.row].contains("Proximity")){
                if (reverse){
                    sortList(type: "proximityreverse")
                } else {
                    sortList(type: "proximity")
                }
            }
            removeMoreMenuTransparentView() // hide drop down menu
        }
        
        // MapListTableView row selected
        else {
        /*let cellIdentifier = "MapListTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MapListTableViewCell else {
            fatalError("The dequeued cell is not an instance of MapListTableViewCell.")
        }*/
        guard let cell = self.tableView.cellForRow(at: indexPath) as? MapListTableViewCell else {
            showMap = false
            displayError(theError: AppError.pdfMapError.cannotSelectRow)
            return
        }
        if (showMap) {
            // when user returns to list it sets showMap to false in viewDidAppear
            tableView.deselectRow(at: indexPath, animated: true)
            // causes error, self.tableView.reloadData()
            performSegue(withIdentifier: "ShowMap", sender: cell)
        }
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // MARK: didEndDisplaying cell
        if (showMap){
            //print("end displaying row \(indexPath.row)")
            if let lastVisibleIndexPath = tableView.indexPathsForVisibleRows?.last {
                if indexPath == lastVisibleIndexPath {
                    // If just imported a map programmatically select row and show map
                    // Performs segue in didSelectRowAt
                    // select the row which calls didSelectRow which will show the map
                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.bottom)
                    self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: indexPath)
                }
            }
        }
    }
    
    // Override to support conditional editing of the table view.
    // if return true allows deleting a row
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    /*
    override func tableView(_ tableView: UITableView,
                            willBeginEditingRowAt indexPath: IndexPath) {
        super.tableView(tableView, willBeginEditingRowAt: indexPath)
        //print ("willBeginEditingRowAt")
    }
    
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        super.tableView(tableView, didEndEditingRowAt: indexPath)
        // Call when user presses delete button??????????
        print("didEndEditingRowAt")
    }
 */
    
    // Swipe left to delete
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // MARK: Delete Row
        // Swipe left for delete button to appear
        if editingStyle == .delete {
            // Delete file from app/documents...
            let cell = self.tableView.cellForRow(at: indexPath) as! MapListTableViewCell
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                displayError(theError: AppError.pdfMapError.invalidDocumentDirectory)
                return
            }
            guard let mapName = cell.mapName.text  else {
                displayError(theError: AppError.pdfMapError.invalidFilename)
                return
            }
            let fileURL = documentsURL.appendingPathComponent(mapName + ".pdf")
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                displayError(theError: AppError.pdfMapError.cannotDelete, title: "Error Deleting File.")
            }
            maps.remove(at: indexPath.row)
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            if self.tableView.isEditing {
                // refresh list of currently viewed cells with mapName textField editable
                setEditing(true, animated: true)
                self.navigationItem.leftBarButtonItem!.title = "Done"
            }
            saveMaps()
            if (maps.count == 0) {
                showMsg() // if deleted last row, show message to add maps press + button
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            //print("insert...")
        }    
    }
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = self.maps[fromIndexPath.row]
        maps.remove(at: fromIndexPath.row)
        maps.insert(movedObject, at: destinationIndexPath.row)
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch(segue.identifier ?? "") {
        case "AddMap":
            print("Adding a map.")
        case "ShowMap":
            guard let mapViewController = segue.destination as? MapViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedMapCell = sender as? MapListTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            guard let indexPath = tableView.indexPath(for: selectedMapCell) else {
                fatalError("The selected cell is not being displayed by the table.")
            }
            // pass the selected map name, thumbnail, etc to MapViewController.swift
            //let selectedMap = maps[indexPath.row]
            //mapViewController.map = selectedMap
            mapViewController.maps = maps
            mapViewController.mapIndex = indexPath.row
        default:
            fatalError("Unexpected Segue Identifier: \(String(describing: segue.identifier))")
        }
    }
}
