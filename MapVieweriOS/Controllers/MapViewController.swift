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
    var pdfView = PDFView()
    var map:PDFMap?
    var locationManager = CLLocationManager()
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
    var marginXworld:Double = 0.0
    var marginYworld:Double = 0.0
    var latDiff:Double = 0.0
    var longDiff:Double = 0.0
    var pdfWidth:Double = 0.0
    var pdfHeight:Double = 0.0
    var currentLatLong:UITextField = UITextField()
    var debugTxtBox:UITextField = UITextField()
    private var popup:UITextField = UITextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    private var selectedWayPt:PDFAnnotation = PDFAnnotation()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //
        // OPEN PDF & Add pdfView
        //
        
        // Get pdf filename
        //guard let pdfFileURL = Bundle.main.url(forResource: "Wellington1", withExtension: "pdf", subdirectory: "myMaps") else {
        guard var pdfFileName = map?.fileName else {
            fatalError("Filename not readable from selected table row.")
        }
        // Strip off .pdf if it exists
        let index = pdfFileName.firstIndex(of: ".") ?? pdfFileName.endIndex
        pdfFileName = String(pdfFileName[..<index])
        self.title = map?.displayName
        
        guard let pdfFileURL = Bundle.main.url(forResource: pdfFileName, withExtension: "pdf") else {
            print ("PDF file not found.")
            return
        }
        guard  let pdfView = setupPDFView(url: pdfFileURL) else {
            print("Error: PDF not found!");
            return;
        }
        
        
        // text fields at top to display current lat long & debug info
        addCurrentLatLongTextbox()
    //    addDebugTextbox()
  

        
        
        
        
        
        
        
        // try to zoom in
       /* if let page = document.page(at: 0) {
            pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit * 2
            pdfView.go(to: CGRect(x: 0, y: 0, width: 1000, height: 1000), on: page)
        }*/
        
        // Set up double tab zoom in --- Does NOTHING!!!!!
    //pdfView.isUserInteractionEnabled = true // didn't help???
      /* let doubleScreenTap = UITapGestureRecognizer(target: pdfView, action: #selector(zoomIn(_:)))
        doubleScreenTap.numberOfTapsRequired = 2
        doubleScreenTap.numberOfTouchesRequired = 1
        pdfView.addGestureRecognizer(doubleScreenTap)
       */
        
        // scrolling direction for multiple pages
        //pdfView.displayDirection = .vertical
        //pdfView.displayDirection = .horizontal
        
    
        
        
        
        
        // Parse PDF return bounds (lat, long), viewport (margins), mediabox (page size).
        let pdf: [String:Any?] = PDFParser.parse(pdfUrl: pdfFileURL)
        print ("-- RETURNED VALUES --")
        guard let bounds = pdf["bounds"]!! as? [Double] else {
            print("Error: cannot convert bounds to float array")
            return
        }
        print ("lat/long bounds: \(bounds)")
        guard let viewport = pdf["viewport"]!! as? [Float] else{
            print("Error: cannot convert viewport to float array")
            return
        }
        print ("viewport margins: \(viewport)")
        guard let mediabox = pdf["mediabox"]!! as? [Float] else {
            print("Error: cannot convert mediabox to float array")
            return
        }
        print ("mediabox page size: \(mediabox)")
        marginTop = Double(mediabox[3] - viewport[1])
        marginBottom = Double(viewport[3])
        marginLeft = Double(viewport[0])
        marginRight = Double(mediabox[2] - viewport[2])
        mediaBoxWidth = Double(mediabox[2] - mediabox[0])
        mediaBoxHeight = Double(mediabox[3] - mediabox[1])
        marginXworld = Double(marginLeft + marginRight)
        marginYworld = Double(marginTop + marginBottom)
        lat1 = bounds[0]
        long1 = bounds[1]
        lat2 = bounds[2]
        long2 = bounds[5]
        latDiff = (90.0 - lat1) - (90.0 - lat2)
        longDiff = (long2 + 180.0) - (long1 + 180.0)
        // mediaBox is page boundary
        pdfWidth = (mediaBoxWidth - (marginLeft + marginRight)) // don't need * zoom
        pdfHeight = (mediaBoxHeight - (marginTop + marginBottom))
        
        
        // Call location manager
        // Add annotation push pin
        guard let page = pdfView.document?.page(at: 0) else {
            print("Problem reading the PDF. Can't get page 1.")
            return
        }
        //locationManager.delegate=self
        locationManager.desiredAccuracy=kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading() // get azimuth
        self.displayLocation(page: page, pdfView: pdfView) // initial location
        
        // update location every 3 seconds
        //var locTimer: Timer?
        //var lat = 40.69847
        //var long = -105.01303195
        //displayLocation(page: page, pdfView: pdfView, latNow: lat, longNow: long)
        //let locTimer =
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            self.displayLocation(page: page, pdfView: pdfView)
            /*self.displayLocation(page: page, pdfView: pdfView, latNow: lat, longNow: long)
            lat += 0.001
            long += 0.001
            if lat > 41 {
                locTimer?.invalidate() // stop the timer
            }*/
        }
        
        // register touch events
        //let singleScreenTap = UITapGestureRecognizer(target: pdfView, action: #selector(zoomIn(_:)))
        //singleScreenTap.numberOfTapsRequired = 1
        //singleScreenTap.numberOfTouchesRequired = 1
        //pdfView.addGestureRecognizer(singleScreenTap)
        
    }
    
    
    func setupPDFView(url: URL) -> PDFView? {
        let pdfView = PDFView(frame: self.view.bounds);
        guard let document:PDFDocument = PDFDocument(url: url) else{
            return nil
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
        
        /*let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
        pdfView.addGestureRecognizer(pdfDrawingGestureRecognizer)
        pdfDrawingGestureRecognizer.drawingDelegate = pdfDrawer
        pdfDrawer.pdfView = pdfView*/
        return pdfView
    }
    
    
    func addCurrentLatLongTextbox() {
        // Add text box for current location display
        currentLatLong.text = "  Current location: "
        currentLatLong.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
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
    
    
    //func displayLocation(page: PDFPage, pdfView: PDFView, latNow: Double, longNow:Double){
    func displayLocation(page: PDFPage, pdfView: PDFView){
        // Remove last location dot
        page.removeAnnotation(currentLocation) // remove last location dot
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
            currentLatLong.text = "  Current location: Not available"
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

        currentLocation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:cirSize,height:cirSize), forType: .circle, withProperties: nil)
        // fill color
        currentLocation.interiorColor = UIColor.cyan
        // border
        let border = PDFBorder()
        border.lineWidth = 5.0 // border width
        currentLocation.color = UIColor.white // border color
        currentLocation.border = border
        page.addAnnotation(currentLocation)
        
        
        // Margin red dots
        let marginTLAnnotation = PDFAnnotation(bounds: CGRect(x:marginLeft-10, y:mediaBoxHeight - marginTop - 10, width:20,height:20), forType: .circle, withProperties: nil)
        // color
        marginTLAnnotation.interiorColor = UIColor.red
        page.addAnnotation(marginTLAnnotation)
        let marginBRAnnotation = PDFAnnotation(bounds: CGRect(x:mediaBoxWidth - marginRight-10, y:marginBottom-10, width:20,height:20), forType: .circle, withProperties: nil)
        // color
        marginBRAnnotation.interiorColor = UIColor.red
        page.addAnnotation(marginBRAnnotation)
        
        // map lat long boundaries long1,lat1 and long2,lat2 in yellow
        x = (((long1 + 180.0) - (long1 + 180.0)) / longDiff) * pdfWidth
        x = x + marginLeft - 5
        y = (((90.0 - lat1) - (90.0 - lat2)) / latDiff) * pdfHeight
        y = y + marginBottom - 5
        var latlongAnnotation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:10,height:10), forType: .circle, withProperties: nil)
        // color
        latlongAnnotation.interiorColor = UIColor.yellow
        page.addAnnotation(latlongAnnotation)
        // map lat long boundaries long2,lat2
        x = (((long2 + 180) - (long1 + 180)) / longDiff) * pdfWidth
        x = x + marginLeft - 5
        y = (((90.0 - lat2) - (90.0 - lat2)) / latDiff) * pdfHeight
        y = y + marginBottom - 5
        latlongAnnotation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:10,height:10), forType: .circle, withProperties: nil)
        latlongAnnotation.interiorColor = UIColor.yellow
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
    func savePDF(fileName:String){
       let path = Bundle.main.url(forResource: fileName, withExtension: "pdf")
       pdfView.document?.write(to:path!)
    }
    
    
    @objc func pdfViewTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        print("called single tap")
        
        let pdfView = gestureRecognizer.view as! PDFView
        if gestureRecognizer.state == .ended
        {
            if let page = pdfView.currentPage
            {
                let location:CGPoint = gestureRecognizer.location(in: pdfView)
                let pdfViewPoint = pdfView.convert(location, to: page)
                var removingPopup:Bool = false
                
                print ("Scr: \(Int(location.x)), \(Int(location.y))")
                print ("PDF: \(Int(pdfViewPoint.x)), \(Int(pdfViewPoint.y))")
                
                // is popup showing? Did they click on the popup then allow editing
                if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
                
                    if (location.x >= aPopup.bounds.minX &&
                    location.x <= aPopup.bounds.maxX &&
                    location.y >= aPopup.bounds.minY &&
                    location.y <= aPopup.bounds.maxY){
                        print("MinX: \(location.x) < \(aPopup.bounds.minX)")
                        print("MaxX: \(location.x) > \(aPopup.bounds.maxX)")
                        print("clicked on popup \(aPopup.isEditing)")
                        return
                    }
                    // remove old popup
                    else {
                        print("remove popup")
                        removingPopup = true
                        aPopup.removeFromSuperview()
                    }
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
                        print ("add a way point!!!")
                        addWayPt(x: pdfViewPoint.x, y: pdfViewPoint.y, page: page)
                        return
                    }
                    else {
                        print ("off map x \(Int(pdfViewPoint.x)) > width \(Int(pdfView.bounds.width)) or y \(Int(pdfViewPoint.y)) > height  \(Int(pdfView.bounds.height)) or negative")
                        return
                    }
                }
                
                // clicked on existing annotation. Is it a way pt? type stamp?
                if (waypt.type != "Stamp"){
                    // clicked on current location
                    addWayPt(x: pdfViewPoint.x, y: pdfViewPoint.y, page: page)
                    return
                    
                }
                let popupWidth:CGFloat = 200.0
                let popupHeight:CGFloat = 50.0
                print ("way pt height: \(waypt.bounds.maxY - waypt.bounds.minY)")
                
                // calculate pixels to move over to get to mid point in image
                // ratio is used to covert from pdf pt to screen pt
                let ratioX = location.x/pdfViewPoint.x
                let ratioY = location.y/pdfViewPoint.y
                let wayptXMiddle:CGFloat = (waypt.bounds.maxX - waypt.bounds.minX)/2 + waypt.bounds.minX
                let xMove:CGFloat = (pdfViewPoint.x - wayptXMiddle) * ratioX
                let x = location.x - xMove - popupWidth/2
                let yMove:CGFloat = (waypt.bounds.maxY - pdfViewPoint.y) / ratioY
                
                let y = location.y - (yMove + popupHeight)
                print("xRatio:\(ratioX) xscr:\(Int(location.x)) - xmove:\(Int(xMove)) - wd:\(Int(popupWidth/2)) = x:\(Int(x))")
                
                print("yRatio:\(ratioY) yscr:\(Int(location.y)) - ymove:\(Int(yMove)) - ht:\(Int(popupHeight)) = y:\(Int(y))")
                
                popup = UITextField(frame: CGRect(x: x, y: y, width: popupWidth, height: popupHeight))
                selectedWayPt = waypt
                
                // edit text listener
                popup.addTarget(self, action: #selector(MapViewController.wayptTextChanged(_:)), for: UIControl.Event.editingDidEnd)
                
                popup.text = waypt.contents
                popup.tag = 100
                popup.backgroundColor = UIColor.white
                
                // add padding 15 to left and right
                let paddingView = UIView(frame: CGRect(x: 0,y: 0,width: 15,height: popup.frame.height))
                popup.leftView = paddingView
                popup.leftViewMode = UITextField.ViewMode.always
                popup.rightView = paddingView
                popup.rightViewMode = UITextField.ViewMode.always
                
                // add border
                let myColor : UIColor = UIColor.gray
                popup.layer.borderColor = myColor.cgColor
                popup.layer.borderWidth = 1
                popup.layer.cornerRadius = 10
                //popup.setAlignmentRectInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
                
                pdfView.addSubview(popup)
                
                // add speech bubble
                // https://stackoverflow.com/questions/4442126/how-to-draw-a-speech-bubble-on-an-iphone
                

                
            }
        }
    }
    
    @objc func wayptTextChanged(_ textField: UITextField){
        // clicked on a waypt and a popup opened with the contents. When they click somewhere else it closes the popup and calls this function. Update the waypt annomation that was clicked on.//
        selectedWayPt.contents = textField.text
    }
    
    func addWayPt(x: CGFloat, y: CGFloat, page: PDFPage){
        // Create a PushPin
        let image = UIImage(named: "cyan_pin")
        let wayPtSize:CGFloat = 80.0
        let halfSize:CGFloat = 40.0
        let midX = x - halfSize
        let midY = y - 15
        let imageAnnotation = PushPin(image, bounds: CGRect(x: midX, y: midY, width: wayPtSize, height: wayPtSize), properties: nil)
        page.addAnnotation(imageAnnotation)
        imageAnnotation.contents = "way pt at \(Int(midX)), \(Int(midY))"
    }
    
    @objc func pdfViewTapped2(_ gestureRecognizer: UITapGestureRecognizer) {
        print("called double tap")
        
        let pdfView = gestureRecognizer.view as! PDFView
        if gestureRecognizer.state == .ended
        {
            if let currentPage = pdfView.currentPage
            {
                let point = gestureRecognizer.location(in: pdfView)
                let destination = PDFDestination(page: currentPage, at: point)
                let scale = pdfView.scaleFactor * 2.0
                // zoom to full extent
                if (scale >= pdfView.maxScaleFactor) {
                    pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
                    print(pdfView.scaleFactorForSizeToFit)
                    return
                }
                destination.zoom = (scale)
                pdfView.go(to: destination)
                pdfView.scaleFactor = destination.zoom
                //print("scaleFactor: \(scale)")
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

