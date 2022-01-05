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
        // Scrolling View
        let scrollView = UIScrollView()
        let contentView = UIView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        // Logo
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imgView)
        imgView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        imgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
        let logo = UIImage(named: "icon")
        imgView.image = (logo)
        
        // Title
        let helpTitle = UILabel()
        helpTitle.text = "Add Map Help"
        helpTitle.font = UIFont.systemFont(ofSize: 24)
        helpTitle.sizeToFit()
        helpTitle.numberOfLines = 0
        helpTitle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(helpTitle)
        // Set its constraint to display it on screen
        helpTitle.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 3/4).isActive = true
        helpTitle.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 10).isActive = true
        helpTitle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        let helpText = UILabel()
        helpText.text = "Your current latitude and longitude will be displayed at the top of the map, and it will be displayed on the map as a cyan circle outlined in white. Double tap or pinch to zoom. To add waypoints, click on the push pin icon at the top-right, then click the map at the desired location. If the waypoint label is showing, clicking on a waypoint will display its label. Clicking on a waypoint label will let you edit the label and pushpin color."
        helpText.numberOfLines = 0
        helpText.sizeToFit()
        helpText.font = UIFont.systemFont(ofSize: 17)
        helpText.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(helpText)
        helpText.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 3/4).isActive = true
        helpText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        helpText.topAnchor.constraint(equalTo: helpTitle.bottomAnchor, constant: 10).isActive = true
        helpText.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 10).isActive = true
        //helpText.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        
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
