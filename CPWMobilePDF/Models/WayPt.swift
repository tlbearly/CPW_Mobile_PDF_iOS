//
//  WayPt.swift
//  MapVieweriOS
//
//  Created by Tammy Bearly on 11/12/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//
// v1.0.6 add ns secure coding

import UIKit
import os.log

class WayPt: NSObject, NSSecureCoding {
    // 8-21-23 add secure coding
    static var supportsSecureCoding: Bool = true
    //MARK: Properties
    var x:Float = 0.0
    var y:Float = 0.0
    var imageName:String = "cyan_pin"
    var desc:String = "description"
    var dateAdded:String = "date added"
    
    // MARK: init read from database
    init(x: Float, y: Float, imageName: String, desc: String, dateAdded: String){
        self.x = x
        self.y = y
        self.imageName = imageName
        self.desc = desc
        self.dateAdded = dateAdded
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(x, forKey: "x")
        coder.encode(y, forKey: "y")
        coder.encode(imageName, forKey: "imageName")
        coder.encode(desc, forKey: "desc")
        coder.encode(dateAdded, forKey: "dateAdded")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let x = aDecoder.decodeFloat(forKey: "x")
        let y = aDecoder.decodeFloat(forKey: "y")
        guard let imageName = aDecoder.decodeObject(forKey: "imageName") as? String else { os_log("Unable to decode the waypoint image name.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let desc = aDecoder.decodeObject(forKey: "desc") as? String else { os_log("Unable to decode the waypoint description.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let dateAdded = aDecoder.decodeObject(forKey: "dateAdded") as? String else { os_log("Unable to decode the waypoint date added.", log: OSLog.default, type: .debug)
            return nil
        }
        
        // Must call designated initializer.
        self.init(x: x, y: y, imageName: imageName, desc: desc, dateAdded: dateAdded)
    }
}
