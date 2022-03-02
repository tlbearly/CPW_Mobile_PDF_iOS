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
import os.log

class CellClass:UITableViewCell { }
class MoreMenuCell:UITableViewCell {
    // mark properties
    var label: UITextField = UITextField()
    var checkbox: CheckBox = CheckBox()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.label = UITextField(frame: CGRect(x: 60, y: 0, width: frame.width - 60, height: 52))
        self.addSubview(self.label)
        self.checkbox = CheckBox(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        self.addSubview(self.checkbox)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    // MARK: Variables
    var pdfView:PDFView = PDFView()
    //var map:PDFMap?
    var maps:[PDFMap] = []
    var mapIndex:Int = -1
    var locationManager = CLLocationManager()
    var lockOrientation = false
    let allowBtn = PrimaryUIButton() // turn on location services button
    // make a dummy location dot because displayLocation deletes it first
    var currentLocation: PDFAnnotation = PDFAnnotation(bounds: CGRect(x:0, y:0, width:1,height:1), forType: .circle, withProperties: nil)
    // pdf map boundary in lat/long
    var lat1:Double = 0.0
    var lat2:Double = 0.0
    var long1:Double = 0.0
    var long2:Double = 0.0
    // current location
    var latNow:Double = 0.0
    var longNow:Double = 0.0
    // pdf maps margins
    var marginTop:Double = 0.0
    var marginBottom:Double = 0.0
    var marginLeft:Double = 0.0
    var marginRight:Double = 0.0
    // pdf map size
    var mediaBoxWidth:Double = 0.0
    var mediaBoxHeight:Double = 0.0
    var latDiff:Double = 0.0
    var longDiff:Double = 0.0
    // pdf page size
    var pdfWidth:Double = 0.0
    var pdfHeight:Double = 0.0
    var currentLatLong:UILabel = UILabel()
    var debugTxtBox:UITextField = UITextField()
    private var popup:UITextField = UITextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    private var selectedWayPt:PDFAnnotation = PDFAnnotation()
    var screenWidth:CGFloat = 0.0
    var screenHeight:CGFloat = 0.0
    var addWayPtsFromDatabaseFlag = true
    var addingWayPt = false
    var locationTimer:Timer = Timer()
    
    // more drop down menu
    let moreMenuTransparentView = UIView();
    let moreMenuTableview = UITableView();
    var dataSource = ["Mark current location", "Add waypoint", "Show waypoints", "Hide waypoints", "Delete all waypoints", "Lock in portrait mode", "Lock in landscape mode","Help"]
    var showWaypoints:Bool = true
    var lockInPortrait:Bool = false
    var lockInLandscape:Bool = false
    var moreMenuShowing = false
    var mainMenuRowHeight = 52 //44
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
    
    // must use lazy or the pinBtn doesn't call onClickWayPtPin after edit waypoint
    // UIBarButtonItem won't be instantiated (and the action selectors won't attempt to be resolved) until they are used inside the class. Doing it
    // this way allows you to use the barButtonItems anywhere in the class (not just in the function they are declared in).
    lazy var pinBtn:UIBarButtonItem = UIBarButtonItem(image: (UIImage(named: "grey_pin")), style: .plain, target: self, action: #selector(onClickWayPtPin))
    var notice:UILabel = UILabel()
    var cancelPinBtn = UIBarButtonItem(image: UIImage(named: "nearme"), style: .plain, target: self, action: #selector(onClickCancelWayPtPin))
    let moreBtn = UIBarButtonItem(image: (UIImage(named: "more")), style: .plain, target: self, action: #selector(onClickMore))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // populate more drop down menu
        self.moreMenuTableview.delegate = self
        self.moreMenuTableview.dataSource = self
        self.moreMenuTableview.register(MoreMenuCell.self, forCellReuseIdentifier: "Cell")
        self.moreMenuTableview.reloadData()
        
        self.title = maps[mapIndex].displayName
        screenWidth = self.view.frame.size.width
        screenHeight = self.view.frame.size.height
        
        // set add waypoint button in titlebar to active
        pinBtn.isEnabled = true
        // add more drop down menu button
        self.navigationItem.rightBarButtonItems = [moreBtn, pinBtn]
        
        // set page margins
        marginTop = maps[mapIndex].marginTop
        marginBottom = maps[mapIndex].marginBottom
        marginLeft = maps[mapIndex].marginLeft
        marginRight = maps[mapIndex].marginRight
        
        // set page boundary with margins
        mediaBoxWidth = maps[mapIndex].mediaBoxWidth
        mediaBoxHeight = maps[mapIndex].mediaBoxHeight
        
        // set lat/long boundary in decimal degrees
        lat1 = maps[mapIndex].lat1
        long1 = maps[mapIndex].long1
        lat2 = maps[mapIndex].lat2
        long2 = maps[mapIndex].long2
        latDiff = maps[mapIndex].latDiff
        longDiff = maps[mapIndex].longDiff
        
        // set pdf boundary without margins
        pdfWidth = maps[mapIndex].pdfWidth
        pdfHeight = maps[mapIndex].pdfHeight
        
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
        
        // popup label for instructions for adding a waypoint
        notice.text = "Tap to add waypoint"
        view.addSubview(notice)
        notice.isHidden = true
        // for dark and light mode
        if #available(iOS 13.0, *) {
            notice.backgroundColor = UIColor.systemBackground
        } else {
            // Fallback on earlier versions
            notice.backgroundColor = UIColor.white
        }
        if #available(iOS 13.0, *) {
            notice.textColor = UIColor.label
        } else {
            // Fallback on earlier versions
            notice.textColor = UIColor.black
        }
        notice.textAlignment = .center
        notice.font = UIFont(name: "bold", size: 18.0)
        notice.translatesAutoresizingMaskIntoConstraints = false
        notice.topAnchor.constraint(equalTo: pdfView.topAnchor, constant: 0).isActive = true
        notice.bottomAnchor.constraint(equalTo: pdfView.topAnchor, constant: 50).isActive = true
        notice.widthAnchor.constraint(equalToConstant: 200).isActive = true
        notice.leftAnchor.constraint(equalTo: pdfView.leftAnchor, constant: ((pdfView.frame.width - 200) / 2)).isActive = true
        notice.heightAnchor.constraint(equalToConstant: 50).isActive = true
        notice.layer.cornerRadius = 15
        notice.clipsToBounds = true
        
    }
    
    // set default orientation from database tlb 3/12/21
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lockOrientation = false // preserve orientation
        // lock in landscape or portrait mode to start
        //AppUtility.lockOrientation(.landscapeRight, andRotateTo: .landscapeRight)
        // Or to rotate and lock
         AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop calling displayLocation
        locationTimer.invalidate()
        
        // Don't forget to reset when view is being removed
        // use .all to return to physical device orientation
        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        //AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Add waypoints from maps array that was passed from MapListTableViewController
        if (addWayPtsFromDatabaseFlag){
            addWayPtsFromDatabaseFlag = false
            let nilPt = CGPoint(x: 0, y: 0) // tells addPopup in addWayPt not to show popup.
            guard let page = pdfView.document?.page(at: 0) else {
                displayError(msg: "Problem reading the PDF map. Can't get page 1.")
                return
            }
            if (maps[mapIndex].wayPtArray.count > 0){
                for i in 0...maps[mapIndex].wayPtArray.count-1 {
                    // add padding to desc since textview doesn't use margins
                    addWayPt(x: CGFloat(maps[mapIndex].wayPtArray[i].x), y: CGFloat(maps[mapIndex].wayPtArray[i].y), page: page, imageName: maps[mapIndex].wayPtArray[i].imageName, desc: maps[mapIndex].wayPtArray[i].desc, dateAdded: maps[mapIndex].wayPtArray[i].dateAdded, location: nilPt)
                }
            }
        }
        // Call location manager
        setupLocationServices()
    }
    
