//
//  PDFParser.swift
//  MapVieweriOS
//
//  Created by Tammy Bearly on 4/17/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//
//  Copyright (c) 2020 Geri Borbás http://www.twitter.com/_eppz
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//https://stackoverflow.com/questions/2475450/extracting-images-from-a-pdf

import PDFKit


class PDFParser
{


    /// Undocumented enumeration case stands for `Object` type (sourced from an expection thrown).
    //static let CGPDFObjectTypeObject: CGPDFObjectType = CGPDFObjectType(rawValue: 77696)!

    /// Shorthand for type strings.
    // For DEBUGGING
    /*static let namesForTypes: [CGPDFObjectType:String] =
    [
        .null : "Null",
        .boolean : "Boolean",
        .integer : "Integer",
        .real : "Real",
        .name : "Name",
        .string : "String",
        .array : "Array",
        .dictionary : "Dictionary",
        .stream : "Stream",
        CGPDFObjectTypeObject : "Object",
    ]

    struct Message
    {
        static let parentNotSerialized = "<PARENT_NOT_SERIALIZED>"
        static let couldNotParseValue = "<COULD_NOT_PARSE_VALUE>"
        static let couldNotGetStreamData = "<COULD_NOT_GET_STREAM_DATA>"
        static let unknownStreamDataFormat = "<UNKNOWN_STREAM_DATA_FORMAT>"
    }

    /// Parse a PDF file into a JSON file.
    static func parse(pdfUrl: URL, into jsonURL: URL)
    {
        do
        {
            let pdf = PDFParser.parse(pdfUrl: pdfUrl)
            let data = try JSONSerialization.data(withJSONObject: pdf, options: .prettyPrinted)
            try data.write(to: jsonURL, options: [])
        }
        catch
        { print(error) }
    }*/
    
    // end  For DEBUGGING

