//
//  HelpMapListViewController.swift
//  CPWMobilePDF
//
//  Created by Tammy Bearly on 1/6/22.
//  Copyright © 2022 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class HelpMapListViewController: UIViewController {
    var maps:[PDFMap] = []
    var mapIndex:Int = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add Scrolling View, Logo, Title, and Text
        let help:HelpScrollView = HelpScrollView(UIScrollView(), view: view)
        help.addTitle(title: "CPW Mobile PDF Help")
        help.addText(text: "Go mobile with this offline PDF map viewer. Pinpoints your current location on PDF maps from the HuntingAtlas, FishingAtlas, CPW Maps Library, or any georeferenced PDF. No need for internet or cell tower connection! Plus, access a list of resources for downloading PDF maps.")

        help.addSubTitle(title: "Imported Maps")
        help.addText(text: "The Imported Maps page contains all the maps that you have downloaded and imported. These maps are copied into this app\'s data folder so that when you go mobile the map data is still available to use. For each imported map it displays the map name, file size, and current distance from the map (in miles). See Add Map, Edit Map, and View Map sections below to add, rename, delete, or view a map")
        help.addSubTitle(title: "Add Map")
        help.addText(text: "Click on the + button on the Imported Maps page to download or import a map.")
        help.addSubTitle(title: "Edit Map")
        help.addText(text: "Long press on the map name in the list of Imported Maps to change the map name, delete a map, or view it\'s file size and lat/long boundaries.")
        help.addSubTitle(title: "View Map")
        help.addText(text: "Click on a map in the list of Imported Maps to display the map, view current location, zoom in or out, and add waypoints.")
        help.addLastElement()
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        // pass variables to help map view
        guard let mapViewController = segue.destination as? MapViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        // pass the selected map name, thumbnail, etc to HelpMapViewController.swift
        mapViewController.maps = maps
        mapViewController.mapIndex = mapIndex
    }
}


#if DEBUG
// show preview window Editor/Canvas
import SwiftUI

@available(iOS 13.0.0, *)
struct HelpMapListVCPreview: PreviewProvider {
    static var devices = ["iPhone 6", "iPhone 12 Pro Max"]
    
    static var previews: some View {
        // The UIKit UIControllerView wrapped in a SwiftUI View
        
        // If using storyboard
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "HelpMapListViewController").toPreview()
        
        // IF not using Storyboard
        // let vc = HelpMapListViewController().toPreview()
            
        vc.colorScheme(.dark).previewDisplayName("Dark Mode")
        vc.colorScheme(.light).previewDisplayName("Light Mode")
       /* ForEach(devices, id: \.self) {
            deviceName in vc.previewDevice(PreviewDevice(rawValue: deviceName)).previewDisplayName(deviceName)
        }*/
    }
}
#endif
