//
//  AddMapsViewController.swift
//  MapVieweriOS
//
//  Created by Tammy Bearly on 4/23/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//
// File Picker help https://www.google.com/search?client=firefox-b-1-d&q=swift+file+picker#kpvalbx=_2GqjXuXrEJrL0PEPi-id2AI26
//


import UIKit
import MobileCoreServices

class AddMapsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Add Map"
        // For debugging write a test file to the documents dir
        //writeDebugPDF(self)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func writeDebugPDF(_ sender: Any){
        // use in simulater to write Wellington.pdf to the Simulator documents directory.
        guard let pdfFileURL = Bundle.main.url(forResource: "Wellington", withExtension: "pdf") else {
            print ("Can't write file: PDF file not found.")
            return
        }
        // destination directory name
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Can't get documents directory.")
            return
        }

        let fileName = "Wellington.pdf"
        let destURL = documentsURL.appendingPathComponent(fileName)
        do {
            try FileManager.default.copyItem(at:pdfFileURL, to: destURL)
        }
        catch{
            print("can't copy file")
        }
    }
    
    
    @IBAction func filePickerClicked(_ sender: PrimaryUIButton) {
        print("open file picker")
        //com.adobe.pdf (kUTTypePDF)
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    
}

extension AddMapsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
       // called when user selects a pdf to import
        print("selected a pdf. File is in urls[0]")
        
    }
}
