//
//  MapViewController.swift
//  MapVieweriOS
//
//  Created by Tammy Bearly on 2/13/20.
//  Copyright © 2020 Tammy Bearly. All rights reserved.
//
// PdfKit https://docs.huihoo.com/apple/wwdc/2017/241_introducing_pdfkit_on_ios.pdf

// gesture recognizer, add signature example https://medium.com/@rajejones/add-a-signature-to-pdf-using-pdfkit-with-swift-7f13f7faad3e

// Download file with alamofire
// Download a file and get notified when it is ready https://www.appcoda.com/swift-delegate/

/* Thumbnails
 // Setup thumbnail viewthumbnailView.pdfView = pdfViewthumbnailView.thumbnailSize = CGSize(width: 100, height: 100)thumbnailView.layoutMode = .verticalthumbnailView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
 */

// Annotations
// check out code at https://medium.com/@artempoluektov/ios-pdfkit-ink-annotations-tutorial-4ba19b474dce
// https://github.com/rajubd49/PDFKit_Sample
// panGesture in pdfView https://stackoverflow.com/questions/46733741/ios-11-pdfkit-not-updating-annotation-position
// anotation, thumbnail

import UIKit
import PDFKit // requires iOS 11+ iPhone 6+
import CoreLocation // current location


class MapViewController: UIViewController {
    // MARK: Variables
    var pdfView:PDFView = PDFView()
    var map:PDFMap?
    var locationManager = CLLocationManager()
    let allowBtn = PrimaryUIButton() // turn on location services button
    // make a dummy location dot because displayLocation deletes it first
    var currentLocation: PDFAnnotation = PDFAnnotation(bounds: CGRect(x:0, y:0, width:1,height:1), forType: .circle, withProperties: nil)
    var lat1:Double = 0.0
    var lat2:Double = 0.0
    var long1:Double = 0.0
    var long2:Double = 0.0
    var latNow:Double = 0.0
    var longNow:Double = 0.0
    var marginTop:Double = 0.0
    var marginBottom:Double = 0.0
    var marginLeft:Double = 0.0
    var marginRight:Double = 0.0
    var mediaBoxWidth:Double = 0.0
    var mediaBoxHeight:Double = 0.0
    var latDiff:Double = 0.0
    var longDiff:Double = 0.0
    var pdfWidth:Double = 0.0
    var pdfHeight:Double = 0.0
    var currentLatLong:UITextField = UITextField()
    var debugTxtBox:UITextField = UITextField()
    private var popup:UITextField = UITextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    private var selectedWayPt:PDFAnnotation = PDFAnnotation()
    var screenWidth:CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = map?.displayName
        screenWidth = self.view.frame.size.width
        
        //
        // OPEN PDF & Add pdfView
        //
        do {
            try setupPDFView()
        }
        catch AppError.pdfMapError.pdfFileNotFound (let file){
            displayError(msg: "Map file not found.\n\n\(file)")
            return
        } catch {
            displayError(msg: "Unknow error occured.")
            return
        }
        
        //NSNotificationName PDFViewScaleChangedNotification
        
        
        //
        // Display Current location: lat long
        //
        addCurrentLatLongTextbox()
        
        // Debug text box
        //addDebugTextbox()
    
        
        // set page margins
        marginTop = map!.marginTop
        marginBottom = map!.marginBottom
        marginLeft = map!.marginLeft
        marginRight = map!.marginRight
        
        // set page boundary with margins
        mediaBoxWidth = map!.mediaBoxWidth
        mediaBoxHeight = map!.mediaBoxHeight
        
        // set lat/long boundary in decimal degrees
        lat1 = map!.lat1
        long1 = map!.long1
        lat2 = map!.lat2
        long2 = map!.long2
        latDiff = map!.latDiff
        longDiff = map!.longDiff
        
