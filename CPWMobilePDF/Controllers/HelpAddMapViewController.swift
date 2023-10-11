//
//  HelpAddMapViewController.swift
//  CPWMobilePDF
//
//  Created by Tammy Bearly on 1/4/22.
//  Copyright © 2022 Colorado Parks and Wildlife. All rights reserved.
//
// SwiftUI requires iOS 13!!!!! But is much easier to build the UI w/o storyboard

import UIKit

class HelpAddMapViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add Scrolling View, Logo, Title, and Text
        let help = HelpScrollView(UIScrollView(), view: view)
        help.addLogo()
        help.addTitle(title: "Adding Maps Help")
        
        help.addTitle(title: "STEP 1: Download Maps",size: 20.0, bold:false, underline: true)
        help.addText(text: "Click on the \'Open Browser\' button to download a map. Note that this requires an internet connection. It will notify you that it is starting up your browser app. Then it will load a page from the CPW website with resources to download georeferenced PDFs. Use one of the resources described below to download a map. If you have changed the default app that displays PDFs and that app does not allow saving the map, reset the default PDF viewer in Settings/app. \n\nTip: when the map displays, click the share button: ")
        help.addImg(img: "export-variant", x: 30, y: 30, borderWidth: 0.0)
        help.addText(text: "then scroll down to \'Save to Files\' and click \'Save\'. This will download the file to the location you pick. When you import the map, it will be copied to the app folder. It can then be deleted from the location you downloaded it to.")
        help.addTitle(title: "Map Resources:", size: 18, bold: true, underline: false)
        help.addTitle(title: "CPW Maps Library",size:20.0)
        help.addText(text: "Click on \'Maps Library page\'. Select file type, GeoPDF, and press \'Search\'. Click on a map name. It will display the map. Click the Share icon (box with up-arrow). Select \'Save to Files\', a location (iCloud or \'On My Phone\' Downloads), and then click on Save.")
        help.addTitle(title: "Hunting or Fishing Atlas",size:20.0)
        help.addText(text:"Click on \'Colorado Hunting Atlas\' or  \'Fishing Atlas\'. Select your map layers by clicking on the menu icon in the top-left. Set your zoom level. Then press the down arrow icon. It will allow you to change: map scale, map size, and orientation. Smaller map scales will show more detail. Larger map sizes will show larger map areas. Enter a PDF file name and press the Create PDF button. Wait for it to be created and then press Download PDF.")
        help.addTitle(title: "Forest Service",size:20.0)
        help.addImg(img: "fs", x: view.frame.width-20, y: view.frame.width-20)
        help.addText(text: "Click on \'USFS\'. Search for a location. When the forest service individual map boundaries are showing, click on one of the rectangles. Then in the popup box, click the \'>\' icon. Lastly, click on \'Download PDF\'. It will display the map. Click the Share icon (box with up-arrow). Select \'Save to Files\', a location (iCloud or \'On My Phone\' Downloads), and then click on Save.")
        help.addTitle(title: "USGS",size:20.0)
        help.addImg(img: "usgs", x: 284, y: 501)
        help.addText(text: "Click on \'USGS\'. Search for a location and tap on it. Scroll down to the most recent map and tap on it. Scroll down and select GeoPDF. Click \'OK\' on the popup that says \'you are navigating away...\' It will display the map. Click the Share icon (box with up-arrow). Select \'Save to Files\', a location (iCloud or \'On My Phone\' Downloads), and then click on Save.")
        
        help.addTitle(title: "STEP 2: Import Maps",size: 20.0, bold:false, underline: true)
        help.addText(text: "After you have downloaded PDF maps, import them by clicking on the \'File Picker\' button. Select the location where you put the map: On MY Phone, iCloud Drive, etc. Click on the PDF file and it will import it and display the map. The map file is copied to the app directory so deleting the original will not affect the imported maps.")
        
        help.addLastElement()
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation, pass variables here
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
struct HelpAddMapVCPreview: PreviewProvider {
    static var devices = ["iPhone 6", "iPhone 12 Pro Max"]
    
    static var previews: some View {
        // The UIKit UIControllerView wrapped in a SwiftUI View - code in UIViewcontrollerPreview.swift
        
        // If using storyboard
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "HelpAddMapViewController").toPreview()
        
        // IF not using Storyboard
        // let vc = HelpAddMapViewController().toPreview()
            
        vc.colorScheme(.dark).previewDisplayName("Dark Mode")
        vc.colorScheme(.light).previewDisplayName("Light Mode")
       /* ForEach(devices, id: \.self) {
            deviceName in vc.previewDevice(PreviewDevice(rawValue: deviceName)).previewDisplayName(deviceName)
        }*/
    }
}
#endif
