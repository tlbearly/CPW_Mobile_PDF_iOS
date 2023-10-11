//
//  AddMapsViewController.swift
//  MapVieweriOS
//
//  Add a map to the app from filepicker or a website
//
//  Created by Tammy Bearly on 4/23/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//
// File Picker help https://www.google.com/search?client=firefox-b-1-d&q=swift+file+picker#kpvalbx=_2GqjXuXrEJrL0PEPi-id2AI26
//
// Segues https://matteomanferdini.com/unwind-segue

import UIKit
import MobileCoreServices // needed for pdf type kUTTypePDF

class AddMapsViewController: UIViewController {
    var map: PDFMap? = nil
    var fileName: String? = nil
    var fileURL: URL? = nil
    
    // more drop down menu
    let moreMenuTransparentView = UIView();
    let moreMenuTableview = UITableView();
    var dataSource = ["Help"]
    var moreMenuShowing = false
    var mainMenuRowHeight = 44
    //  Height of status bar + navigation bar (if navigation bar exist)
    var topbarHeight: Int {
        if #available(iOS 13.0, *) {
            return Int((view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 5) +
                (self.navigationController?.navigationBar.frame.height ?? 40))
        } else {
            // Fallback on earlier versions
            return Int(self.navigationController?.navigationBar.frame.size.height ?? 45)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Add Map"
        let help = HelpScrollView(UIScrollView(), view: view)
        help.addTitle(title: "STEP 1: Download Maps", size: 22.0)
        help.addText(text: "Show a list of map resources from the CPW website. The following resources will work with this app:")
        help.addText(text: "    \u{2022} Maps Library (use GeoPDF file type)")
        help.addText(text: "    \u{2022} Hunting Atlas or Fishing Atlas")
        help.addText(text: "    \u{2022} U.S. Forest Service")
        help.addText(text: "    \u{2022} U.S. Geological Survey")
        let txt = help.addText2(text: "See Help for more detailed instructions.")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openHelp(_:)))
        txt.isUserInteractionEnabled = true
        txt.addGestureRecognizer(tapGesture)
        let btn1 = help.addButton(text: "OPEN BROWSER")
        btn1.addTarget(self, action: #selector(openBrowserClicked(_:)), for: .touchUpInside)
        help.addTitle(title: "STEP 2: Import Maps", size: 22)
        help.addText(text: "Open File Picker to select PDF maps that you downloaded. They will be copied into this app.")
        let btn2 = help.addButton(text: "FILE PICKER")
        btn2.addTarget(self, action: #selector(filePickerClicked(_:)), for: .touchUpInside)
        help.addLastElement()
        
        // populate more drop down menu
        moreMenuTableview.delegate = self
        moreMenuTableview.dataSource = self
        moreMenuTableview.register(CellClass.self, forCellReuseIdentifier: "Cell")
        
        // add more drop down menu button
        let moreBtn = UIBarButtonItem(image: (UIImage(named: "more")), style: .plain, target: self, action: #selector(onClickMore))
        self.navigationItem.rightBarButtonItems = [moreBtn]
    }

    // preserve orientation
    override open var shouldAutorotate: Bool {
        // do not auto rotate
        return false
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        // map from file picker or website
        if (segue.identifier == "pdfFromFilePicker"){
            //print("AddMapsViewController: return to MapListTableViewController to import map")
        }
    }
    
    @IBAction func performUnwindToAddMapDone(_ sender: UIStoryboardSegue) {
        //print("return to AddMapsViewController")
    }
    
    // MARK: Private Functions
    
    // MARK: More Menu
    func addMoreMenuTransparentView(frames:CGRect){
        let window = UIApplication.shared.keyWindow
        let x = 55
        moreMenuTransparentView.frame = window?.frame ?? self.view.frame
        self.view.addSubview(moreMenuTransparentView)
        
        moreMenuTableview.frame = CGRect(x: 0, y: 0, width: frames.width, height: 0)
        self.view.addSubview(moreMenuTableview)
        moreMenuTableview.layer.cornerRadius = 5
        
        moreMenuTransparentView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        moreMenuTableview.reloadData()
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(removeMoreMenuTransparentView))
        moreMenuTransparentView.addGestureRecognizer(tapgesture)
        moreMenuTransparentView.alpha = 0
        
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.moreMenuTransparentView.alpha = 0.5
            self.moreMenuTableview.frame = CGRect(x: x, y: self.topbarHeight, width: Int(frames.width), height: self.dataSource.count * self.mainMenuRowHeight)
        }, completion: nil)
        moreMenuShowing = true
    }
    @objc func removeMoreMenuTransparentView(){
        let frames = self.view.frame
        // remove more button drop down menu view
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.moreMenuTransparentView.alpha = 0.0
            self.moreMenuTableview.frame = CGRect(x: 0, y: self.topbarHeight, width: Int(frames.width), height: 0)
        }, completion: nil)
        moreMenuShowing = false
    }
    
    @objc func openHelp(_ sender:UITapGestureRecognizer){
        self.performSegue(withIdentifier: "HelpAddMap", sender: nil)
    }
    @objc func onClickMore(_ sender:Any){
        //dataSource = ["Help"]
        if (!moreMenuShowing){
            addMoreMenuTransparentView(frames: self.view.frame)
        }else{
            removeMoreMenuTransparentView()
        }
    }
    
    // MARK: File Picker functions
    
    @objc func filePickerClicked(_ sender:PrimaryUIButton) {
        // open file picker displaying only PDFs
        // use documentTypes: com.adobe.pdf (kUTTypePDF)
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    // MARK: Open Browser functions

    @objc func openBrowserClicked(_ sender:PrimaryUIButton){
        // Download button clicked, open the user's browser to download pdf maps
        guard let url = URL(string: "https://cpw.state.co.us/learn/Pages/Maps.aspx") else {
            print("failed to create url")
            return }
        UIApplication.shared.open(url)
    }
}