        // set pdf boundary without margins
        pdfWidth = map!.pdfWidth
        pdfHeight = map!.pdfHeight
        
        
        // Call location manager
        setupLocationServices()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "editWayPt":
            guard let editWayPtVC = segue.destination as? EditWayPtViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            // pass the selected map name, thumbnail, etc to MapViewController.swift
            let wayPt = selectedWayPt.contents
            editWayPtVC.wayPt = wayPt ?? "description$lat, long$date added$cyan_pin$0$0"
        default:
            fatalError("Unexpected Segue Identifier: \(String(describing: segue.identifier))")
        }
    }
    
    // MARK: Navigation
    
    @IBAction func performUnwindToMapDone(_ sender: UIStoryboardSegue) {
        // MARK: WayPt Done
        guard let editWayPtVC = sender.source as? EditWayPtViewController else {
            fatalError("Unexpected Segue Sender: \(String(describing: sender.source))")
        }
        let desc = editWayPtVC.wayPtDesc.text ?? "Way Point"
        guard let page = pdfView.document?.page(at: 0) else {
            displayError(msg: "Problem reading the PDF map. Can't get page 1.")
            return
        }
        page.removeAnnotation(selectedWayPt)
        // add padding to desc since textview doesn't use margins
        addWayPt(x: CGFloat(editWayPtVC.x), y: CGFloat(editWayPtVC.y), page: page, imageName: editWayPtVC.pushPinImg, desc: " " + desc.trimmingCharacters(in: .whitespacesAndNewlines), dateAdded: editWayPtVC.addDate.text)
        savePDF()
    }
    
    @IBAction func performUnwindToMapTrash(_ sender: UIStoryboardSegue) {
        // MARK: WayPt Trash
        // delete selectedWayPt and savePDF
        guard let page = pdfView.document?.page(at: 0) else {
            displayError(msg: "Problem reading the PDF map. Can't get page 1.")
            return
        }
        page.removeAnnotation(selectedWayPt)
        //selectedWayPt.action = .delete
        savePDF()
    }
    
    
    func setupLocationServices() {
        // MARK: setupLocationServices
        // Check for location permission. Display button is permission is needed. Start updating
        // user location.
        guard let page = pdfView.document?.page(at: 0) else {
            displayError(msg: "Problem reading the PDF map. Can't get page 1.")
            return
        }
        locationManager.desiredAccuracy=kCLLocationAccuracyBest
        let status = CLLocationManager.authorizationStatus()
        print("location status ",status)
        switch status {
        case .notDetermined:
            // display button, when click on it display permissions request
            currentLatLong.text = " Current location: Needs location permission"
            allowBtn.isHidden = false
            allowBtn.setTitle("Allow Location Permission", for: .normal)
            allowBtn.addTarget(self, action: #selector(self.allowBtnPressed), for: .touchUpInside)
            allowBtn.backgroundColor = UIColor.cyan
            allowBtn.setTitleColor(.black, for: .normal)
            view.addSubview(allowBtn)
            allowBtn.translatesAutoresizingMaskIntoConstraints = false
            allowBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50).isActive = true
            allowBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50).isActive = true
            allowBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -130).isActive = true
            allowBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80).isActive = true
            
        case .denied, .restricted:
            currentLatLong.text = " Current location: Needs location permission"
            let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable Location Services in Settings, Privacy, Location Services.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
            
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading() // get azimuth
            self.displayLocation(page: page, pdfView: self.pdfView) // initial location
            // update location every 2 seconds
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                self.displayLocation(page: page, pdfView: self.pdfView)
            }
            
        default:
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading() // get azimuth
            self.displayLocation(page: page, pdfView: self.pdfView) // initial location
            // update location every 2 seconds
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                self.displayLocation(page: page, pdfView: self.pdfView)
            }
        }
    }
    
    func setupPDFView() throws {
        // MARK: sertupPDFView
        // Loads the url into a PDFVIew
        
        // check if file exists
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if map == nil {
            throw AppError.pdfMapError.mapNil
        }
        
        let url = documentsDir.appendingPathComponent(map!.fileName)
        if !FileManager.default.fileExists(atPath:url.path){
            print("Map file not found: \(url.absoluteString)")
            throw AppError.pdfMapError.pdfFileNotFound(file: url.lastPathComponent)
        }
        pdfView.frame = self.view.bounds
        guard let document:PDFDocument = PDFDocument(url: url) else{
            print("File not found: ",url)
            throw AppError.pdfMapError.pdfFileNotFound(file: url.absoluteString)
        }
        // Must set this to false!
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        pdfView.autoresizesSubviews = true
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin, .flexibleLeftMargin]
        pdfView.displayDirection = .vertical
        // show only one page of document. true is causing many errors????? Can't zoom in with double click any more when this is uncommented!
        //pdfView.usePageViewController(true)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        //pdfView.displaysPageBreaks = true
        pdfView.document = document
        pdfView.backgroundColor = UIColor.lightGray // must be set after pdfView.document

        // how far can we zoom in?
        pdfView.maxScaleFactor = 8.0
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit // fit in window
        
        //pdfView.autoScales = true // true is giving error one error
        //pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit //pdfView.scaleFactor
        //pdfView.zoomIn(15.0)
        //pdfView.maxScaleFactor = 10
        //pdfView.scaleFactor = 1
        print ("min \(pdfView.minScaleFactor)  max \(pdfView.maxScaleFactor)  scaleFactor \(pdfView.scaleFactor)");
        
        // add gestures
        //pdfView.isUserInteractionEnabled = true
        let singleScreenTap = UITapGestureRecognizer(target: self, action: #selector(MapViewController.pdfViewTapped(_:)))
        singleScreenTap.numberOfTapsRequired = 1
        singleScreenTap.numberOfTouchesRequired = 1
        let doubleScreenTap = UITapGestureRecognizer(target: self, action: #selector(MapViewController.pdfViewTapped2(_:)))
        doubleScreenTap.numberOfTapsRequired = 2
        doubleScreenTap.numberOfTouchesRequired = 1
        singleScreenTap.require(toFail: doubleScreenTap)
        pdfView.addGestureRecognizer(singleScreenTap)
        pdfView.addGestureRecognizer(doubleScreenTap)
    }
    
    func displayError(msg: String){
        // MARK: displayError
        let alert = UIAlertController(title: "Unable to View Map", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
        return
    }
    
    // MARK: addCurrentLatLongTextbox
    func addCurrentLatLongTextbox() {
        // MARK: addCurrentLatLongTextbox
        // Add text box for current location display
        currentLatLong.text = "  Current location: "
        currentLatLong.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        currentLatLong.allowsEditingTextAttributes = false
        
        // layoutMargins does nothing!!!!!!!!!????????????
        //currentLatLong.layoutMargins = UIEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 20.0)
        
        currentLatLong.textColor = UIColor.white
        view.addSubview(currentLatLong)
        currentLatLong.translatesAutoresizingMaskIntoConstraints = false
        currentLatLong.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        currentLatLong.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        currentLatLong.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        currentLatLong.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
    }
    
    // MARK: addDebugTextbox
    func addDebugTextbox() {
        // Add text box for current location display
        debugTxtBox.text = "  Debug: "
        debugTxtBox.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        debugTxtBox.allowsEditingTextAttributes = false
        
        // layoutMargins does nothing!!!!!!!!!????????????
        //debugTxtBox.layoutMargins = UIEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 20.0)
        
        debugTxtBox.textColor = UIColor.white
        view.addSubview(debugTxtBox)
        debugTxtBox.translatesAutoresizingMaskIntoConstraints = false
        debugTxtBox.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        debugTxtBox.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        debugTxtBox.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        debugTxtBox.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100).isActive = true
    }
    
    // MARK: displayLocation
    
    //func displayLocation(page: PDFPage, pdfView: PDFView, latNow: Double, longNow:Double){
    func displayLocation(page: PDFPage, pdfView: PDFView){
        // Remove last location dot
        page.removeAnnotation(currentLocation) // remove last location dot
        
        // DEBUG remove margin and lat long circles
        if (page.annotations.count > 0){
            for i in stride(from: page.annotations.count-1, to: 0, by: -1) {
                if (page.annotations[i].type == "Circle"){
                    page.removeAnnotation(page.annotations[i])
                }
            }
        }
        
        
        var azimuth:Double = -1.0
        // get current location
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
           CLLocationManager.authorizationStatus() == .authorizedAlways) {
            guard let currentLoc = locationManager.location else {
                currentLatLong.text = " Current location: Not available"
                return
            }
            latNow = currentLoc.coordinate.latitude
            longNow = currentLoc.coordinate.longitude
            // get the azimuth the heading relative to the magnetic North Pole 0 = pointed toward magnetic north, 90=east relative to the headingOrientation in CLLocationManager
            // Add direction arc
            if let heading = locationManager.heading  {
                if (heading.headingAccuracy > 0.0){
                    // CLLocationManager.CLDeviceOrientation.portrait
                    // landscapeLeft, landscapeRight
                    azimuth = heading.magneticHeading
                    debugTxtBox.text = "orient: \(locationManager.headingOrientation) a=\(azimuth)"
                }
            }
        }
        else {
            currentLatLong.text = "  Current location: Needs location permission"
            return
        }
        // See if current location is on the map
        if (latNow >= lat1 && latNow <= lat2 && longNow >= long1 && longNow <= long2) {
            currentLatLong.text = "  Current location: \(latNow), \(longNow)"
        }
        else {
            currentLatLong.text = "  Current location: Not on map"
            return
        }
        
        let cirSize:Double = 30.0
        let halfCirSize:Double = 15.0

        // Add current location dot
        var x:Double = (((longNow + 180.0) - (long1 + 180.0)) / longDiff) * pdfWidth
        x = x + marginLeft - halfCirSize
        var y:Double = (((90.0 - latNow) - (90.0 - lat2)) / latDiff) * pdfHeight
        y = (pdfHeight + marginTop - halfCirSize)  - (y) // Y is too low add 90???

        // border
        let border = PDFBorder()
        
        // fill color
        // this line crashes in iOS 11.0 PDFAnnotation.setInteriorColor
        if #available(iOS 11.2, *) {
            currentLocation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:cirSize,height:cirSize), forType: .circle, withProperties: nil)
            currentLocation.interiorColor = UIColor.cyan
            border.lineWidth = 5.0 // border width
            currentLocation.color = UIColor.white // border color
        }
        // iOS 11.0 and 11.1 don't have interiorColor function
        else {
            currentLocation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:cirSize,height:cirSize), forType: .circle, withProperties: nil)
            border.lineWidth = 12.0 // border width
            currentLocation.color = UIColor.cyan // border color
        }
        
        
        currentLocation.border = border
        page.addAnnotation(currentLocation)
        
        
        // Margin red dots
        let marginTLAnnotation = PDFAnnotation(bounds: CGRect(x:marginLeft-10, y:mediaBoxHeight - marginTop - 10, width:20,height:20), forType: .circle, withProperties: nil)
        // color
        if #available(iOS 11.2, *) {
            marginTLAnnotation.interiorColor = UIColor.red
        }
        
        page.addAnnotation(marginTLAnnotation)
        let marginBRAnnotation = PDFAnnotation(bounds: CGRect(x:mediaBoxWidth - marginRight-10, y:marginBottom-10, width:20,height:20), forType: .circle, withProperties: nil)
        // color
        if #available(iOS 11.2, *) {
            marginBRAnnotation.interiorColor = UIColor.red
        }
        
        page.addAnnotation(marginBRAnnotation)
        
        // map lat long boundaries long1,lat1 and long2,lat2 in yellow
        x = (((long1 + 180.0) - (long1 + 180.0)) / longDiff) * pdfWidth
        x = x + marginLeft - 5
        y = (((90.0 - lat1) - (90.0 - lat2)) / latDiff) * pdfHeight
        y = y + marginBottom - 5
        var latlongAnnotation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:10,height:10), forType: .circle, withProperties: nil)
        // color
        if #available(iOS 11.2, *) {
            latlongAnnotation.interiorColor = UIColor.yellow
        }
        page.addAnnotation(latlongAnnotation)
        
        // map lat long boundaries long2,lat2
        x = (((long2 + 180) - (long1 + 180)) / longDiff) * pdfWidth
        x = x + marginLeft - 5
        y = (((90.0 - lat2) - (90.0 - lat2)) / latDiff) * pdfHeight
        y = y + marginBottom - 5
        latlongAnnotation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:10,height:10), forType: .circle, withProperties: nil)
        if #available(iOS 11.2, *) {
            latlongAnnotation.interiorColor = UIColor.yellow
        }
        page.addAnnotation(latlongAnnotation)
    }
    
    // On rotation make map fit, was zooming on landscape NOT WORKING??? Does nothing???
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
   /*     pdfView.frame = view.frame
        pdfView.autoScales = true
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        if UIDevice.current.orientation.isLandscape {
            print("landscape")
        }
        else {
            print("portrait")
        } */
    }
    // fix autoscales bug on iPad on screen rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
      pdfView.autoScales = true
    }
    
    
    // save the pdf with annotations in app directory
    func savePDF(){
        //guard let fileName = map?.fileURL else {
        //    fatalError("Map file not found")
        //}
        //pdfView.document?.write(to:fileName) // this overwrites all of the geo spatial info!!!!
        // Save way points to database
    }
    
    @objc func allowBtnPressed(){
        // User pressed allowBtn display permissions dialog
        // hide button
        allowBtn.isHidden = true;
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading() // get azimuth
        guard let page = self.pdfView.document?.page(at: 0) else {
            print("Problem reading the PDF. Can't get page 1.")
            return
        }
        self.displayLocation(page: page, pdfView: self.pdfView) // initial location
        // update location every 3 seconds
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            self.displayLocation(page: page, pdfView: self.pdfView)
        }
    }
    
    
    @objc func pdfViewTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        // MARK: pdfViewTap
        // Check if clicked on Way Point or add new way point annotation
        print("called single tap")
        
        let pdfView = gestureRecognizer.view as! PDFView
        if gestureRecognizer.state == .ended
        {
            if let page = pdfView.currentPage
            {
                let location:CGPoint = gestureRecognizer.location(in: pdfView) // location on screen
                let pdfViewPoint = pdfView.convert(location, to: page) // location on pdf
                var removingPopup:Bool = false
                
                print ("Scr: \(Int(location.x)), \(Int(location.y))")
                print ("PDF: \(Int(pdfViewPoint.x)), \(Int(pdfViewPoint.y))")
                
                // is popup showing? Did they click on the popup then allow editing
                if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
                    // popup is showing and did not click on popup hide it.
                    removingPopup = true
                    aPopup.removeFromSuperview()
                }
                                
                // clicked on way point annotation?
                guard let waypt = page.annotation(at: pdfViewPoint) else {
                    if removingPopup {
                        return
                    }
                    
                    // ADD A WAY POINT
                    // make sure it is on the map
                    if (pdfViewPoint.x>CGFloat(marginLeft) && pdfViewPoint.y>CGFloat(marginBottom) &&
                        pdfViewPoint.x<CGFloat(mediaBoxWidth - marginRight) &&
                        pdfViewPoint.y<CGFloat(mediaBoxHeight - marginTop)){
                        //print ("add a way point!!!")
                        var count:Int = 1
                        if (page.annotations.count > 0){
                            for i in 0...page.annotations.count-1 {
                                if page.annotations[i].type == "Stamp" {
                                    count+=1
                                }
                            }
                        }
                        let desc = " Way Point \(count)";
                        addWayPt(x: pdfViewPoint.x, y: pdfViewPoint.y, page: page, imageName: "cyan_pin", desc: desc, dateAdded: nil)
                        return
                    }
                    // Display off map message for 1 second
                    else {
                        //print ("off map x \(Int(pdfViewPoint.x)) > width \(Int(pdfView.bounds.width)) or y \(Int(pdfViewPoint.y)) > height  \(Int(pdfView.bounds.height)) or negative")
                        let alert = UIAlertController(title: "Off Map", message: "", preferredStyle: .alert)
                        self.present(alert, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                            alert.dismiss(animated: true)
                        }
                        return
                    }
                }
                
                // clicked on existing annotation. Is it a way pt? type stamp?
                if (waypt.type != "Stamp"){
                    // clicked on current location
                    addWayPt(x: pdfViewPoint.x, y: pdfViewPoint.y, page: page, imageName: "cyan_pin", desc: " Way Point", dateAdded: nil)
                    return
                    
                }
                
                // Display popup bubble
                selectedWayPt = waypt
                
                let popupWidth:CGFloat = 150
                let popupHeight:CGFloat = 50
                print ("way pt height: \(waypt.bounds.maxY - waypt.bounds.minY)")
                
                // calculate pixels to move over to get to mid point in image
                // ratio is used to covert from pdf pt to screen pt
                let ratioX = location.x/pdfViewPoint.x
                let ratioY = location.y/pdfViewPoint.y
                let wayptXMiddle:CGFloat = (waypt.bounds.maxX - waypt.bounds.minX)/2 + waypt.bounds.minX
                let xMove:CGFloat = (pdfViewPoint.x - wayptXMiddle) * ratioX
                var x = location.x - xMove - popupWidth/2
                if (x < 1) {
                    x = 1
                }
                else if (x + popupWidth > screenWidth){
                    x = screenWidth - popupWidth
                }
                let yMove:CGFloat = (waypt.bounds.maxY - pdfViewPoint.y) / ratioY
                
                let y = location.y - (yMove + popupHeight)
                print("xRatio:\(ratioX) xscr:\(Int(location.x)) - xmove:\(Int(xMove)) - wd:\(Int(popupWidth/2)) = x:\(Int(x))")
                
                print("yRatio:\(ratioY) yscr:\(Int(location.y)) - ymove:\(Int(yMove)) - ht:\(Int(popupHeight)) = y:\(Int(y))")
                
                /*let descLabel = UILabel(frame: CGRect(x: 10, y: 20, width: 80, height: 30))
                descLabel.text = "Desc:"
                let desc = UITextField(frame: CGRect(x: 90, y:20, width: 200, height: 30))
                desc.backgroundColor = .init(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
                desc.borderStyle = UITextField.BorderStyle.roundedRect
                let latlongLabel = UILabel(frame: CGRect(x: 10, y: 60, width: 80, height: 30))
                latlongLabel.text = "Lat/Long:"
                let latlong = UITextField(frame: CGRect(x: 90, y:60, width: 200, height: 30))
                latlong.allowsEditingTextAttributes = false
                let timeNowLabel = UILabel(frame: CGRect(x: 10, y: 100, width: 80, height: 30))
                timeNowLabel.text = "Date:"
                let timeNow = UITextField(frame: CGRect(x: 90, y:100, width: 200, height: 30))
                timeNow.allowsEditingTextAttributes = false
                let saveBtn = PrimaryUIButton(frame: CGRect(x:10, y:300,width: 80, height: 40))
                saveBtn.setTitle("Save", for: .normal)*/
                popup = UITextField(frame: CGRect(x: x, y: location.y+20, width: popupWidth, height: popupHeight))
                
                
                // edit text listener
                popup.addTarget(self, action: #selector(MapViewController.wayptTextClicked(_:)), for: UIControl.Event.touchDown)// .editingDidEnd)
                guard let items = waypt.contents?.components(separatedBy: "$") else {
                    print("empty waypt contents!!!!")
                    return
                }
                //desc.text = items[0]
                //latlong.text = items[1]
                //timeNow.text = items[2]
                
                popup.text = " " + items[0]
                
                popup.tag = 100
                popup.backgroundColor = UIColor.white
                
                // add padding 15 to left and right
               /* let paddingView = UIView(frame: CGRect(x: 0,y: 0,width: 15,height: popup.frame.height))
                popup.leftView = paddingView
                popup.leftViewMode = UITextField.ViewMode.always
                popup.rightView = paddingView
                popup.rightViewMode = UITextField.ViewMode.always*/
                
                // add border
                let myColor : UIColor = UIColor.gray
                popup.layer.borderColor = myColor.cgColor
                popup.layer.borderWidth = 1
                popup.layer.cornerRadius = 10
                //popup.setAlignmentRectInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
                /*popup.addSubview(descLabel)
                popup.addSubview(desc)
                popup.addSubview(latlongLabel)
                popup.addSubview(latlong)
                popup.addSubview(timeNowLabel)
                popup.addSubview(timeNow)
                popup.addSubview(saveBtn)*/
                pdfView.addSubview(popup)
                
                // add speech bubble
                // https://stackoverflow.com/questions/4442126/how-to-draw-a-speech-bubble-on-an-iphone
                

                
            }
        }
    }
    
    @objc func wayptTextClicked(_ textField: UITextField){
        // clicked on popup open edit way pt segue
        if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
        // hide popup with push pin description.
            aPopup.removeFromSuperview()
        }
        // Open EditWayPtViewController
        self.performSegue(withIdentifier: "editWayPt", sender: nil)
        
        //selectedWayPt.contents = textField.text
    }
    
    func addWayPt(x: CGFloat, y: CGFloat, page: PDFPage, imageName: String, desc: String, dateAdded: String?){
        // Create a PushPin
        var dateString: String
        let image = UIImage(named: imageName)
        
        print("width \(pdfWidth * Double(pdfView.scaleFactor))")
        let wayPtSize:CGFloat = 80.0 / CGFloat(pdfView.scaleFactor)
        let halfSize:CGFloat = wayPtSize / 2
        let midX = x - halfSize
        let midY = y - (15  / CGFloat(pdfView.scaleFactor))
        let long = (Double(x)/pdfWidth * longDiff) + long1
        let lat = (Double(y)/pdfHeight * latDiff) + lat1
        let imageAnnotation = PushPin(image, bounds: CGRect(x: midX, y: midY, width: wayPtSize, height: wayPtSize), properties: nil)
        
        page.addAnnotation(imageAnnotation)
        if dateAdded == nil {
            let dateTime = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            dateString = formatter.string(from:dateTime)
        }
        else {
            dateString = dateAdded!
        }
        
        // contents: description, lat/long, time added
        imageAnnotation.contents = "\(desc)$\(String(format: "%.5f", lat)), \(String(format: "%.5f", long))$ \(dateString)$\(imageName)$\(x)$\(y)"
    }
    
    @objc func pdfViewTapped2(_ gestureRecognizer: UITapGestureRecognizer) {
        print("called double tap")
        
        let pdfView = gestureRecognizer.view as! PDFView
        if gestureRecognizer.state == .ended
        {
            if let currentPage = pdfView.currentPage
            {
                let point = gestureRecognizer.location(in: pdfView) // location on screen
                let pdfViewPoint = pdfView.convert(point, to: currentPage) // location on pdf
                var moveX = (1 / (pdfView.scaleFactor * 2.0)) * (pdfView.frame.width / 2.0)
                var moveY = (1 / (pdfView.scaleFactor * 2.0)) * (pdfView.frame.height / 2.0)
                if (moveX < 0){moveX = 0}
                if (moveY < 0){moveY = 0}
                let myPoint:CGPoint = CGPoint(x: pdfViewPoint.x - moveX, y: pdfViewPoint.y + moveY)
                
                let destination = PDFDestination(page: currentPage, at: myPoint)
                let scale = pdfView.scaleFactor * 2.0
                // zoom to full extent
                if (scale >= pdfView.maxScaleFactor) {
                    pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
                    print(pdfView.scaleFactorForSizeToFit)
                }
                else {
                    destination.zoom = (scale)
                    pdfView.scaleFactor = destination.zoom
                    pdfView.go(to: destination)
                }
                
               // print("scaleFactor: \(scale)")
                resizePushPins()
            }
        }
    }
    
    func resizePushPins() {
        let wayPtHeight:CGFloat = 80.0 / CGFloat(pdfView.scaleFactor) // square
        let halfSize = wayPtHeight / 2
        let scale = 1.0 / CGFloat(pdfView.scaleFactor)
        guard let page = pdfView.document?.page(at: 0) else {
            displayError(msg: "Problem reading the PDF map. Can't get page 1.")
            return
        }

        if (page.annotations.count > 0){
            for i in 0...page.annotations.count-1 {
                let pt:PDFAnnotation = page.annotations[i]
                if (pt.type == "Stamp"){
                    let midX = pt.bounds.minX + halfSize
                    let midY = pt.bounds.minY + (15  / CGFloat(pdfView.scaleFactor))
                    print(pt.bounds)
                    
                    pt.bounds = CGRect(x: midX, y: midY, width: wayPtHeight, height: wayPtHeight)
                    print("scale: \(pt.bounds)")
                }
            }
        }
    }
    
  /*  // try NOT WORKING, NOT CALLED
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: pdfView)
            //signingPath = UIBezierPath()
            //signingPath.move(to: pdfView.convert(position, to: pdfView.page(for: position, nearest: true)!))
            //annotationAdded = false
            UIGraphicsBeginImageContext(CGSize(width: 800, height: 600))
            //let lastPoint = pdfView.convert(position, to: pdfView.page(for: position, nearest: true)!)
        }
    }*/
}


/*var counter:Int = 0
// trying to hide menu that pops up on double click once in while. "Look Up Share... Copy Select Send To..."
extension PDFView {
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        print("\(counter) try to turn off PDF menu")
        counter += 1
        return false
    }
}
*/

