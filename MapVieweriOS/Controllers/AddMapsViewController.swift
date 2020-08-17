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
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Add Map"
        
        // For debugging write a test file to the documents dir
        writeDebugPDF(self, newFile: "Wellington")
        writeDebugPDF(self, newFile: "Wellington1")
        writeDebugPDF(self, newFile: "Wellington3")
        writeDebugPDF(self, newFile: "63RanchSTL_geo")
        writeDebugPDF(self, newFile: "CobbLake")
        writeDebugPDF(self, newFile: "Chambers_Lake_403010545_FSTopo")
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
    
    
    // MARK: Private Functions
    
    
    func writeDebugPDF(_ sender: Any, newFile: String){
        // For Debugging: use in simulater to write pdfs in app main directory on Mac to the Simulator's documents directory.
        
        guard let pdfFileURL = Bundle.main.url(forResource: newFile, withExtension: "pdf") else {
            print ("Can't write file: PDF file not found.")
            return
        }
        
        // destination directory name
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Can't get documents directory.")
            return
        }
        
        let name = newFile+".pdf"
        let destURL = documentsURL.appendingPathComponent(name)
        
        let filePath = destURL.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            return
        }
       
        do {
            try FileManager.default.copyItem(at:pdfFileURL, to: destURL)
        }
        catch{
            return
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
            print("selected a pdf. File is in urls[0]", urls[0].lastPathComponent)
            
            // copy file to documents directory, warn if it already imported
            fileName = urls[0].lastPathComponent
            fileURL = urls[0]
            
            self.performSegue(withIdentifier: "pdfFromFilePicker", sender: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Cancelled")
    }
}
