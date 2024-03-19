//
//  AppSettings.swift
//  CPWMobilePDF
//
//  Store app wide user preferences
//    - show waypoints?
//    - display menu to load adjacent maps?
//  Created by Tammy Bearly on 3/18/24.
//  Copyright © 2024 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class AppSettings: NSObject, NSSecureCoding {
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    // creates a settings folder in the user's documents folder (for this app) to store all the data
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("settings")
    static var supportsSecureCoding: Bool = true
    
    //MARK: Properties
    var showWaypoints: Bool = true
    var loadAdjMaps: Bool = true
    
    //MARK: Types
    struct PropertyKey {
        static let showWaypoints = "showWaypoints"
        static let loadAdjMaps = "loadAdjMaps"
    }

    required convenience init?(coder aDecoder: NSCoder) {
        // read user settings data via NSCoding
        let showWaypoints = aDecoder.decodeBool(forKey: PropertyKey.showWaypoints)
        let loadAdjMaps = aDecoder.decodeBool(forKey: PropertyKey.loadAdjMaps)
        self.init(showWaypoints: showWaypoints, loadAdjMaps: loadAdjMaps)
    }
    
    // MARK: init read from database
    init(showWaypoints: Bool, loadAdjMaps: Bool){
        self.showWaypoints = showWaypoints
        self.loadAdjMaps = loadAdjMaps
    }
    
    init?(showWaypoints: Bool) {
        // MARK: init import
        super.init()
        self.showWaypoints = showWaypoints
    }
    
    init?(loadAdjMaps: Bool) {
        // MARK: init import
        super.init()
        self.loadAdjMaps = loadAdjMaps
    }
    
    // MARK: NSCoding
    func encode(with coder: NSCoder) {
        // write persistent data
        coder.encode(showWaypoints, forKey: PropertyKey.showWaypoints)
        coder.encode(loadAdjMaps, forKey: PropertyKey.loadAdjMaps)
    }
}
