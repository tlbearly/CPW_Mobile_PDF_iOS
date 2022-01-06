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
        
        // populate more drop down menu
        moreMenuTableview.delegate = self
        moreMenuTableview.dataSource = self
        moreMenuTableview.register(CellClass.self, forCellReuseIdentifier: "Cell")
        
        // add more drop down menu button
        let moreBtn = UIBarButtonItem(image: (UIImage(named: "more")), style: .plain, target: self, action: #selector(onClickMore))
        self.navigationItem.rightBarButtonItems = [moreBtn]
    }

    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        // map from file picker or website
        if (segue.identifier == "pdfFromFilePicker"){
            print("AddMapsViewController: return to MapListTableViewController to import map")
        }
    }
    
    @IBAction func performUnwindToAddMapDone(_ sender: UIStoryboardSegue) {
        //print("return to AddMapsViewController")
    }
    
    // MARK: Private Functions
    
    // MARK: More Menu
    func addMoreMenuTransparentView(frames:CGRect){
        let window = UIApplication.shared.keyWindow
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
            self.moreMenuTableview.frame = CGRect(x: 0, y: self.topbarHeight, width: Int(frames.width), height: self.dataSource.count * self.mainMenuRowHeight)
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
    @objc func onClickMore(_ sender:Any){
        //dataSource = ["Help"]
        if (!moreMenuShowing){
            addMoreMenuTransparentView(frames: self.view.frame)
        }else{
            removeMoreMenuTransparentView()
        }
    }
    
    // MARK: File Picker functions
    
    @IBAction func filePickerClicked(_ sender: PrimaryUIButton) {
        // open file picker with PDFs
        // use documentTypes: com.adobe.pdf (kUTTypePDF)
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func openBrowserClicked(_ sender: PrimaryUIButton) {
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
            print("selected a pdf. File is in urls[0] ", urls[0].lastPathComponent)
            
            // copy file to documents directory, warn if it already imported
            fileName = urls[0].lastPathComponent
            fileURL = urls[0]
            
            self.performSegue(withIdentifier: "pdfFromFilePicker", sender: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Cancelled")
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