    /// Parse a PDF file into a JSON file.
    static func parse(pdfUrl: URL) -> [String:Any?]
    {
        // Document.
        guard
            let document = CGPDFDocument(pdfUrl as CFURL),
            let page = document.page(at: 1)
        else
        {
            print("Cannot open PDF.")
            return ["error": "CannotOpenPDF"]
        }
        
        // Get PDF version
        var major: Int32 = 0
        var minor: Int32 = 0
         document.getVersion(majorVersion: &major, minorVersion: &minor)
        //print("Version: \(major).\(minor)")
        
        // get media box
        var mediaBox: [CGFloat] = [0.0, 0.0, 0.0, 0.0]
        mediaBox[0] =  page.getBoxRect(CGPDFBox.mediaBox).minX
        mediaBox[1] =  page.getBoxRect(CGPDFBox.mediaBox).minY
        mediaBox[2] =  page.getBoxRect(CGPDFBox.mediaBox).width
        mediaBox[3] =  page.getBoxRect(CGPDFBox.mediaBox).height
        let mediabox: [Float] = [
            Float (mediaBox[0]),
            Float (mediaBox[1]),
            Float (mediaBox[2]),
            Float (mediaBox[3])
        ]
        //print("mediabox = \(mediabox)" )
        
        // get dictionary
        guard let dictionary = page.dictionary else {
            print ("error getting dictionary")
            return ["error": "CannotReadDictionary"]
        }
        
        var bboxValues: [Float] = []
        var gptsValues: [Double] = []
        // GET VP array of dictionaries
        var vp: CGPDFArrayRef?
        if CGPDFDictionaryGetArray(dictionary,"VP",&vp), let vpArray = vp {
            // check for version > 1.5
            if (major == 1 && minor < 6) {
                return ["error": "PDFVersionTooLow"]
            }
            var maxBBoxHt: Float = 0.0
            var measureDicts: [Int : CGPDFDictionaryRef] = [:]
            var id = 0 // the vpArray that has the image with the largest height, ie the map
            // Loop through each dictionary look for BBox<array> and Measure<Dict>GPTS<array>
            for index in 0 ..< CGPDFArrayGetCount(vpArray)
            {
                var eachDictRef: CGPDFDictionaryRef? = nil
                if
                    CGPDFArrayGetDictionary(vpArray, index, &eachDictRef),
                    let eachDict = eachDictRef
                {
                
                    // Get BBox Array
                    var bboxArrayRef: CGPDFArrayRef? = nil
                    if CGPDFDictionaryGetArray(eachDict, "BBox", &bboxArrayRef), let bboxArr = bboxArrayRef {
                        // Get values from BBox Array x1 y1 x2 y2
                        var bboxValue:[CGFloat] = []
                        for i in 0 ..< CGPDFArrayGetCount(bboxArr)
                        {
                            var bboxValueRef: CGPDFReal = 0.0
                            CGPDFArrayGetNumber(bboxArr, i, &bboxValueRef)
                            bboxValue.append(bboxValueRef)
                        }
                        var ht:Float
                        if bboxValue[1] > bboxValue[3] { ht = Float (bboxValue[1] - bboxValue[3]) }
                        else { ht = Float (bboxValue[3] - bboxValue[1]) }
                        if (ht > maxBBoxHt) {
                            maxBBoxHt = ht
                            id = index
                            bboxValues = [Float (bboxValue[0]), Float(bboxValue[1]), Float(bboxValue[2]), Float(bboxValue[3])]
                        }
                        //print ("viewport = \(bboxValues)")
                    }
                    else {
                        return ["error": "CannotReadPDFDictionary"]
                    }
                    
                    // Save the Measure CGPDFDictionaryRefs in an array
                    var measureDictRef: CGPDFDictionaryRef? = nil
                    if CGPDFDictionaryGetDictionary(eachDict, "Measure", &measureDictRef), let measureDict = measureDictRef {
                        measureDicts[index] = measureDict
                        
                    }
                    else {
                        return ["error": "CannotReadPDFDictionary"]
                    }
                }
                else {
                    print("error reading dictionaries in VP dictionary")
                    return ["error": "CannotReadPDFDictionary"]
                }
            }// loop to read each dictionary in VP
            
            // Read gpts lat/long values from the VP array that had the largest viewport bbox height stored in index id
            // Get the lat long from GPTS from the Measure dictionary
            var gptsArrayRef: CGPDFArrayRef? = nil
            if CGPDFDictionaryGetArray(measureDicts[id]!, "GPTS", &gptsArrayRef), let gptsArr = gptsArrayRef {
                // Get values from GPTS Array lat1 long1 lat2 long1 lat2 long2 lat1 long2
                for i in 0 ..< CGPDFArrayGetCount(gptsArr)
                {
                    var gptsValueRef: CGPDFReal = 0.0
                    CGPDFArrayGetNumber(gptsArr, i, &gptsValueRef)
                    gptsValues.append(Double (gptsValueRef)) //.description)
                }
                print ("bounds = \(gptsValues)")
            }
            else {
                return ["error": "CannotReadPDFDictionary"]
            }
            
            // return values here...
            return ["bounds": gptsValues,
                    "mediabox": mediabox,
                    "viewport": bboxValues]
        }
        
        
        // no VP, This is the GeoPDF format
        else {
            var lgiArrayRef: CGPDFArrayRef?
            if CGPDFDictionaryGetArray(dictionary,"LGIDict",&lgiArrayRef), let lgiDictArray = lgiArrayRef {
                var max:Double = 0.0
                var id:Int = 0
                var v1:Double = 0.0
                var v2:Double = 0.0
                var lgiDictRef: CGPDFDictionaryRef? = nil
                // Select LGIDict dictionary with largest vertical area (the map!)
                for i in 0 ..< CGPDFArrayGetCount(lgiDictArray){
                    if CGPDFArrayGetDictionary(lgiDictArray, i, &lgiDictRef), let lgiDictionary1 = lgiDictRef {
                        var neatArrRef: CGPDFArrayRef? = nil
                        if CGPDFDictionaryGetArray(lgiDictionary1, "Neatline", &neatArrRef), let neatArray = neatArrRef {
                            // Get v1, neatArray[1]
                            if CGPDFArrayGetString(neatArray, 1, &neatArrRef), let v1StrRef = neatArrRef {
                                guard let v1CFStr:CFString = CGPDFStringCopyTextString(v1StrRef) else {
                                    return ["error":"UnknownFormat missing Neatline v1"]
                                }
                                let v1double = CFStringGetDoubleValue(v1CFStr)
                                v1 = round(v1double)
                            }
                            else {
                                return ["error":"UnknownFormat missing Neatline v1"]
                            }
                            // Get v2, neatArray[3]
                            if CGPDFArrayGetString(neatArray, 3, &neatArrRef), let v2StrRef = neatArrRef {
                                guard let v2CFStr:CFString = CGPDFStringCopyTextString(v2StrRef) else {
                                    return ["error":"UnknownFormat missing Neatline v2"]
                                }
                                let v2double = CFStringGetDoubleValue(v2CFStr)
                                v2 = round(v2double)
                            }
                            else {
                                return ["error":"UnknownFormat missing Neatline v2"]
                            }
                            if (v1 == v2){
                                // Get v2 as get neatArray[5]
                                if CGPDFArrayGetString(neatArray, 5, &neatArrRef), let v2StrRef = neatArrRef {
                                    guard let v2CFStr:CFString = CGPDFStringCopyTextString(v2StrRef) else {
                                        return ["error":"UnknownFormat missing Neatline v5"]
                                    }
                                    let v2double = CFStringGetDoubleValue(v2CFStr)
                                    v2 = round(v2double)
                                }
                                else {
                                    return ["error":"UnknownFormat missing Neatline v5"]
                                }
                            }
                            if (v1 < v2){
                                let tmp:Double = v1
                                v1 = v2
                                v2 = tmp
                            }
                            let thisMax:Double = v1 - v2
                            if (thisMax > max) {
                                max = thisMax
                                id = i
                            }
                        }
                        else {
                            return ["error":"UnknownFormat missing Neatline"]
                        }
                    }
                    else {
                        return ["error":"UnknownFormat missing Dictionary"]
                    }
                }
                
                // Get dictionary from lgiDictArray[id]
                // working for projection type UTM, unit meters
                if CGPDFArrayGetDictionary(lgiDictArray, id, &lgiDictRef), let lgiDictionary = lgiDictRef {
                    var displayDictRef:CGPDFDictionaryRef? = nil
                    var projTypeRef:CGPDFStringRef? = nil
                    var projUnitsRef:CGPDFStringRef? = nil
                    var projZoneRef:CGPDFReal = 13.0
                    var zone:CGFloat = 13.0
                    // Display dictionary has: ProjectionType, Units, Zone
                    if CGPDFDictionaryGetDictionary(lgiDictionary, "Display", &displayDictRef), let displayDict = displayDictRef {
                        if CGPDFDictionaryGetString(displayDict, "ProjectionType", &projTypeRef), let projTypeRef2 = projTypeRef {
                            guard let CFprojType:CFString = CGPDFStringCopyTextString(projTypeRef2) else {
                                return ["error":"UnknownFormat missing ProjectionType"]
                            }
                            let projType:String = CFprojType as String
                            if projType.lowercased() != "ut" {
                                return ["error":"UnknownFormat missing ProjectionType"]
                            }
                        }
                        else {
                            return ["error":"UnknownFormat missing ProjectionType"]
                        }
                        // check for units in meters "m"
                        if CGPDFDictionaryGetString(displayDict, "Units", &projUnitsRef), let projUnitsRef2 = projUnitsRef {
                            guard let CFunits:CFString = CGPDFStringCopyTextString(projUnitsRef2) else {
                                return ["error":"UnknownFormat missing Units"]
                            }
                            let units:String = CFunits as String
                            if (units.lowercased() != "m"){
                                return ["error":"UnknownFormat Units not in meters"]
                            }
                            // get zone
                            if CGPDFDictionaryGetNumber(displayDict, "Zone", &projZoneRef) {
                                zone = CGFloat(projZoneRef)
                            }
                            else {
                                zone = 13.0
                            }
                        }
                        else {
                            return ["error":"UnknownFormat missing Units"]
                        }
                    }
                    // no Display dictionary. Projection dictionary has: ProjectionType, Units, and Zone
                    else {
                        // check for projectionType of UTM "ut"
                        if CGPDFDictionaryGetDictionary(lgiDictionary, "Projection", &displayDictRef), let projDict = displayDictRef {
                            if CGPDFDictionaryGetString(projDict, "ProjectionType", &projTypeRef), let projTypeRef2 = projTypeRef {
                                guard let CFprojType:CFString = CGPDFStringCopyTextString(projTypeRef2) else {
                                    return ["error":"UnknownFormat missing ProjectionType"]
                                }
                                let projType:String = CFprojType as String
                                if projType.lowercased() != "ut" {
                                    return ["error":"UnknownFormat unknown ProjectionType"]
                                }
                                // check for units in meters "m"
                                if CGPDFDictionaryGetString(projDict, "Units", &projUnitsRef), let projUnitsRef2 = projUnitsRef {
                                    guard let CFunits:CFString = CGPDFStringCopyTextString(projUnitsRef2) else {
                                        return ["error":"UnknownFormat missing Units"]
                                    }
                                    let units:String = CFunits as String
                                    if (units.lowercased() != "m"){
                                        return ["error":"UnknownFormat Units not in meters"]
                                    }
                                    // get zone
                                    if CGPDFDictionaryGetNumber(projDict, "Zone", &projZoneRef) {
                                        zone = CGFloat(projZoneRef)
                                    }
                                    else {
                                        zone = 13.0
                                    }
                                }
                                else {
                                    return ["error":"UnknownFormat missing Units"]
                                }
                            }
                            else {
                                return ["error":"UnknownFormat missing ProjectionType"]
                            }
                        }
                        else {
                            return ["error":"UnknownFormat missing Projection"]
                        }
                    }
                    
                    
                    // Get Viewport
                    // This works for projType == UT (for UTM) units == M for meters
                    var neatlineRef:CGPDFArrayRef? = nil
                    if CGPDFDictionaryGetArray(lgiDictionary, "Neatline", &neatlineRef), let neatArray = neatlineRef {
                        var neatArrRef:CGPDFArrayRef? = nil
                        //var strRef:CGPDFStringRef? = nil
                        var h1:Double, h2:Double, v1:Double, v2:Double
                        
                        if CGPDFArrayGetString(neatArray, 0, &neatArrRef), let strRef = neatArrRef {
                            guard let str:CFString = CGPDFStringCopyTextString(strRef) else {
                                return ["error":"UnknownFormat missing Neatline[0]"]
                            }
                            let myDouble = CFStringGetDoubleValue(str)
                            h1 = round(myDouble)
                        }
                        else {
                            return ["error":"UnknownFormat missing Neatline[0]"]
                        }
                        if CGPDFArrayGetString(neatArray, 1, &neatArrRef), let strRef = neatArrRef {
                            guard let str:CFString = CGPDFStringCopyTextString(strRef) else {
                                return ["error":"UnknownFormat missing Neatline[0]"]
                            }
                            let myDouble = CFStringGetDoubleValue(str)
                            v1 = round(myDouble)
                        }
                        else {
                            return ["error":"UnknownFormat missing Neatline[1]"]
                        }
                        if CGPDFArrayGetString(neatArray, 2, &neatArrRef), let strRef = neatArrRef {
                            guard let str:CFString = CGPDFStringCopyTextString(strRef) else {
                                return ["error":"UnknownFormat missing Neatline[0]"]
                            }
                            let myDouble = CFStringGetDoubleValue(str)
                            h2 = round(myDouble)
                        }
                        else {
                            return ["error":"UnknownFormat missing Neatline[2]"]
                        }
                        if CGPDFArrayGetString(neatArray, 3, &neatArrRef), let strRef = neatArrRef {
                            guard let str:CFString = CGPDFStringCopyTextString(strRef) else {
                                return ["error":"UnknownFormat missing Neatline[0]"]
                            }
                            let myDouble = CFStringGetDoubleValue(str)
                            v2 = round(myDouble)
                        }
                        else {
                            return ["error":"UnknownFormat missing Neatline[3]"]
                        }
                        if (h1 == h2){
                            if CGPDFArrayGetString(neatArray, 4, &neatArrRef), let strRef = neatArrRef {
                                guard let str:CFString = CGPDFStringCopyTextString(strRef) else {
                                    return ["error":"UnknownFormat missing Neatline[0]"]
                                }
                                let myDouble = CFStringGetDoubleValue(str)
                                h2 = round(myDouble)
                            }
                            else {
                                return ["error":"UnknownFormat missing Neatline[4]"]
                            }
                        }
                        if (v1 == v2){
                            if CGPDFArrayGetString(neatArray, 5, &neatArrRef), let strRef = neatArrRef {
                                guard let str:CFString = CGPDFStringCopyTextString(strRef) else {
                                    return ["error":"UnknownFormat missing Neatline[0]"]
                                }
                                let myDouble = CFStringGetDoubleValue(str)
                                v2 = round(myDouble)
                            }
                            else {
                                return ["error":"UnknownFormat missing Neatline[5]"]
                            }
                        }
                        var tmp:Double
                        if (h2 < h1){
                            tmp = h1
                            h1 = h2
                            h2 = tmp
                        }
                        if (v1 < v2){
                            tmp = v1
                            v1 = v2
                            v2 = tmp
                        }
                        bboxValues = [Float (h1), Float(v1), Float(h2), Float(v2)]
                        
                        // Get Latitude/Longitude Bounds lat1 long1 lat2 long1 lat2 long2 lat1 long2
                        // Get CTM dictionary
                        
                        var cmtRef:CGPDFArrayRef? = nil
                        
                        
                        
                        // MARK: DEBUG show catalog of dictionary
                        CGPDFDictionaryApplyFunction(lgiDictionary, { (key, object, info) in
                            NSLog("key = %s",key)
                        }, nil)
                        
                        
                        
                        
                        
                        
                        if CGPDFDictionaryGetArray(lgiDictionary, "CTM", &cmtRef), let cmtArray = cmtRef {
                            var cmtArrRef:CGPDFArrayRef? = nil
                            //var strRef:CGPDFStringRef? = nil
                            var a:Double, H:Double, V:Double, x1:Double, y1:Double, x2:Double, y2:Double
                            // get a = cmtArry[0], scale (x2 - x1) / (h2 - h1)
                            if CGPDFArrayGetString(cmtArray, 0, &cmtArrRef), let strRef = cmtArrRef {
                                guard let str:CFString = CGPDFStringCopyTextString(strRef) else {
                                    return ["error":"UnknownFormat missing CMT[0]"]
                                }
                                a = CFStringGetDoubleValue(str)
                            }
                            else {
                                return ["error":"UnknownFormat missing CMT[0]"]
                            }
                            // get H = cmtArry[4], x1 - a * h1
                            if CGPDFArrayGetString(cmtArray, 4, &cmtArrRef), let strRef = cmtArrRef {
                                guard let str:CFString = CGPDFStringCopyTextString(strRef) else {
                                    return ["error":"UnknownFormat missing CMT[4]"]
                                }
                                H = CFStringGetDoubleValue(str)
                            }
                            else {
                                return ["error":"UnknownFormat missing CMT[4]"]
                            }
                            // get V = cmtArry[5], y1 - a * v1
                            if CGPDFArrayGetString(cmtArray, 5, &cmtArrRef), let strRef = cmtArrRef {
                                guard let str:CFString = CGPDFStringCopyTextString(strRef) else {
                                    return ["error":"UnknownFormat missing CMT[5]"]
                                }
                                V = CFStringGetDoubleValue(str)
                            }
                            else {
                                return ["error":"UnknownFormat missing CMT[5]"]
                            }
                            // in meters!
                            x1 = H + (a * h1)
                            y1 = V + (a * v1)
                            x2 = H + (a * h2)
                            y2 = V + (a * v2)
                            
                            // MARK: TODO add call to utmtoll
                            let latlong1:[Double] = UTMtoLL(f: y1,f1: x1,j: Double(zone))
                            let latlong2:[Double] = UTMtoLL(f: y2,f1: x2,j: Double(zone))
                            print ("a=\(a) H=\(H) V=\(V)")
                            print ("x1=\(x1) y1=\(y1) x2=\(x2) y2=\(y2)")
                            print("\(latlong1[0]), \(latlong1[1])")
                            print("\(latlong2[0]), \(latlong2[1])")
                            gptsValues = [latlong2[1], latlong1[0], latlong1[1], latlong1[0], latlong1[1], latlong2[0]]
                            print ("bounds = \(gptsValues)")
                        }
                        else {
                            return ["error":"UnknownFormat missing CTM"]
                        }
                        
                        
                    }
                    else {
                        return ["error":"UnknownFormat missing Neatline"]
                    }
                }
                else {
                    return ["error":"UnknownFormat missing Dictionary[id]"]
                }
                
                // return values here...
                return ["bounds": gptsValues,
                        "mediabox": mediabox,
                        "viewport": bboxValues]
            }
            else {
                // MEASURE dictionary not found
                return ["error":"UnknownFormat missing MEASURE"]
            }
        }
    }

    
    static func UTMtoLL(f:Double, f1:Double, j:Double) ->[Double] {
        // Convert UTM to Lat Long return [lat, long]
        // UTM=f,f1 Zone=j Colorado is mostly 13 and a little 12
        let d:Double = 0.99960000000000004;
        let d1:Double = 6378137;
        let d2:Double = 0.0066943799999999998;

        let d4:Double = (1 - (1 - d2).squareRoot())/(1 + (1 - d2).squareRoot())
        let d15:Double = f1 - 500000.0
        let d16:Double = f;
        let d11:Double = ((j - 1.0) * 6.0 - 180.0) + 3.0

        let d3:Double = d2/(1 - d2)
        let d10:Double = d16 / d
        let d12:Double = d10 / (d1 * (1 - d2/4 - (3 * d2 * d2)/64 - (5 * pow(d2,3))/256))
        let d14:Double = d12 + ((3*d4)/2 - (27*pow(d4,3))/32) * sin(2*d12) + ((21*d4*d4)/16 - (55 * pow(d4,4))/32) * sin(4*d12) + ((151 * pow(d4,3))/96) * sin(6*d12)
//        let d13:Double = d14 * 180 / Double.pi
        let d5:Double = d1 / (1 - d2 * sin(d14) * sin(d14)).squareRoot()
        let d6:Double = tan(d14) * tan(d14)
        let d7:Double = d3 * cos(d14) * cos(d14)
        let d8:Double = (d1 * (1 - d2))/pow(1-d2*sin(d14)*sin(d14),1.5)

        let d9:Double = d15/(d5 * d)
        var d17:Double = d14 - ((d5 * tan(d14))/d8) * (((d9 * d9)/2-(((5 + 3 * d6 + 10 * d7) - 4 * d7 * d7 - 9 * d3) * pow(d9,4))/24) + (((61 + 90 * d6 + 298 * d7 + (45 * d6) * d6) - 252 * d3 - 3 * d7 * d7) * pow(d9,6))/720)
        d17 = d17 * 180 / Double.pi
        var d18:Double = ((d9 - ((1 + 2 * d6 + d7) * pow(d9,3))/6) + (((((5 - 2 * d7) + 28*d6) - 3 * d7 * d7) + 8 * d3 + 24 * d6 * d6) * pow(d9,5))/120)/cos(d14)
        d18 = d11 + d18 * 180 / Double.pi
        return [d18,d17]
    }
    
    
    
    
    // used for debugging to show values
   /* static func value(from object: CGPDFObjectRef) -> Any?
    {
        switch (CGPDFObjectGetType(object))
        {
            case .null:

                return nil

            case .boolean:

                var valueRef: CGPDFBoolean = 0
                if CGPDFObjectGetValue(object, .boolean, &valueRef)
                { return Bool(valueRef == 0x01) }

            case .integer:

                var valueRef: CGPDFInteger = 0
                if CGPDFObjectGetValue(object, .integer, &valueRef)
                { return valueRef as Int }

            case .real:

                var valueRef: CGPDFReal = 0.0
                if CGPDFObjectGetValue(object, .real, &valueRef)
                { return Double(valueRef) }

            case .name:

                var objectRefOrNil: UnsafePointer<Int8>? = nil
                if
                    CGPDFObjectGetValue(object, .name, &objectRefOrNil),
                    let objectRef = objectRefOrNil,
                    let string = String(cString: objectRef, encoding: String.Encoding.isoLatin1)
                { return string }

            case .string:

                var objectRefOrNil: UnsafePointer<Int8>? = nil
                if
                    CGPDFObjectGetValue(object, .string, &objectRefOrNil),
                    let objectRef = objectRefOrNil,
                    let stringRef = CGPDFStringCopyTextString(OpaquePointer(objectRef))
                { return stringRef as String }

            case .array:

                var arrayRefOrNil: CGPDFArrayRef? = nil
                if
                    CGPDFObjectGetValue(object, .array, &arrayRefOrNil),
                    let arrayRef = arrayRefOrNil
                {
                    var array: [Any] = []
                    for index in 0 ..< CGPDFArrayGetCount(arrayRef)
                    {
                        var eachObjectRef: CGPDFObjectRef? = nil
                        if
                            CGPDFArrayGetObject(arrayRef, index, &eachObjectRef),
                            let eachObject = eachObjectRef,
                            let eachValue = PDFParser.value(from: eachObject)
                        { array.append(eachValue) }
                    }
                    return array
                }

            case .stream:

                var streamRefOrNil: CGPDFStreamRef? = nil
                if
                    CGPDFObjectGetValue(object, .stream, &streamRefOrNil),
                    let streamRef = streamRefOrNil,
                    let streamDictionaryRef = CGPDFStreamGetDictionary(streamRef)
                {
                    // Get stream dictionary.
                    var streamNSMutableDictionary = NSMutableDictionary()
                    Self.collectObjects(from: streamDictionaryRef, into: &streamNSMutableDictionary)
                    var streamDictionary = streamNSMutableDictionary as! [String: Any?]

                    // Get data.
                    var dataString: String? = Message.couldNotGetStreamData
                    var streamDataFormat: CGPDFDataFormat = .raw
                    if let streamData: CFData = CGPDFStreamCopyData(streamRef, &streamDataFormat)
                    {
                        switch streamDataFormat
                        {
                            case .raw: dataString = String(data: NSData(data: streamData as Data) as Data, encoding: String.Encoding.utf8)
                            case .jpegEncoded, .JPEG2000: dataString = NSData(data: streamData as Data).base64EncodedString()
                        @unknown default: dataString = Message.unknownStreamDataFormat
                        }
                    }

                    // Add to dictionary.
                    streamDictionary["Data"] = dataString

                    return streamDictionary
                }

            case .dictionary:

                var dictionaryRefOrNil: CGPDFDictionaryRef? = nil
                if
                    CGPDFObjectGetValue(object, .dictionary, &dictionaryRefOrNil),
                    let dictionaryRef = dictionaryRefOrNil
                {
                    var dictionary = NSMutableDictionary()
                    Self.collectObjects(from: dictionaryRef, into: &dictionary)
                    return dictionary as! [String: Any?]
                }

            case CGPDFObjectTypeObject:

                var dictionary = NSMutableDictionary()
                Self.collectObjects(from: object, into: &dictionary)
                return dictionary as! [String: Any?]

            @unknown default:

                return nil
        }

        // No known case.
        return nil
    }

    static func collectObjects(from dictionaryRef: CGPDFDictionaryRef, into dictionaryPointer: UnsafeMutableRawPointer?)
    {

        CGPDFDictionaryApplyFunction(
            dictionaryRef,
            {
                (eachKeyPointer, eachObject, eachContextOrNil: UnsafeMutableRawPointer?) -> Void in

                // Unwrap dictionary.
                guard let dictionary = eachContextOrNil?.assumingMemoryBound(to: NSMutableDictionary.self).pointee
                else { return print("Could not unwrap dictionary.") }

                // Unwrap key.
                guard let eachKey = String(cString: UnsafePointer<CChar>(eachKeyPointer), encoding: .isoLatin1)
                else { return print("Could not unwrap key.") }

                // Type.
                guard let eachTypeName = PDFParser.namesForTypes[CGPDFObjectGetType(eachObject)]
                else { return print("Could not unwrap type.") }

                // Assemble.
                let eachDictionaryKey = "\(eachKey)<\(eachTypeName)>" as NSString

                // Skip parent.
                guard eachKey != "Parent"
                else
                {
                    dictionary.setObject(Message.parentNotSerialized, forKey: eachDictionaryKey)
                    return
                }

                // Parse value.
                guard let eachValue = PDFParser.value(from: eachObject)
                else
                {
                    dictionary.setObject(Message.couldNotParseValue, forKey: eachDictionaryKey)
                    fatalError("😭")
                    // return
                }

                // Set.
                dictionary.setObject(eachValue, forKey: eachDictionaryKey)
            },
            dictionaryPointer
        )
    }*/
}


