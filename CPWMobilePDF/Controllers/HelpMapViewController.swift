//
//  HelpMapViewController.swift
//  CPWMobilePDF
//
//  Created by Tammy Bearly on 12/27/21.
//  Copyright © 2021 Colorado Parks and Wildlife. All rights reserved.
//
// SwiftUI requires iOS 13!!!!! But is much easier to build the UI w/o storyboard

import UIKit

class HelpMapViewController: UIViewController {
    var maps:[PDFMap] = []
    var mapIndex:Int = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add Scrolling View, Logo, Title, and Text
        let help = HelpScrollView(UIScrollView(), view: view)
        help.addTitle(title: "Map View Help")
        help.addText(text: "Your current latitude and longitude will be displayed at the top of the map, and it will be displayed on the map as a cyan circle outlined in white. Double tap or pinch to zoom. To add waypoints, click on the push pin icon at the top-right, then click the map at the desired location. If the waypoint label is showing, clicking on a waypoint will display its label. Clicking on a waypoint label will let you edit the label and pushpin color.")
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
struct HelpMapVCPreview: PreviewProvider {
    static var devices = ["iPhone 6", "iPhone 12 Pro Max"]
    
    static var previews: some View {
        // The UIKit UIControllerView wrapped in a SwiftUI View - code in UIViewcontrollerPreview.swift
        
        // If using storyboard
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "HelpMapViewController").toPreview()
        
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
