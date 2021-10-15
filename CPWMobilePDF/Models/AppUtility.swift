//
//  AppUtility.swift
//  MapVieweriOS
//
//  Created by Tammy Bearly on 3/12/21.
//  Copyright © 2021 Colorado Parks and Wildlife. All rights reserved.
//
// Lock phone in portrait or landscape mode for bumpy roads
// https://stackoverflow.com/questions/28938660/how-to-lock-orientation-of-one-view-controller-to-portrait-mode-only-in-swift

import UIKit
struct AppUtility {

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
    
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }

    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
   
        self.lockOrientation(orientation)
    
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

}
