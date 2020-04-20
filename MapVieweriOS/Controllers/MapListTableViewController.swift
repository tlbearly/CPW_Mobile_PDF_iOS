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

import UIKit

class MapListTableViewController: UITableViewController {
    var currentMapName:String?
    var mapVC:MapViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load maps
        loadMaps()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

   
    // MARK: - Table view data source

    
    var maps = [PDFMap]()
    
    // MARK: Private Methods
    
    private func loadMaps() {
        let defaultThumb = UIImage(imageLiteralResourceName: "pdf_icon")
        let thumbnail1 = defaultThumb
        let thumbnail2 = defaultThumb
        let thumbnail3 = defaultThumb
        guard let map1 = PDFMap(name: "Wellington.pdf", thumbnail: thumbnail1) else {
            fatalError("Unable to instantiate map1")
        }
        guard let map2 = PDFMap(name: "Wellington1.pdf", thumbnail: thumbnail2) else {
            fatalError("Unable to instantiate map2")
        }
        guard let map3 = PDFMap(name: "Wellington3.pdf", thumbnail: thumbnail3) else {
            fatalError("Unable to instantiate map3")
        }
        maps += [map1, map2, map3]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        return 1
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
        cell.nameLabel.text = map.name
        cell.pdfImage.image = map.thumbnail
        
        print(map.name)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! MapListTableViewCell
        if mapVC != nil && cell.nameLabel.text != nil {
            var fileName:String = cell.nameLabel.text!
            let index = fileName.firstIndex(of: ".") ?? fileName.endIndex
            fileName = String(fileName[..<index])
            
            mapVC!.pdfFileName = fileName
            print(fileName)
        }
        else {
            print("Failed to get filename from selected row!!!")
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

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
        if segue.identifier == "goToMap" {
            mapVC = segue.destination as? MapViewController
        }
    }
    

}
