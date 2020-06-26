//
//  MapListTableViewController.swift
//  MapViewer
//
//  Created by Tammy Bearly on 4/15/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//
//
// From: https://developer.apple.com/library/archive/referencelibrary/GettingStarted/DevelopiOSAppsSwift/CreateATableView.html
//
// long press on a table row https://stackoverflow.com/questions/3924446/long-press-on-uitableview

import UIKit
import CoreLocation // current location

class MapListTableViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var msgLabel: UILabel!
    @IBOutlet weak var addBtn: UIBarButtonItem!
    
    private var sortBy = "name" // user selected sort method
    private var importing = false
    private var showMap = false
    private var importFileName:String = ""
    private var currentMapName:String = ""
    private var documentsURL:URL? = nil
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get path to documents/app directory
        documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if (documentsURL == nil) {
           displayError(theError: AppError.pdfMapError.invalidDocumentDirectory, title: "Fatal Error")
           return
        } else {
        
            // This does not allow clicking on a cell to show map!!!!!
            //self.tableView.isEditing = true // shows delete & rearange buttons in each row
            
            // load maps
            loadMaps()
            
            // sort list
            sortList(type: sortBy)
            
            // Uncomment the following line to preserve selection between presentations
            // self.clearsSelectionOnViewWillAppear = false

            // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
            self.navigationItem.leftBarButtonItem = self.editButtonItem
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
            sortList(type: sortBy)
            self.tableView.reloadData()
            scrollToCurrentMapName()
        }
        else {
            sortList(type: sortBy)
            self.tableView.reloadData()
            showMsg() // if no imported maps
        }
    }

   
    // MARK: - Data source
    var maps = [PDFMap]()
    
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
            showMap = true
            currentMapName = map2!.displayName
            // when the table reloads it will display the map in didEndDisplaying cell
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
            let cells = self.tableView.visibleCells as! Array<MapListTableViewCell>
            for cell in cells {
                if cell.fileName.text == "Loading..." {
                    if self.tableView.indexPath(for: cell) != nil {
                        indexPath = self.tableView.indexPath(for: cell)!
                        // Delete the row from the data source
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        break
                    }
                }
            }
            return
        }
    }
    
    private func loadMaps() {
        // MARK: loadMaps
        // Load all PDF files found in the local documents directory. PDFMap gets the file modification
        // date and parses the file for thumbnail. When the map is loaded in MapViewController,
        // it calls PDFParser to get lat/long bounds, mediabox, and viewport
        
        // get pdf files in app documents directory
        var dirContents: [URL]? = nil
        do {
            dirContents = try FileManager.default.contentsOfDirectory(at: documentsURL!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        }catch {
            displayError(theError: AppError.pdfMapError.invalidDocumentDirectory)
            return
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
    
    func sortList(type: String = "name"){
        // MARK: sortList
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
        case "reverse":
            maps = maps.sorted(by:{
                $0.fileName.lowercased() > $1.fileName.lowercased()
            })
        // by file name a-z
        default:
            maps = maps.sorted(by:{
                $0.fileName.lowercased() < $1.fileName.lowercased()
            })
        }
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
            for cell in cells {
                cell.mapName.isEnabled = true // editable
                cell.mapName.delegate = self
                cell.mapName.addTarget(self, action: #selector(self.saveCurrentMapName(_:)), for: UIControl.Event.editingDidBegin)
                cell.mapName.addTarget(self, action: #selector(self.endEditingMapName(_:)), for: UIControl.Event.editingDidEnd)
                cell.mapName.backgroundColor = .init(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
                cell.mapName.borderStyle = UITextField.BorderStyle.roundedRect
            }
        }
        else {
            // Done button pushed. Update all map names. Set map name text boxes to un-editable
            tableView.isScrollEnabled = true
            addBtn.isEnabled = true
            for cell in cells {
                cell.mapName.isEnabled = false
                cell.mapName.backgroundColor = .white
                cell.mapName.borderStyle = UITextField.BorderStyle.none
                // search for cell where map name has changed and filenames match. Filename must be unique.
                for i in 0...maps.count-1 {
                    if maps[i].fileName == cell.fileName.text && cell.mapName.text != nil &&
                        maps[i].displayName != cell.mapName.text {
                        // save new display name, filename, and URL
                        maps[i].displayName = cell.mapName.text!
                        maps[i].fileName = cell.mapName.text! + ".pdf"
                        cell.fileName.text = maps[i].fileName
                        maps[i].fileURL = documentsURL!.appendingPathComponent(cell.fileName.text!)
                    }
                }
            }
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
                    //print("\(sourceURL.lastPathComponent) renamed to \(destURL.lastPathComponent)")
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
    // MARK: Table Functions
    //
    override func numberOfSections(in tableView: UITableView) -> Int {
           // return the number of sections
           return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows
        return maps.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // MARK: cellForRowAt
        let cellIdentifier = "MapListTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MapListTableViewCell else {
            fatalError("The dequeued cell is not an instance of MapListTableViewCell.")
        }
        
        // Fetches the appropriate map for the data source layout.
        let map = maps[indexPath.row]
        cell.fileSize.text = map.fileSize
        cell.distToMap.text = map.mapDist
        cell.distToMap.textColor = .red
        cell.mapName.text = map.displayName
        cell.fileName.text = map.fileName
        cell.mapName.placeholder = "Map Name"
        cell.pdfImage.image = map.thumbnail
       //print("\(map.displayName) \(map.modDate)")
        // reset map name editing to done. Sometimes if scroll it is still in editing mode grey textbox
        cell.mapName.isEnabled = false
        cell.mapName.backgroundColor = .white
        cell.mapName.borderStyle = UITextField.BorderStyle.none
        
        // show progress bar
        if (cell.mapName.text == "Loading...") {
            // scroll to cell that was just loaded after importing the map
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            cell.loadingProgress.isHidden = false
        } else {
            cell.loadingProgress.isHidden = true
        }
        return cell
    }
    
    // Used to show the map after importing a new map
    // Not called while in edit mode
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // MARK: didSelectRowAt
        // Cell clicked on
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
            //showMap = false
            // when user returns to list it sets showMap to false in viewDidAppear
            tableView.deselectRow(at: indexPath, animated: true)
            // causes error, self.tableView.reloadData()
            performSegue(withIdentifier: "ShowMap", sender: cell)
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
        print ("willBeginEditingRowAt")
    }
    
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        super.tableView(tableView, didEndEditingRowAt: indexPath)
        // Call when user presses delete button??????????
        print("ddidEndEditingRowAt")
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
            let selectedMap = maps[indexPath.row]
            mapViewController.map = selectedMap
        default:
            fatalError("Unexpected Segue Identifier: \(String(describing: segue.identifier))")
        }
    }
}