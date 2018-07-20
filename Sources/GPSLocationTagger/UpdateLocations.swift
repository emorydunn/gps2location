//
//  UpdateLocations.swift
//  gps2location
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation
import Cocoa
import Utility
import Basic

public class LocationUpdater: NSObject {
    
    public let sourceURLs: [Foundation.URL]
    
    public let geocoder: ReverseGeocoder
    public let exiftool: ExiftoolProtocol
    
    public let dryRun: Bool
    
    /// Unique image URLs
    var exifLocations = Set<Foundation.URL>()
    
    /// Count of locations written successfully
    var succusfulExifLocations = Set<Foundation.URL>()

    @objc let omniQueue = OperationQueue()
    var queueTotalTasks: Int = 0
    var progressBar: ProgressBarProtocol? = nil
    let progressQueue = DispatchQueue(label: "ProgressQeue")
    
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
        omniQueue.isSuspended = true
        
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
            self.omniQueue.name = "Geocoding \(location.sourceURL.lastPathComponent)"
            if !geocodeOperation.statusText.isEmpty {
//                print(geocodeOperation.statusText)
            }
            
            writeOperation.place = geocodeOperation.place
        }
        
        writeOperation.completionBlock = {
            self.omniQueue.name = "Writing \(location.sourceURL.lastPathComponent)"
            if writeOperation.success {
                self.succusfulExifLocations.insert(location.sourceURL)
            }
            if !writeOperation.statusText.isEmpty {
//                print(writeOperation.statusText)
            }
            
        }
        
        writeOperation.addDependency(geocodeOperation)
//        print("Enqueueing \(location.sourceURL.lastPathComponent)")
        omniQueue.addOperations([geocodeOperation, writeOperation], waitUntilFinished: false)
        
    }
    

    public func update(_ completionHandler: @escaping (Int, Int, TimeInterval) -> Void) {
        sourceURLs.forEach { url in
            addToOmniQueue(url)
        }
//        print("Queue is \(omniQueue.isSuspended ? "paused" : "active") with \(omniQueue.operationCount / 2) tasks")
        queueTotalTasks = omniQueue.operationCount
        
        addObserver(
            self,
            forKeyPath: #keyPath(omniQueue.operationCount),
            options: NSKeyValueObservingOptions.new,
            context: nil
        )
        
        progressBar = createProgressBar(forStream: stdoutStream, header: "Geocoding")
        let startDate = Date()
        omniQueue.isSuspended = false
        sleep(1) // Sleep to ensure everything has been added to queue
        omniQueue.waitUntilAllOperationsAreFinished()
        
        progressBar?.complete(success: true)
        let duration = Date().timeIntervalSince(startDate)
        completionHandler(succusfulExifLocations.count, exifLocations.count, duration)

    }
    
    func percent(for queue: OperationQueue, total: Int) -> Int {
        return ((total - queue.operationCount) / total ) * 100
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(omniQueue.operationCount) {
            let complete = Double(queueTotalTasks - omniQueue.operationCount) / Double(queueTotalTasks)
            
            let percent = Int(complete * 100)

            progressQueue.async {
                self.progressBar?.update(percent: percent, text: self.omniQueue.name ?? "")
            }
            
        }
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
