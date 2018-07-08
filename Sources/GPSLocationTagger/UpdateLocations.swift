//
//  UpdateLocations.swift
//  gps2location
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation

public struct LocationUpdater {
    
    public let sourceURLs: [URL]
    public let geocoder: ReverseGeocoder
    
    let operationQueue = OperationQueue()
    
    public init(sourceURL: URL, geocoder: ReverseGeocoder) {
        self.init(sourceURLs: [sourceURL], geocoder: geocoder)
    }
    
    public init(sourceURLs: [URL], geocoder: ReverseGeocoder) {

        self.sourceURLs = sourceURLs.reduce([]) { (previous, url) in
            
            if let contents = LocationUpdater.dcimContents(at: url) {
                return previous + contents
            } else {
                return previous + [url]
            }
        }
        self.geocoder = geocoder
    }
    
    public func update(_ completionHandler: @escaping (Int, Int) -> Void) throws {
        let locations: [EXIFLocation] = try sourceURLs.reduce([]) { (previous, url) in
            return try EXIFLocation.exifLocation(for: url) + previous
        }

        print("Writing location information")
        var locationUpdateCount = 0
        
        operationQueue.qualityOfService = .userInitiated
        operationQueue.maxConcurrentOperationCount = 1

        let ops = locations.map { location -> Operation in
            let op = LocationOperation(withLocation: location, geocoder: geocoder) { success in
                if success {
                    locationUpdateCount += 1
                }
            }

            op.completionBlock = {

                if self.operationQueue.operations.isEmpty {
                    completionHandler(locationUpdateCount, locations.count)
                }
            }
            return op
        }

        operationQueue.addOperations(ops, waitUntilFinished: false)

    }
    
}

extension LocationUpdater {
    public static func dcimContents(at url: URL) -> [URL]? {
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
