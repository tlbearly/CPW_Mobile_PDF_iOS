//
//  UIViewControllerPreview.swift
//  CPWMobilePDF
//
//  show preview window Editor/Canvas
//  Created by Tammy Bearly on 1/7/22.
//  Copyright © 2022 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit
#if DEBUG

import SwiftUI

@available(iOS 13.0.0, *)
extension UIViewController {
    private struct Preview: UIViewControllerRepresentable {
        // this var is used for injecting the current view controller
        let viewController: UIViewController
        
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        }
        
        func makeUIViewController(context: Context) -> UIViewController {
            return viewController
        }
        
    }
    func toPreview() -> some View {
        // inject self (the curtrent view controller) for the preview
        Preview(viewController: self)
    }
}
#endif
