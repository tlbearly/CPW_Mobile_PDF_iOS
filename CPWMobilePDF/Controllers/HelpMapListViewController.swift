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
        let help:HelpScrollView = HelpScrollView(UIScrollView(), view: view, helpTitleStr: "CPW Mobile PDF Help", helpTextStr: "Take this app out in the field to display your current location on PDFs from the HuntingAtlas, FishingAtlas, CPW Maps Library, or any georeferenced PDF. No need for internet or data connection! Plus, access a list of resources for downloading PDF maps (requires data connection).")
        let contentView = help.getContentView()
        
        help.addTitle(contentView: contentView, title: "Imported Maps", topElem: help.getFirstTextElement())
        /*let scrollView = UIScrollView()
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        // Logo
        let viewForImg = UIView()
        let imgView = UIImageView(image: UIImage(named: "icon"))
        let imgSize:CGFloat = 140.0
        imgView.layer.borderColor = UIColor.lightGray.cgColor
        imgView.layer.borderWidth = 3
        viewForImg.layer.shadowColor = UIColor.gray.cgColor
        viewForImg.layer.shadowOpacity = 0.7
        viewForImg.layer.shadowOffset = .zero
        viewForImg.layer.shadowRadius = 5
        viewForImg.layer.cornerRadius = imgSize / 2.0 // round
        viewForImg.clipsToBounds = true
        viewForImg.layer.masksToBounds = false
        imgView.layer.cornerRadius = imgSize / 2.0
        imgView.clipsToBounds = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        viewForImg.addSubview(imgView)
        contentView.addSubview(viewForImg)
        imgView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: imgSize).isActive = true
        imgView.heightAnchor.constraint(equalToConstant: imgSize).isActive = true
        imgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        
        // Title
        let helpTitle = UILabel()
        helpTitle.text = "CPW Mobile PDF Help"
        helpTitle.font = UIFont.systemFont(ofSize: 24)
        helpTitle.sizeToFit()
        helpTitle.numberOfLines = 0
        helpTitle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(helpTitle)
        // Set its constraint to display it on screen
        helpTitle.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 4/5).isActive = true
        helpTitle.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 10).isActive = true
        helpTitle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        let helpText = UILabel()
        helpText.text = "Take this app out in the field to display your current location on PDFs from the HuntingAtlas, FishingAtlas, CPW Maps Library, or any georeferenced PDF. No need for internet or data connection! Plus, access a list of resources for downloading PDF maps (requires data connection)."
        helpText.numberOfLines = 0
        helpText.sizeToFit()
        helpText.font = UIFont.systemFont(ofSize: 17)
        helpText.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(helpText)
        helpText.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 4/5).isActive = true
        helpText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        helpText.topAnchor.constraint(equalTo: helpTitle.bottomAnchor, constant: 10).isActive = true
        helpText.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 10).isActive = true*/
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


#if DEFUG
// show preview window Editor/Canvas
import SwiftUI

struct HelpMapVC: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
    @available(iOS 13.0.0, *)
    func makeUIViewController(context: Context) -> some UIViewController {
        UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "HelpMapViewController")
        //HelpMapViewController()
    }
    
}
@available(iOS 13.0.0, *)
struct HelpMapViewCcontroller_Previews: PreviewProvider {
    static var previews: some View {
        // The UIKit UIControllerView wrapped in a SwiftUI View
        Group {
            // dark mode
            HelpMapVC().colorScheme(.dark)
            // light mode
            HelpMapVC.colorScheme(.light)
        }
    }
}
#endif