extension AddMapsViewController: UIDocumentPickerDelegate {
    // iOS 8.0 - 11.0
    /*func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
       // called when user selects a pdf to import
        print("selected a pdf. File is in url ",url)
        
        // copy file to documents directory, warn if it already imported
        fileName = url.lastPathComponent
        fileURL = url
        
        self.performSegue(withIdentifier: "pdfFromFilePicker", sender: nil)
    }*/
    
    // iOS 11.0+
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // called when user selects a pdf to import
            //print("selected a pdf. File is in urls[0] ", urls[0].lastPathComponent)
            
            // copy file to documents directory, warn if it already imported
            fileName = urls[0].lastPathComponent
            fileURL = urls[0]
            
            self.performSegue(withIdentifier: "pdfFromFilePicker", sender: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        //print("Cancelled")
    }
}

// More Menu Functions
extension AddMapsViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.rowHeight // 50
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (dataSource[indexPath.row] == "Help"){
            removeMoreMenuTransparentView()
            // Show HelpAddMapViewController
            self.performSegue(withIdentifier: "HelpAddMap", sender: nil)
        }
    }
}

#if DEBUG
// show preview window Editor/Canvas
import SwiftUI

@available(iOS 13.0.0, *)
struct AddMapsVCPreview: PreviewProvider {
    static var devices = ["iPhone 6", "iPhone 12 Pro Max"]
    
    static var previews: some View {
        // The UIKit UIControllerView wrapped in a SwiftUI View - code in UIViewcontrollerPreview.swift
        
        // If using storyboard
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "AddMapsViewController").toPreview()
        
        // IF not using Storyboard
        // let vc = AddMapsViewController().toPreview()
            
        vc.colorScheme(.dark).previewDisplayName("Dark Mode")
        vc.colorScheme(.light).previewDisplayName("Light Mode")
       /* ForEach(devices, id: \.self) {
            deviceName in vc.previewDevice(PreviewDevice(rawValue: deviceName)).previewDisplayName(deviceName)
        }*/
    }
}
#endif
