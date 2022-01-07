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
        HelpScrollView(UIScrollView(), view: view, helpTitleStr: "Add Map Help", helpTextStr: "Your current latitude and longitude will be displayed at the top of the map, and it will be displayed on the map as a cyan circle outlined in white. Double tap or pinch to zoom. To add waypoints, click on the push pin icon at the top-right, then click the map at the desired location. If the waypoint label is showing, clicking on a waypoint will display its label. Clicking on a waypoint label will let you edit the label and pushpin color.")
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
