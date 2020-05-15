//
//  AppError.swift
//  MapVieweriOS
//
//  Created by Tammy Bearly on 5/15/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

class AppError {
    enum pdfMapError: Error {
        case invalidFilename
        case invalidDocumentDirectory
        case notPDF
        
    }
}