    // preserve orientation to phone rotation
    override open var shouldAutorotate: Bool {
        // do not auto rotate
        if (lockOrientation){
            return true
        }
        else{
            return false
        }
    }
    
    // MARK: More Menu
    func addMoreMenuTransparentView(frames:CGRect){
        let window = UIApplication.shared.keyWindow
        let x = 55
        moreMenuTransparentView.frame = window?.frame ?? self.view.frame
        self.view.addSubview(moreMenuTransparentView)
        // hide the menu so it can animate dropping down
        self.moreMenuTableview.frame = CGRect(x: 0, y: 0, width: frames.width, height: 0)
        self.view.addSubview(self.moreMenuTableview)
        self.moreMenuTableview.layer.cornerRadius = 5
        
        moreMenuTransparentView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(removeMoreMenuTransparentView))
        moreMenuTransparentView.addGestureRecognizer(tapgesture)
        moreMenuTransparentView.alpha = 0
       
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.moreMenuTransparentView.alpha = 0.5
            self.moreMenuTableview.frame = CGRect(x: x, y: self.topbarHeight, width: Int(frames.width - CGFloat(x)), height: self.dataSource.count * self.mainMenuRowHeight) //Int(self.moreMenuTableview.rowHeight))
        }, completion: nil)
        //self.moreMenuTableview.autoresizingMask = UIView.AutoresizingMask.flexibleHeight
        //self.moreMenuTableview.bounces = true
        self.moreMenuTableview.reloadData()
        moreMenuShowing = true
    }
    @objc func removeMoreMenuTransparentView(){
        let frames = self.view.frame
        let x = 55
        // remove more button drop down menu view
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.moreMenuTransparentView.alpha = 0.0
            self.moreMenuTableview.frame = CGRect(x: x, y: self.topbarHeight, width: Int(frames.width - CGFloat(x)), height: 0)
        }, completion: nil)
        moreMenuShowing = false
    }
    @objc func onClickMore(_ sender:Any){
        //dataSource = ["Mark current location", "Add waypoint", "Show waypoints", "Hide waypoints", "Delete all waypoints", "Lock in portrait mode", "Lock in landscape mode","Help"]
        if (!moreMenuShowing){
            addMoreMenuTransparentView(frames: self.view.frame)
        }else{
            removeMoreMenuTransparentView()
        }
    }
    @objc func onClickWayPtPin(_ sender:Any){
        removeMoreMenuTransparentView()
        showWaypoints = true
        showWayPts()
        addingWayPt = true
        // set add waypoint button in titlebar to inactive
        pinBtn.isEnabled = false
        // hide any popup
        if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
            aPopup.removeFromSuperview()
        }
        notice.isHidden = false
        self.navigationItem.rightBarButtonItems = [moreBtn, cancelPinBtn]
    }
    @objc func onClickCancelWayPtPin(_ sender:Any){
        removeMoreMenuTransparentView()
        addingWayPt = false
        pinBtn.isEnabled = true
        notice.isHidden = true
        self.navigationItem.rightBarButtonItems = [moreBtn, pinBtn]
    }
    func lockLandscape(){
        // Lock in landscape mode was checked or unchecked
        // if unlocking landscape mode
        if (lockInLandscape){
            lockInLandscape = false
            // if both unlocked orientation should not be locked
            if (lockInPortrait == false){
                lockOrientation = true // should auto rotate?
            }
            return
        }
        // Locking in landscape mode
        lockOrientation = true
        lockInLandscape = true
        lockInPortrait = false
        AppUtility.lockOrientation(.landscapeLeft, andRotateTo: .landscapeLeft)
        //self.navigationItem.rightBarButtonItem = portBtn
    }
    
    @objc func lockPortrait(){
        // if unlocking portrait mode
        if (lockInPortrait){
            lockInPortrait = false
            // if both unlocked orientation should not be locked
            if (lockInLandscape == false){
                lockOrientation = true // should auto rotate?
            }
            return
        }
        // lock in portrait mode
        lockOrientation = true
        lockInLandscape = false
        lockInPortrait = true
        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        //self.navigationItem.rightBarButtonItem = landBtn
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "editWayPt":
            // show Edit waypoint page
            guard let editWayPtVC = segue.destination as? EditWayPtViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            // pass the selected map name, thumbnail, etc to MapViewController.swift
            let wayPt = selectedWayPt.contents
            editWayPtVC.wayPt = wayPt ?? "description$lat, long$date added$blue_pin$0$0"
        case "HelpMapView":
            // pass variables to help map view
            guard let helpMapViewController = segue.destination as? HelpMapViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            // pass the selected map name, thumbnail, etc to HelpMapViewController.swift
            helpMapViewController.maps = maps
            helpMapViewController.mapIndex = mapIndex
        default:
            fatalError("Unexpected Segue Identifier: \(String(describing: segue.identifier))")
        }
    }
    
    @IBAction func performUnwindFromHelpDone(_ sender: UIStoryboardSegue) {
        //print("return to MapViewController")
    }
    
    @IBAction func performUnwindToMapCancel(_ sender: UIStoryboardSegue){
        // print ("return from Edit Waypoint Cancel")
    }
    
    @IBAction func performUnwindToMapDone(_ sender: UIStoryboardSegue) {
        // MARK: WayPt Save
        // Return from waypt edit window. Save button pressed
        guard let editWayPtVC = sender.source as? EditWayPtViewController else {
            fatalError("Unexpected Segue Sender: \(String(describing: sender.source))")
        }
        var desc = editWayPtVC.wayPtDesc.text ?? "Waypoint"
        if (desc == "") {
            desc = "Waypoint"
        }
        guard let page = pdfView.document?.page(at: 0) else {
            displayError(msg: "Problem reading the PDF map. Can't get page 1.")
            return
        }
        // update the push pin color and description
        page.removeAnnotation(selectedWayPt)
        removeWayPt(x: editWayPtVC.x, y: editWayPtVC.y)
        let nilPt = CGPoint(x: 0, y: 0) // tells addPopup in addWayPt not to show popup.
        // add padding to desc since textview doesn't use margins
        addWayPt(x: CGFloat(editWayPtVC.x), y: CGFloat(editWayPtVC.y), page: page, imageName: editWayPtVC.pushPinImg, desc: " " + desc.trimmingCharacters(in: .whitespacesAndNewlines), dateAdded: editWayPtVC.addDate.text, location: nilPt)
    }
    
    @IBAction func performUnwindToMapTrash(_ sender: UIStoryboardSegue) {
        // MARK: WayPt Trash
        // delete selectedWayPt and savePDF
        guard let page = pdfView.document?.page(at: 0) else {
            displayError(msg: "Problem reading the PDF map. Can't get page 1.")
            return
        }
        page.removeAnnotation(selectedWayPt)
        guard let arr:[String] = selectedWayPt.contents?.components(separatedBy: "$") else {
            return
        }
        removeWayPt(x: Float(arr[4])!, y: Float(arr[5])!)
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
            // update location every 5 seconds
            locationTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
                self.displayLocation(page: page, pdfView: self.pdfView)
            }
            
        default:
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading() // get azimuth
            self.displayLocation(page: page, pdfView: self.pdfView) // initial location
            // update location every 5 seconds
            locationTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
                self.displayLocation(page: page, pdfView: self.pdfView)
            }
        }
    }
    
    func setupPDFView() throws {
        // MARK: sertupPDFView
        // Loads the url into a PDFVIew
        
        // check if file exists
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        /*if map == nil {
            throw AppError.pdfMapError.mapNil
        }*/
        
        let url = documentsDir.appendingPathComponent(maps[mapIndex].fileName)
        print("load url maps[\(mapIndex)].fileName = \(maps[mapIndex].fileName)")
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
        //view.addSubview(pdfView)
        //pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        //pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        //pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        //pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        pdfView.autoresizesSubviews = true
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin, .flexibleLeftMargin]
        pdfView.displayDirection = .vertical
        // show only one page of document. true is causing many errors????? Can't zoom in with double click any more when this is uncommented!
        //pdfView.usePageViewController(true)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.enableDataDetectors = false // turn off copy menu
        //pdfView.displaysPageBreaks = true
        pdfView.document = document
        // must be set after pdfView.document
        if #available(iOS 13.0, *) {
            pdfView.backgroundColor = UIColor.systemBackground
        } else {
            // Fallback on earlier versions
            pdfView.backgroundColor = UIColor.lightGray
        }

        // how far can we zoom in?
        pdfView.maxScaleFactor = 8.0
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit // fit in window
        
        // add gestures
        let singleScreenTap = UITapGestureRecognizer(target: self, action: #selector(MapViewController.pdfViewTapped(_:)))
        let doubleScreenTap = UITapGestureRecognizer(target: self, action: #selector(MapViewController.pdfViewTapped2(_:)))
        let pinchScreen = UIPinchGestureRecognizer(target: self, action: #selector(MapViewController.pdfViewPinched(_:)))
        let panScreen = UIPanGestureRecognizer(target: self, action: #selector(MapViewController.pdfViewPanned(_:)))
        
        singleScreenTap.cancelsTouchesInView = false
        doubleScreenTap.cancelsTouchesInView = false
        panScreen.cancelsTouchesInView = false
        pinchScreen.cancelsTouchesInView = false
        
        singleScreenTap.require(toFail: pinchScreen)
        singleScreenTap.require(toFail: panScreen)
        singleScreenTap.require(toFail: doubleScreenTap)
        
        doubleScreenTap.require(toFail: panScreen)
        doubleScreenTap.require(toFail: pinchScreen)
        
        pinchScreen.require(toFail: panScreen)
        
        // Allow pinch and pan, calls self.gestureRecognizer function
        pinchScreen.delegate = self
        panScreen.delegate = self
        singleScreenTap.delegate = self
        
        singleScreenTap.numberOfTapsRequired = 1
        singleScreenTap.numberOfTouchesRequired = 1
        doubleScreenTap.numberOfTapsRequired = 2
        doubleScreenTap.numberOfTouchesRequired = 1
        
        pdfView.isUserInteractionEnabled = true
        
        pdfView.addGestureRecognizer(pinchScreen)
        pdfView.addGestureRecognizer(panScreen)
        pdfView.addGestureRecognizer(singleScreenTap)
        pdfView.addGestureRecognizer(doubleScreenTap)
        
        view.addSubview(pdfView)
        pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    // allow multiple gestures to be recognized, must add UIGestureRecognizerDelegate to class
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: displayError
    func displayError(msg: String){
        let alert = UIAlertController(title: "Unable to View Map", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
        return
    }
    func displayError(msg: String, title: String?){
        let theTitle:String = title ?? "Unable to View Map"
        let alert = UIAlertController(title: theTitle, message: msg, preferredStyle: .alert)
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
    
    // MARK: addCurrentLocationDot
    func addCurrentLocationDot(page: PDFPage){
        // draw current location dot
        let cirSize = 30.0 / Double(pdfView.scaleFactor)
        let halfCirSize:Double = cirSize / 2.0
        var x:Double
        var y:Double
        x = (((longNow + 180.0) - (long1 + 180.0)) / longDiff) * pdfWidth
        x = x + marginLeft - halfCirSize
        y = (((90.0 - latNow) - (90.0 - lat2)) / latDiff) * pdfHeight
        y = (pdfHeight + marginTop - halfCirSize)  - (y)

        // border
        let border = PDFBorder()
        
        // fill color
        // this line crashes in iOS 11.0 PDFAnnotation.setInteriorColor
        if #available(iOS 11.2, *) {
            currentLocation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:cirSize,height:cirSize), forType: .circle, withProperties: nil)
            currentLocation.interiorColor = UIColor.cyan
            border.lineWidth = CGFloat(cirSize) / 6.0 // border width
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
    }
    // MARK: displayLocation
    func displayLocation(page: PDFPage, pdfView: PDFView){
        // DEBUG add lat long boundary dots
        // DEBUG remove margin and lat long circles
        /*if (page.annotations.count > 0){
            for i in stride(from: page.annotations.count-1, to: -1, by: -1) {
                if (page.annotations[i].type == "Circle"){
                    page.removeAnnotation(page.annotations[i])
                    
                }
            }
        }*/
        // DEBUG map lat long boundaries long1,lat1 and long2,lat2 in yellow
        /*var x:Double
        var y:Double
        var latlongAnnotation: PDFAnnotation
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
        
        // map lat long boundaries long1,lat1 in yellow
        x = (((long1 + 180.0) - (long1 + 180.0)) / longDiff) * pdfWidth
        x = x + marginLeft - 5
        y = (((90.0 - lat1) - (90.0 - lat2)) / latDiff) * pdfHeight
        y = y + marginBottom - 5
        latlongAnnotation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:10,height:10), forType: .circle, withProperties: nil)
        // color
        if #available(iOS 11.2, *) {
            latlongAnnotation.interiorColor = UIColor.yellow
        }
        page.addAnnotation(latlongAnnotation)
        
        // map lat long boundaries long2,lat2 in yellow
        x = (((long2 + 180) - (long1 + 180)) / longDiff) * pdfWidth
        x = x + marginLeft - 5
        y = (((90.0 - lat2) - (90.0 - lat2)) / latDiff) * pdfHeight
        y = y + marginBottom - 5
        latlongAnnotation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:10,height:10), forType: .circle, withProperties: nil)
        if #available(iOS 11.2, *) {
            latlongAnnotation.interiorColor = UIColor.yellow
        }
        page.addAnnotation(latlongAnnotation)
        */
        
        
        
        // Update current location
        
        // Remove last location dot
        page.removeAnnotation(currentLocation) // remove last location dot
        
        //var azimuth:Double = -1.0
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
                    //azimuth = heading.magneticHeading
                    //debugTxtBox.text = "orient: \(locationManager.headingOrientation) a=\(azimuth)"
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
        
        // draw current location dot
        addCurrentLocationDot(page:page)
        /*let cirSize = 30.0 / Double(pdfView.scaleFactor)
        let halfCirSize:Double = cirSize / 2.0

        // Add current location dot
        //var x:Double
        //var y:Double
        //var latlongAnnotation
        x = (((longNow + 180.0) - (long1 + 180.0)) / longDiff) * pdfWidth
        x = x + marginLeft - halfCirSize
        y = (((90.0 - latNow) - (90.0 - lat2)) / latDiff) * pdfHeight
        y = (pdfHeight + marginTop - halfCirSize)  - (y)

        // border
        let border = PDFBorder()
        
        // fill color
        // this line crashes in iOS 11.0 PDFAnnotation.setInteriorColor
        if #available(iOS 11.2, *) {
            currentLocation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:cirSize,height:cirSize), forType: .circle, withProperties: nil)
            currentLocation.interiorColor = UIColor.blue
            border.lineWidth = CGFloat(cirSize) / 6.0 // border width
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
         */
        
        // Margin red dots
        /*let marginTLAnnotation = PDFAnnotation(bounds: CGRect(x:marginLeft-10, y:mediaBoxHeight - marginTop - 10, width:20,height:20), forType: .circle, withProperties: nil)
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
        latlongAnnotation = PDFAnnotation(bounds: CGRect(x:x, y:y, width:10,height:10), forType: .circle, withProperties: nil)
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
 */
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
        // Save waypoints to database
        if #available (iOS 11.0,*){
            //'archiveRootObject(_:toFile:)' was deprecated in iOS 12.0: Use +archivedDataWithRootObject:requiringSecureCoding:error: and -writeToURL:options:error: instead
            do {
                let dataToBeArchived = try NSKeyedArchiver.archivedData(withRootObject: maps, requiringSecureCoding: false)
                try dataToBeArchived.write(to: PDFMap.ArchiveURL)
                //os_log("Maps successfully saved.", log: OSLog.default, type: .debug)
            } catch {
                displayError(msg: "Failed to save waypoints.")
            }
        }
        // older than iOS 11 depricated
        else{
            let isSuccessfullSave = NSKeyedArchiver.archiveRootObject(maps, toFile: PDFMap.ArchiveURL.path)
            if isSuccessfullSave {
                //os_log("Maps successfully saved.", log: OSLog.default, type: .debug)
            }
            else {
                os_log("Failed to save maps.", log: OSLog.default, type: .error)
                displayError(msg: "Failed to save waypoints.")
            }
        }
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
            displayError(msg: "Problem reading the PDF. Can't get page 1")
            return
        }
        self.displayLocation(page: page, pdfView: self.pdfView) // initial location
        // update location every 5 seconds
        locationTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            self.displayLocation(page: page, pdfView: self.pdfView)
        }
    }
    
    func getWayPtLabel(page: PDFPage) -> String {
        var count:Int = 1
        if (page.annotations.count > 0){
            for i in 0...page.annotations.count-1 {
                if page.annotations[i].type == "Stamp" {
                    count+=1
                }
            }
        }
        let desc = " Waypoint \(count)"
        return desc
    }
    
    func addPopup(waypt: PDFAnnotation, pdfViewPoint: CGPoint, location: CGPoint, page: PDFPage) {
        // MARK: addPopup
        // Display popup bubble
        selectedWayPt = waypt
        
        let popupWidth:CGFloat = 150
        let popupHeight:CGFloat = 50
        
        // calculate pixels to move over to get to mid point in image
        // ratio is used to covert from pdf pt to screen pt
        let ratioX = location.x/pdfViewPoint.x
        //let ratioY = location.y/pdfViewPoint.y
        let wayptXMiddle:CGFloat = (waypt.bounds.maxX - waypt.bounds.minX)/2 + waypt.bounds.minX
        let xMove:CGFloat = (pdfViewPoint.x - wayptXMiddle) * ratioX
        var x = location.x - xMove - popupWidth/2
        if (x < 1) {
            x = 1
        }
        else if (x + popupWidth > screenWidth){
            x = screenWidth - popupWidth
        }
                
        popup = UITextField(frame: CGRect(x: x, y: location.y+20, width: popupWidth, height: popupHeight))
        let rightImgView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 90.0))
        rightImgView.image = UIImage(named: "arrow_right_circle")
        rightImgView.contentMode = .scaleAspectFit
        popup.rightView = rightImgView
        popup.rightViewMode = .always
        
        // edit text listener
        popup.addTarget(self, action: #selector(MapViewController.wayptTextClicked(_:)), for: UIControl.Event.touchDown)
        guard let items = waypt.contents?.components(separatedBy: "$") else {
            print("empty waypt contents, clicked on current location???")
            //displayError(msg: "Trying to display waypoint popup but contents are empty!")
            return
        }
        
        // add padding
        popup.text = " " + items[0]
        
        // give it a tag so we will know if this popup was clicked on
        popup.tag = 100
        if #available(iOS 13.0, *) {
            popup.backgroundColor = UIColor.systemBackground
        } else {
            // Fallback on earlier versions
            popup.backgroundColor = UIColor.white
        }
        if #available(iOS 13.0, *) {
            popup.textColor = UIColor.label
        } else {
            // Fallback on earlier versions
            popup.textColor = UIColor.black
        }
        
        // add border
        let myColor : UIColor = UIColor.gray
        popup.layer.borderColor = myColor.cgColor
        popup.layer.borderWidth = 1
        popup.layer.cornerRadius = 10
        pdfView.addSubview(popup)
    }
        
    @objc func wayptTextClicked(_ textField: UITextField){
        // clicked on popup open edit way pt segue
        if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
        // hide popup with push pin description.
            aPopup.removeFromSuperview()
        }
        // Open EditWayPtViewController
        self.performSegue(withIdentifier: "editWayPt", sender: nil)
    }
    
    func addWayPt(x: CGFloat, y: CGFloat, page: PDFPage, imageName: String, desc: String, dateAdded: String?, location: CGPoint){
        self.navigationItem.rightBarButtonItems = [moreBtn, pinBtn]
        if (addingWayPt){
            pinBtn.isEnabled = true
            addingWayPt = false // flag to ignor taps unless add waypoint was selected from the menu
        }
        // Create a PushPin
        var dateString: String
        let image = UIImage(named: imageName)
        
        //print("width \(pdfWidth * Double(pdfView.scaleFactor))")
        //print("desc \(desc)")
        let wayPtSize:CGFloat = 80.0 / CGFloat(pdfView.scaleFactor)
        let halfSize:CGFloat = wayPtSize / 2
        let midX = x - halfSize
        let midY = y - (15.0  / CGFloat(pdfView.scaleFactor))
        
        
        
        // MARK: TODO add page margin left and top
        //print ("x=\(round(x)) y=\(round(y))")
        //let marginL = CGFloat(marginLeft) * pdfView.scaleFactor
        //let marginT = CGFloat(marginTop) * pdfView.scaleFactor
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
        let pdfViewPoint = CGPoint(x: x,y: y)
        if (location.x != 0 && location.y != 0) {
            addPopup(waypt: imageAnnotation, pdfViewPoint: pdfViewPoint,location: location, page: page)
        }
        
        // if not already in database, add it
        var found = false
        if (maps[mapIndex].wayPtArray.count > 0){
            for i in 0...maps[mapIndex].wayPtArray.count-1 {
                if (Int(maps[mapIndex].wayPtArray[i].x) == Int(x) &&
                        Int(maps[mapIndex].wayPtArray[i].y) == Int(y)){
                    found = true
                    break
                }
            }
        }
        // not already in database, savePDF adds it
        if (!found){
            let wayPt = WayPt(x: Float(x), y: Float(y), imageName: imageName, desc: desc, dateAdded: dateString)
            maps[mapIndex].wayPtArray.append(wayPt)
            savePDF()
        }
    }
    
    func removeAllWayPoints(){
        // Remove all waypoints from pdf annotation and database
        print("total way pts = \(maps[mapIndex].wayPtArray.count)")
        var i:Int
        while (maps[mapIndex].wayPtArray.count > 0){
            i = maps[mapIndex].wayPtArray.count - 1
            maps[mapIndex].wayPtArray.remove(at: i)
            print("removing way pt \(i)")
        }
        // Remove popup
        if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
            // popup is showing and removing all waypoints.
            aPopup.removeFromSuperview()
        }
        // save these changes in the database
        savePDF()
        hideWayPts() // update pdf annotations
    }
    
    func removeWayPt(x:Float, y:Float){
        // Updated waypoint remove it so can update and add it again
        if (maps[mapIndex].wayPtArray.count > 0){
            for i in 0...maps[mapIndex].wayPtArray.count-1 {
                if (Int(maps[mapIndex].wayPtArray[i].x) == Int(x) &&
                        Int(maps[mapIndex].wayPtArray[i].y) == Int(y)){
                    maps[mapIndex].wayPtArray.remove(at: i)
                    break
                }
            }
        }
        // save these changes in the database
        savePDF()
    }
    
    // MARK: Gestures
    @objc func pdfViewTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        // MARK: pdfViewTap
        // Check if clicked on Waypoint or add new waypoint annotation
        print("called single tap")
        let pdfView = gestureRecognizer.view as! PDFView
        pdfView.clearSelection() // remove selected text!!!
        if gestureRecognizer.state == .ended
        {
            if let page = pdfView.currentPage
            {
                let location:CGPoint = gestureRecognizer.location(in: pdfView) // location on screen
                let pdfViewPoint = pdfView.convert(location, to: page) // location on pdf
                var removingPopup:Bool = false
                
                //print ("Scr: \(Int(location.x)), \(Int(location.y))")
                //print ("PDF: \(Int(pdfViewPoint.x)), \(Int(pdfViewPoint.y))")
                
                // is popup showing? Did they click on the popup then allow editing
                if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
                    // popup is showing and did not click on popup, hide it.
                    removingPopup = true
                    aPopup.removeFromSuperview()
                }
                                
                // clicked on waypoint annotation?
                guard let waypt = page.annotation(at: pdfViewPoint) else {
                    if removingPopup {
                        return
                    }
                    
                    // ADD A WAYPOINT
                    // make sure it is on the map
                    if (pdfViewPoint.x>CGFloat(marginLeft) && pdfViewPoint.y>CGFloat(marginBottom) &&
                        pdfViewPoint.x<CGFloat(mediaBoxWidth - marginRight) &&
                        pdfViewPoint.y<CGFloat(mediaBoxHeight - marginTop) && addingWayPt){
                        notice.isHidden = true
                        addWayPt(x: pdfViewPoint.x, y: pdfViewPoint.y, page: page, imageName: "blue_pin", desc: getWayPtLabel(page: page), dateAdded: nil,location: location)
                        return
                    }
                    // Display off map message for 1 second
                    else {
                        if (!addingWayPt) {return}
                        //print ("off map x \(Int(pdfViewPoint.x)) > width \(Int(pdfView.bounds.width)) or y \(Int(pdfViewPoint.y)) > height  \(Int(pdfView.bounds.height)) or negative")
                        let alert = UIAlertController(title: "Off Map", message: "", preferredStyle: .alert)
                        self.present(alert, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                            alert.dismiss(animated: true)
                        }
                        return
                    }
                }
                
                // clicked on existing annotation. Is it a waypoint? type stamp?
                if (waypt.type != "Stamp" && addingWayPt){
                    // clicked on current location
                    addWayPt(x: pdfViewPoint.x, y: pdfViewPoint.y, page: page, imageName: "red_pin", desc: getWayPtLabel(page: page), dateAdded: nil, location: location)
                    return
                }
                // clicked on existing annotation.
                if (waypt.type == "Stamp"){
                    // fixed bug: -canOpenURL: failed for URL: "tel:..." by making sure it is not a link.
                    addPopup(waypt: waypt,pdfViewPoint: pdfViewPoint,location: location, page: page)
                }
            }
        }
    }

    @objc func pdfViewPinched(_ gestureRecognizer: UIPinchGestureRecognizer){
        //print ("pinch")
        if gestureRecognizer.state == .began {
            // is popup showing? Hide it
            if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
                // popup is showing hide it.
                aPopup.removeFromSuperview()
            }
        }
        else if gestureRecognizer.state == .ended
        {
            resizePushPins()
        }
    }
    
    @objc func pdfViewPanned(_ gestureRecognizer: UIPanGestureRecognizer){
        //print ("panning")
        if gestureRecognizer.state == .began {
            // is popup showing? Hide it
            if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
                // popup is showing hide it.
                aPopup.removeFromSuperview()
            }
        }
        else if gestureRecognizer.state == .ended
        {
            resizePushPins()
        }
    }
    
    @objc func pdfViewTapped2(_ gestureRecognizer: UITapGestureRecognizer) {
        // double tap
        //print("double tap")
        
        let pdfView = gestureRecognizer.view as! PDFView
        if gestureRecognizer.state == .ended
        {
            if let currentPage = pdfView.currentPage
            {
                // is popup showing? Did they click on the popup then allow editing
                if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
                    // popup is showing hide it.
                    aPopup.removeFromSuperview()
                }
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
                }
                else {
                    destination.zoom = (scale)
                    pdfView.scaleFactor = destination.zoom
                    pdfView.go(to: destination)
                }
                
                resizePushPins()
            }
        }
    }
    
    func markCurrentLocation(){
        if (currentLatLong.text != "  Current location: \(latNow), \(longNow)"){
            displayError(msg: "Current location not on map", title:"Notice")
            return
        }
        guard let page = pdfView.document?.page(at: 0) else {
            displayError(msg: "Problem reading the PDF map. Cannot add waypoint.", title:"Notice")
            return
        }
        // get pdf point
        var x:Double = (((longNow + 180.0) - (long1 + 180.0)) / longDiff) * pdfWidth
        var y:Double = (((90.0 - latNow) - (90.0 - lat2)) / latDiff) * pdfHeight
        x = x + marginLeft
        y = (pdfHeight + marginTop)  - y
        
        // Move to show current location in center
        var moveX = (1 / (pdfView.scaleFactor)) * (pdfView.frame.width / 2.0)
        var moveY = (1 / (pdfView.scaleFactor)) * (pdfView.frame.height / 2.0)
        if (moveX < 0){moveX = 0}
        if (moveY < 0){moveY = 0}
        let myPoint:CGPoint = CGPoint(x: CGFloat(x) - moveX, y: CGFloat(y) + moveY)
        let destination = PDFDestination(page: page, at: myPoint)
        pdfView.go(to: destination)
        
        // Get screen point
        let pdfPoint = CGPoint(x: x, y: y)
        let location:CGPoint = pdfView.convert(pdfPoint, from: page)
        addWayPt(x: CGFloat(x), y: CGFloat(y), page: page, imageName: "red_pin", desc: getWayPtLabel(page: page), dateAdded: nil, location: location)
    }
    func hideWayPts(){
        // hide all waypoints
        guard let page = pdfView.document?.page(at: 0) else {
            displayError(msg: "Problem reading the PDF map. Can't get page 1.")
            return
        }
        if (page.annotations.count > 1){
            while (page.annotations.count > 1) {
                var i = page.annotations.count-1
                let pt:PDFAnnotation = page.annotations[i]
                //remove waypoint pin
                if (pt.type == "Stamp"){
                    page.removeAnnotation(page.annotations[i])
                }
                else if (pt.type == "Circle"){
                    i = i - 1
                    if (i > -1){
                        page.removeAnnotation(page.annotations[i])
                    }
                }
            }
        }
            // Remove the last one if it is not the current location
        if (page.annotations.count == 1 && page.annotations[0].type == "Stamp"){
            page.removeAnnotation(page.annotations[0])
        }
        
    }
    
    func showHideWayPts(){
        // toggle show / hide waypoints
        if (showWaypoints){
            showWaypoints = false
            hideWayPts()
        } else {
            showWaypoints = true
            showWayPts()
            resizePushPins()
        }
    }
    func showWayPts(){
        // show all waypoints menu item
        guard let page = pdfView.document?.page(at: 0) else {
            displayError(msg: "Problem reading the PDF map. Can't get page 1.")
            return
        }
        // remove all annotations
        hideWayPts()
    
        // show waypoints
        let nilPt = CGPoint(x: 0, y: 0) // tells addPopup in addWayPt not to show popup.
        if (maps[mapIndex].wayPtArray.count > 0){
            for i in 0...maps[mapIndex].wayPtArray.count-1 {
                // add padding to desc since textview doesn't use margins
                addWayPt(x: CGFloat(maps[mapIndex].wayPtArray[i].x), y: CGFloat(maps[mapIndex].wayPtArray[i].y), page: page, imageName: maps[mapIndex].wayPtArray[i].imageName, desc: maps[mapIndex].wayPtArray[i].desc, dateAdded: maps[mapIndex].wayPtArray[i].dateAdded, location: nilPt)
            }
        }
    }
    func resizePushPins() {
        // When zoom in or out resize push pins and current location marker
        let wayPtHeight:CGFloat = 80.0 / CGFloat(pdfView.scaleFactor) // square
        let halfSize:CGFloat = wayPtHeight / 2.0
        //let scale = 1.0 / CGFloat(pdfView.scaleFactor)
        guard let page = pdfView.document?.page(at: 0) else {
            displayError(msg: "Problem reading the PDF map. Can't get page 1.")
            return
        }

        // Remove last location dot
        page.removeAnnotation(currentLocation)
        // resize current location dot
        addCurrentLocationDot(page:page)
        
        if (page.annotations.count > 0){
            for i in 0...page.annotations.count-1 {
                let pt:PDFAnnotation = page.annotations[i]
                if (pt.type == "Stamp"){
                    // get lat long from contents and convert to screen coordinates locX, locY
                    guard let items:[String] = pt.contents?.components(separatedBy: "$") else {
                        displayError(msg: "Waypoint is missing lat long value. Cannot resize.")
                        return
                    }
                    let latlong = items[1].components(separatedBy: ",")
                    let latStr = latlong[0].trimmingCharacters(in: .whitespaces)
                    let longStr = latlong[1].trimmingCharacters(in: .whitespaces)
                    guard let long:Double = Double(longStr) else {
                        displayError(msg: "Problem reading longitude of waypoint.")
                        return
                    }
                    let locX = CGFloat(((long - long1) / longDiff) * pdfWidth)
                    guard let lat:Double = Double(latStr) else {
                        displayError(msg: "Problem reading latitude of waypoint.")
                        return
                    }
                    let locY = CGFloat(((lat - lat1) / latDiff) * pdfHeight)
                    
                    // the locX, locY is the point at the base of the push pin
                    // now calculate the x,y at the bottom left of the image rectangle
                    let minX = locX - halfSize
                    let minY = locY - (15.0  / CGFloat(pdfView.scaleFactor))
                    pt.bounds = CGRect(x: minX, y: minY, width: wayPtHeight, height: wayPtHeight)
                }
            }
        }
    }
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

