//
//  UpdateLocations.swift
//  gps2location
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation
import Utility
import Basic

public class LocationUpdater {
    
    public let sourceURLs: [Foundation.URL]
    public let geocoder: ReverseGeocoder
    public let dryRun: Bool
    public let exiftool: ExiftoolProtocol
    
//    let operationQueue = OperationQueue()
    
    var progressBar: ProgressBarProtocol? = nil
    
    let exifReadQueue = OperationQueue()
    let geocodeQueue = OperationQueue()
    let exifWriteQueue = OperationQueue()
    
    public convenience init(sourceURL: Foundation.URL, geocoder: ReverseGeocoder, exiftool: ExiftoolProtocol, dryRun: Bool) {
        self.init(sourceURLs: [sourceURL], geocoder: geocoder, exiftool: exiftool, dryRun: dryRun)
        
//        self.progressBar = createProgressBar(forStream: stdoutStream, header: "Update")
    }
    
    public init(sourceURLs: [Foundation.URL], geocoder: ReverseGeocoder, exiftool: ExiftoolProtocol, dryRun: Bool) {

        self.sourceURLs = sourceURLs.reduce([]) { (previous, url) in
            
            if let contents = LocationUpdater.dcimContents(at: url) {
                return previous + contents
            } else {
                return previous + [url]
            }
        }
        self.geocoder = geocoder
        self.exiftool = exiftool
        self.dryRun = dryRun
        
    }
    

    func addToQueue(_ urls: [Foundation.URL]) -> [EXIFLocation] {
        self.progressBar = createProgressBar(forStream: stdoutStream, header: "Reading EXIF")

        var locations = [EXIFLocation]()
        let operations = urls.map { url -> ExifReaderOperation in
            let op = ExifReaderOperation(source: url, exiftool: exiftool)
            
            op.completionBlock = {
                locations.append(contentsOf: op.locations)
                
                self.progressBar?.update(percent: urls.count - self.exifReadQueue.operationCount, text: op.source.lastPathComponent)
            }
            
            return op
        }
        
        exifReadQueue.addOperations(operations, waitUntilFinished: true)

        self.progressBar?.complete(success: true)
        
        return locations
    }
    
    func addToQueue(_ locations: [EXIFLocation], waitUntilFinished: Bool) {
        self.progressBar = createProgressBar(forStream: stdoutStream, header: "Reverse Geocoding")
        
        let operations = locations.map { location -> ReverseGeocodeOperation in
            let op = ReverseGeocodeOperation(location: location, geocoder: geocoder)
            
            op.completionBlock  = {
                if let place = op.responseData {
                    self.addToQueue(op.location, place: place)
                }
                
                self.progressBar?.update(percent: locations.count - self.geocodeQueue.operationCount, text: op.location.sourceURL.lastPathComponent)
                
            }
            
            return op
        }

        geocodeQueue.addOperations(operations, waitUntilFinished: true)
        self.progressBar?.complete(success: true)
    }
    
    func addToQueue(_ location: EXIFLocation, place: IPTCLocatable) {
        let operation = ExifWriterOperation(location: location, place: place, exiftool: exiftool)
        
        exifWriteQueue.addOperation(operation)
    }
    
    
    
    public func update(_ completionHandler: @escaping (Int, Int) -> Void) {
        
        let locations = addToQueue(sourceURLs)
        addToQueue(locations, waitUntilFinished: false)
        
        
        
        
        
//        exifReadQueue.
//        let locations: [EXIFLocation] = try sourceURLs.reduce([]) { (previous, url) in
//            return try EXIFLocation.exifLocation(for: url) + previous
//        }
//
//        print("Writing location information")
//        var locationUpdateCount = 0
//
//        operationQueue.qualityOfService = .userInitiated
//        operationQueue.maxConcurrentOperationCount = 1
//
//        let ops = locations.map { location -> Operation in
//            let op = LocationOperation(withLocation: location, geocoder: geocoder) { success in
//                if success {
//                    locationUpdateCount += 1
//                }
//            }
//            op.dryRun = self.dryRun
//            op.completionBlock = {
//
//                if self.operationQueue.operations.isEmpty {
//                    completionHandler(locationUpdateCount, locations.count)
//                }
//            }
//            return op
//        }
//
//        operationQueue.addOperations(ops, waitUntilFinished: false)

    }
    
}

extension LocationUpdater {
    public static func dcimContents(at url: Foundation.URL) -> [Foundation.URL]? {
        var isDir: ObjCBool = false
        
        let dcimURL = url.appendingPathComponent("DCIM")

        FileManager.default.fileExists(atPath: dcimURL.path, isDirectory: &isDir)
        
        if isDir.boolValue {
            NSLog("Reading contents of \(dcimURL.path)")

            let dcimContents = try? FileManager.default.contentsOfDirectory(at: dcimURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

            return dcimContents?.filter { url in
                url.lastPathComponent.range(of: "\\d{3}\\w{5}", options: .regularExpression) != nil
                }

        }
        
        return nil
    }
}
