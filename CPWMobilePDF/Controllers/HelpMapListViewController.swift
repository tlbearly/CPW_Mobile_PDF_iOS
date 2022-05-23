//
//  HelpMapListViewController.swift
//  CPWMobilePDF
//
//  Created by Tammy Bearly on 1/6/22.
//  Copyright © 2022 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class HelpMapListViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add Scrolling View, Logo, Title, and Text
        let help:HelpScrollView = HelpScrollView(UIScrollView(), view: view)
        help.addLogo()
        help.addTitle(title: "CPW Mobile PDF Help")
        help.addText(text: "Go mobile with this offline PDF map viewer. Pinpoints your current location on PDF maps from the HuntingAtlas, FishingAtlas, CPW Maps Library, or any georeferenced PDF. No need for internet or cell tower connection! Plus, access a list of resources for downloading PDF maps.")

        help.addTitle(title: "Imported Maps",size:20.0)
        help.addText(text: "The Imported Maps page contains all the maps that you have downloaded and imported. These maps are copied into this app\'s data folder so that the map data is still available to use when you go mobile. Each imported map displays: the map name, file size, and current distance from the map in miles. See Add Map, Edit Map, and View Map sections below to add, rename, delete, or view a map.")
        help.addTitle(title:"Current Location On The Map", size:20.0)
        help.addImg(img: "nearme", x: 40.0, y: 40.0, borderWidth: 0.0)
        help.addText(text: "If you are on the map, the location icon, pictured above, will be displayed.")
        help.addTitle(title: "Add Map", size:20.0)
        help.addText(text: "Click on the + button on the Imported Maps page to download or import a map.")
        help.addTitle(title: "Edit Map", size:20.0)
        help.addText(text: "Press \'Edit\' to change the map name or delete a map. Also, you may slide the row to the left to delete.")
        help.addTitle(title: "View Map", size:20.0)
        help.addText(text: "Click on a map to display the map, view current location, zoom in or out, and add waypoints.")
        help.addLastElement()
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
    }
}


#if DEBUG
// show preview window Editor/Canvas
import SwiftUI

@available(iOS 13.0.0, *)
struct HelpMapListVCPreview: PreviewProvider {
    static var devices = ["iPhone 6", "iPhone 12 Pro Max"]
    
    static var previews: some View {
        // The UIKit UIControllerView wrapped in a SwiftUI View - code in UIViewcontrollerPreview.swift
        
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
