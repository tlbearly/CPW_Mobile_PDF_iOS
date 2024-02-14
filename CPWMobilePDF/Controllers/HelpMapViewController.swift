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
        help.addLogo()
        help.addTitle(title: "Map View Help")
        help.addText(text: "Location:\nYour current latitude and longitude will be displayed at the top of the map, and it will be displayed on the map as a cyan circle outlined in white.\n\nViewing the Map:\nDouble tap or pinch to zoom in or out. Drag to pan the map.\n\nWaypoints:\nTo add waypoints, click on the push pin icon at the top-right, then click the map at the desired location. To cancel adding a waypoint, click on the push pin icon with an X at the top-right. If the waypoint label is showing, clicking on the map will hide it. Clicking on a waypoint will display its label and edit, move, and delete buttons. Edit will let you edit the label and pushpin color. It will display the date added and the latitude and longitude. Move will turn the pin gray and display a location icon. Zoom or pan the map to the desired position. Use pinch or double tap to zoom and drag to pan the map. Then click the MOVE HERE button at the top of the screen, to move the waypoint.\n\n Loading Adjacent Maps:\nIf you are close to the map edge and your current location is on other maps, the Load Adjacent Maps button will appear. Clicking this will let you pick a map to switch to. This feature can be turned off in the map menu options.")
        help.addLastElement()
    }
    // preserve orientation
    /*override open var shouldAutorotate: Bool {
        // do not auto rotate
        return false
    }*/

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

// preserve orientation
/*extension UINavigationController {
    override open var shouldAutorotate: Bool {
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.shouldAutorotate
            }
            return super.shouldAutorotate
        }
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.preferredInterfaceOrientationForPresentation
            }
            return super.preferredInterfaceOrientationForPresentation
        }
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.supportedInterfaceOrientations
            }
            return super.supportedInterfaceOrientations
        }
    }
}*/

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
