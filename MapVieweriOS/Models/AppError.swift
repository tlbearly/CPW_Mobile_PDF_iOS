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
        // failed to delete the map
        case cannotDelete
        // Cannot rename the map file destination file already exists
        case cannotRename(file: String)
        // cannot rename, new file name already exists
        case fileAlreadyExists(file: String)
        // duplicate name
        case mapNameDuplicate
        // map name cannot be blank
        case mapNameBlank
        // cannot parse pdf dictionary
        case unknownFormat
    }
}
