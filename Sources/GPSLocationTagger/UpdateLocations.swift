//
//  UpdateLocations.swift
//  gps2location
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation

public struct LocationUpdater {
    
    public let sourceURLs: [URL]
    let operationQueue = OperationQueue()
    
    public init(sourceURL: URL) {
        self.init(sourceURLs: [sourceURL])
    }
    
    public init(sourceURLs: [URL]) {
        
        self.sourceURLs = sourceURLs.reduce([]) { (previous, url) in
            
            if let contents = LocationUpdater.dcimContents(at: url) {
                return previous + contents
            } else {
                return previous + [url]
            }
        }
    }
    
    public func update(_ completionHandler: @escaping () -> Void) throws {
        let locations: [EXIFLocation] = try sourceURLs.reduce([]) { (previous, url) in
            return try EXIFLocation.exifLocation(for: url) + previous
        }

        print("Writing location information")
        
        operationQueue.qualityOfService = .userInitiated
        operationQueue.maxConcurrentOperationCount = 1

        let ops = locations.map { location -> Operation in
            let op = LocationOperation(withLocation: location)

            op.completionBlock = {

                if self.operationQueue.operations.isEmpty {
                    completionHandler()
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
            let dcimContents = try? FileManager.default.contentsOfDirectory(atPath: dcimURL.path)
            
            return dcimContents?.filter { name in
                name.range(of: "\\d{3}\\w{5}", options: .regularExpression) != nil
                }.map { name in
                    dcimURL.appendingPathComponent(name)
                }

        }
        
        return nil
    }
}
