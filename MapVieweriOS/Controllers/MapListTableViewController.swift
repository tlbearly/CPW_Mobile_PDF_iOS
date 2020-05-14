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

class MapListTableViewController: UITableViewController {
    //var currentMapName:String?
    private var sortBy = "name" // user selected sort method
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sortList(type: sortBy)
        self.tableView.reloadData()
    }

   
    // MARK: - Table view data source

    
    var maps = [PDFMap]()
    
    // MARK: Actions
    
    @IBAction func unwindToMapsList(sender: UIStoryboardSegue){
        // Called from AddMapsViewController when user selects a file from file picker or downloads from a website.
        if let sourceViewController = sender.source as? AddMapsViewController, let map = sourceViewController.map {
            // Import map
            let newIndexPath = IndexPath(row: maps.count, section: 0)
            
            maps.append(map)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            print("count = \(maps.count)")
        }
    }
    
    // MARK: Private Methods
    
    private func loadMaps() {
        // Load all PDF files found in the local documents directory. PDFMap gets the file modification
        // date and parses the file for thumbnail. When the map is loaded in MapViewController,
        // it calls PDFParser to get lat/long bounds, mediabox, and viewport
        
        // get documents directory
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("documents directory does not exist!")
            return
        }

        //
        // MARK: TODO: ***** replace this with reading from library  *****
        //
        // get pdf files in documents directory
        var dirContents: [URL]? = nil
        do {
            dirContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        }catch {
            print(error)
            return
        }
          
        if dirContents != nil {
            let pdfFiles = dirContents!.filter{ $0.pathExtension == "pdf" }
            
            // load pdf files into maps array
            for pdf in pdfFiles.enumerated() {
                let map = PDFMap(fileName:
                    pdf.element.lastPathComponent)
                if map != nil {
                    maps += [map!]
                }
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        return 1
    }
    
    func sortList(type: String = "name"){
        switch type {
        // by file last modified date
        case "date":
            maps = maps.sorted(by: {
                $0.modDate > $1.modDate
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
        super.setEditing(editing, animated: animated)
        let cells = self.tableView.visibleCells as! Array<MapListTableViewCell>
        if (editing) {
            // Edit button pushed. Highlight map name text box and make editable.
            for cell in cells {
                cell.mapName.isEnabled = true // editable
                cell.mapName.backgroundColor = .init(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
                cell.mapName.borderStyle = UITextField.BorderStyle.roundedRect
            }
        }
        else {
            // Done button pushed. Update all map names. Set map name text boxes to un-editable
            for cell in cells {
                cell.mapName.isEnabled = false
                cell.mapName.backgroundColor = .white
                cell.mapName.borderStyle = UITextField.BorderStyle.none
                // search for cell where filenames match. Filename must be unique.
                for i in 0...maps.count-1 {
                    if maps[i].fileName == cell.fileName.text {
                        maps[i].displayName = cell.mapName.text ?? "Map Name"
                    }
                }
            }
             self.tableView.reloadData()
        }
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows
        return maps.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MapListTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MapListTableViewCell else {
            fatalError("The dequeued cell is not an instance of MapListTableViewCell.")
        }
        
        // Fetches the appropriate map for the data source layout.
        let map = maps[indexPath.row]
        cell.fileSize.text = map.fileSize
        cell.distToMap.text = "10 mi"
        cell.mapName.text = map.displayName
        cell.fileName.text = map.fileName
        cell.mapName.placeholder = "Map Name"
        cell.pdfImage.image = map.thumbnail
        return cell
    }
    
    /*
    // Not called while in edit mode
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Cell clicked on
        let cell = tableView.cellForRow(at: indexPath) as! MapListTableViewCell
    }
    */

    
    // Override to support conditional editing of the table view.
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
        // Swipe left for delete button to appear
        if editingStyle == .delete {
            maps.remove(at: indexPath.row)
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            print("insert...")
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
