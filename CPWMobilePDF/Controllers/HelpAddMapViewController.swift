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
    var maps:[PDFMap] = []
    var mapIndex:Int = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add Scrolling View, Logo, Title, and Text
        let help = HelpScrollView(UIScrollView(), view: view)
        help.addTitle(title: "Adding Maps Help")
        help.addSubTitle(title: "Import Maps")
        help.addText(text: "After you have downloaded PDF maps, import them by clicking on the File Picker button. Use the menu in the top-left to select from Recent, Documents, or Downloads folders. Or select the Google Drive icon if the file is located there. Click on the PDF file and it will import it and display the map. The map file is copied to the app directory so deleting the original will not affect the imported maps.")
        help.addSubTitle(title: "Download Maps")
        help.addText(text: "Click on the Open Browser button to download a map. Note that this requires an internet connection. It will notify you that it is starting up your browser app. Then it will load a page from the CPW website with resources to download georeferenced PDFs. Use one of the resources described below to download a map. Depending on your settings, the PDF map file will either download or be displayed. If it is displayed, click the menu button in the top-right and then click Download. Once it has downloaded, go back to this app and click the File Picker button, open the Downloads folder, and click on the map that was downloaded (hint to get back to this app: click the Recent Apps icon next to the home icon at the bottom of your phone, then select this app). From the CPW resource page, click on one of the following resources:")
        help.addSubTitle(title: "CPW Maps Library")
        help.addText(text: "Click on \'Maps Library page\'. Select file type, GeoPDF, and press \'Search\'. Click on a map name to download it.")
        help.addSubTitle(title: "Hunting or Fishing Atlas")
        help.addText(text: "Click on the \'Colorado Hunting Atlas\' or the \'Colorado Fishing Atlas\'. Select you map layers and map boundary by clicking on the menu icon in the top-left. Set your zoom level. Then press the down arrow icon. It will allow you to choose the map scale but, may change the map boundary. Setting a smaller map scale will show more detail. Increasing the map size will show a larger map area. Enter a PDF file name and press the Create PDF button. Wait for it to be created and then press Download PDF.")
        
        
        
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


#if DEFUG
// show preview window Editor/Canvas
import SwiftUI

struct HelpAddMapViewController_Representable: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
    @available(iOS 13.0.0, *)
    func makeUIViewController(context: Context) -> some UIViewController {
        HelpAddMapViewController()
    }
    
}
@available(iOS 13.0.0, *)
struct HelpAddMapViewController_Previews: PreviewProvider {
    static var previews: some View {
        HelpAddMapViewController_Representable().colorScheme(.dark) // .light or .dark
    }
}
#endif
