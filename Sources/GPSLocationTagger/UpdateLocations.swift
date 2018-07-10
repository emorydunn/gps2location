//
//  UpdateLocations.swift
//  gps2location
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation

public class LocationUpdater {
    
    public let sourceURLs: [Foundation.URL]
    
    public let geocoder: ReverseGeocoder
    public let exiftool: ExiftoolProtocol
    
    public let dryRun: Bool

    /// Unique image URLs
    var exifLocations = Set<Foundation.URL>()
    
    /// Count of locations written successfully
    var succusfulExifLocations = Set<Foundation.URL>()

    let omniQueue = OperationQueue()
    
    public convenience init(sourceURL: Foundation.URL, geocoder: ReverseGeocoder, exiftool: ExiftoolProtocol, dryRun: Bool) {
        self.init(sourceURLs: [sourceURL], geocoder: geocoder, exiftool: exiftool, dryRun: dryRun)

    }
    
    public init(sourceURLs: [Foundation.URL], geocoder: ReverseGeocoder, exiftool: ExiftoolProtocol, dryRun: Bool) {

        // For each URL attempt to get DCIM contents
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
        
        // Queue Settings
        omniQueue.maxConcurrentOperationCount = 1
        
    }
    
    /// Use `exiftool` to get images for the given URL and create operations
    ///
    /// - Parameter url: URL to pass to `exiftool`
    func addToOmniQueue(_ url: Foundation.URL) {
        print("Read contents of \(url.lastPathComponent)\(self.dryRun ? " (dry run)" : "")")
        do {
            let locations: [EXIFLocation] = try exiftool.execute(arguments: [
                url.path,
                "-n", "-q", "-json",
                "-GPSLatitude", "-GPSLongitude", "-GPSStatus"
                ])
            
            locations.forEach { location in
                self.addToQueue(location)
            }
            
        } catch {
            print("error: could not read images")
        }
        
    }

    /// Create a ReverseGeocoding and EXIFWrite operation for the given locaiton
    ///
    /// - Parameter location: An EXIFLocation to look up and update
    func addToQueue(_ location: EXIFLocation) {
        // Create the operations
        let geocodeOperation = ReverseGeocodeOperation(location: location, geocoder: geocoder)
        let writeOperation = ExifWriterOperation(location: location, place: nil, exiftool: exiftool, dryRun: dryRun)

        // Add to the set of URLS
        exifLocations.insert(location.sourceURL)
        
        geocodeOperation.completionBlock = {
            if !geocodeOperation.statusText.isEmpty {
                print(geocodeOperation.statusText)
            }
            
            writeOperation.place = geocodeOperation.place
        }
        
        writeOperation.completionBlock = {
            if writeOperation.success {
                self.succusfulExifLocations.insert(location.sourceURL)
            }
            if !writeOperation.statusText.isEmpty {
                print(writeOperation.statusText)
            }
            
        }
        
        writeOperation.addDependency(geocodeOperation)
        
        omniQueue.addOperations([geocodeOperation, writeOperation], waitUntilFinished: true)
        
    }
    

    public func update(_ completionHandler: @escaping (Int, Int) -> Void) {
        sourceURLs.forEach { url in
            addToOmniQueue(url)
        }
        sleep(1) // Sleep to ensure everything has been added to queue
        omniQueue.waitUntilAllOperationsAreFinished()
        
        completionHandler(succusfulExifLocations.count, exifLocations.count)

    }
    
    func percent(for queue: OperationQueue, total: Int) -> Int {
        return ((total - queue.operationCount) / total ) * 100
    }
    
}

extension LocationUpdater {
    
    /// Attempt to get the contents of the DCIM of the URL.
    ///
    /// If the given URL contains a DCIM directory it is treated as a memory card
    /// and any valid DCIM folders will be returned.
    ///
    /// - Parameter url: URL to return the DCIM contents of
    /// - Returns: The valid DCIM contents, or `nil` if the folder does not contains a DCIM directory.
    public static func dcimContents(at url: Foundation.URL) -> [Foundation.URL]? {
        
        // Path of potential DCIM directory
        let dcimURL = url.appendingPathComponent("DCIM")
        
        // Get the contents of the DCIM dir
        let dcimContents = try? FileManager.default.contentsOfDirectory(at: dcimURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

        // Filter for valid DCIM image directories
        return dcimContents?.filter { url in
            url.lastPathComponent.range(of: "^\\d{3}\\w{5}$", options: .regularExpression) != nil
            }

    }
}