extension MapViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MoreMenuCell
        //cell.textLabel?.text = dataSource[indexPath.row]
        cell.label.text = dataSource[indexPath.row]
        switch cell.label.text {
            case "Show waypoints":
                cell.checkbox.isChecked = showWaypoints
                cell.checkbox.isHidden = false
            case "Lock in portrait mode":
                cell.checkbox.isChecked = lockInPortrait
                cell.checkbox.isHidden = false
            case "Lock in landscape mode":
                cell.checkbox.isChecked = lockInLandscape
                cell.checkbox.isHidden = false
            default:
                cell.checkbox.isHidden = true
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(mainMenuRowHeight) // tableView.rowHeight // 50
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (dataSource[indexPath.row] == "Lock in landscape mode"){
            lockLandscape()
            removeMoreMenuTransparentView()
            resizePushPins()
        }
        else if (dataSource[indexPath.row] == "Lock in portrait mode"){
            lockPortrait()
            removeMoreMenuTransparentView()
            resizePushPins()
        }
        else if (dataSource[indexPath.row] == "Add waypoint"){
            showWaypoints = true
            showWayPts()
            addingWayPt = true
            pinBtn.isEnabled = false
            self.navigationItem.rightBarButtonItems = [moreBtn, cancelPinBtn]
            // hide any popups
            if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
                aPopup.removeFromSuperview()
            }
            // reset left anchor of notice, because it may have rotated and is not centered
            //TODO: not working!!!!!!!
            //notice.leftAnchor.constraint(equalTo: pdfView.leftAnchor, constant: ((pdfView.frame.width - 200) / 2)).isActive = true
            notice.isHidden = false
            removeMoreMenuTransparentView()
        }
        else if (dataSource[indexPath.row] == "Mark current location"){
            // hide any popup
            if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
                aPopup.removeFromSuperview()
            }
            showWaypoints = true
            showWayPts()
            addingWayPt = true
            markCurrentLocation()
            removeMoreMenuTransparentView()
        }
        else if (dataSource[indexPath.row] == "Hide waypoints"){
            // hide any popup
            if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
                aPopup.removeFromSuperview()
            }
            hideWayPts()
            removeMoreMenuTransparentView()
        }
        else if (dataSource[indexPath.row] == "Show waypoints"){
            showHideWayPts()
            // hide any popup
            if let aPopup: UITextField = pdfView.viewWithTag(100) as? UITextField {
                aPopup.removeFromSuperview()
            }
            removeMoreMenuTransparentView()
        }
        else if (dataSource[indexPath.row] == "Delete all waypoints"){
            removeAllWayPoints()
            removeMoreMenuTransparentView()
        }
        else if (dataSource[indexPath.row] == "Help"){
            // show help
            removeMoreMenuTransparentView()
            // Open HelpMapViewController
            self.performSegue(withIdentifier: "HelpMapView", sender: nil)
        }
    }
}
