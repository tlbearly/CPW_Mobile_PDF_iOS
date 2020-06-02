//
//  AppError.swift
//  MapVieweriOS
//
//  Created by Tammy Bearly on 5/15/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

class AppError {
    enum pdfMapError: Error {
        // nil or empty filename
        case invalidFilename
        // apps documents directory not found or excessable
        case invalidDocumentDirectory
        // file does not have .pdf extension
        case notPDF
        // file not found
        case pdfFileNotFound(file: String)
        // map is nil
        case mapNil
        // cannot open pdf for parsing
        case cannotOpenPDF
        // must be 1.6 or greater or geoPDF
        case pdfVersionTooLow
        // cannot parse pdf dictionary
        case cannotReadPDFDictionary
        // cannot parse pdf dictionary
        case unknownFormat
    }
}
