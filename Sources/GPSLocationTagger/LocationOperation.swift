//
//  LocationOperation.swift
//  GPSLocationTagger
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation


//class LocationOperation: DAOperation {
//
//    let location: EXIFLocation
//    let geocoder: ReverseGeocoder
//    let completionHandler: (Bool) -> Void
//    var dryRun: Bool = false
//
//    init(withLocation location: EXIFLocation, geocoder: ReverseGeocoder, completionHandler: @escaping (Bool) -> Void) {
//        self.location = location
//        self.geocoder = geocoder
//        self.completionHandler = completionHandler
//    }
//
//    override func start() {
//        guard isCancelled == false else {
//            finish(true)
//            return
//        }
//
//        executing(true)
//        if dryRun {
//            self.completionHandler(true)
//            self.executing(false)
//            self.finish(true)
//        } else {
//            location.writeLocationInfo(geocoder: geocoder) { success in
//                self.completionHandler(success)
//                self.executing(false)
//                self.finish(true)
//            }
//        }
//
//
//    }
//
//}

class ExifReaderOperation: DAOperation {
    
    let source: URL
    let exiftool: ExiftoolProtocol

    var locations: [EXIFLocation] = []
    
    init(source: URL, exiftool: ExiftoolProtocol) {
        self.source = source
        self.exiftool = exiftool
    }
    
    override func start() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        do {
            locations = try exiftool.execute(arguments: [
                source.path,
                "-n", "-q", "-json",
                "-GPSLatitude", "-GPSLongitude", "-GPSStatus"
                ])
            print("Operation with \(locations.count) locations")
        } catch {
            print("error: could not read images")
        }
        self.executing(false)
        self.finish(true)
        
    }
    
}

class ReverseGeocodeOperation: DAOperation {
    
    let location: EXIFLocation
    let geocoder: ReverseGeocoder
    
    var responseData: IPTCLocatable? = nil
    
    init(location: EXIFLocation, geocoder: ReverseGeocoder) {
        self.location = location
        self.geocoder = geocoder
    }
    
    override func start() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        switch location.status {
        case .active:
            geocoder.reverseGeocodeLocation(location) { place in
                print("Operation assigning place")
                self.responseData = place
                self.executing(false)
                self.finish(true)
            }
        case .void:
            print("Operation location void")
            self.executing(false)
            self.finish(true)
        }
    }
    
}

class ExifWriterOperation: DAOperation {
    
    let location: EXIFLocation
    let place: IPTCLocatable
    let exiftool: ExiftoolProtocol
    
    init(location: EXIFLocation, place: IPTCLocatable, exiftool: ExiftoolProtocol) {
        self.location = location
        self.place = place
        self.exiftool = exiftool
    }
    
    override func start() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        var arguments = [
            location.sourceURL.path,
            "-m"
        ]
        
        // IPTC Location
        if let value = place.country {
            arguments.append("-IPTC:Country-PrimaryLocationName=\(value)")
        }
        if let value = place.state {
            arguments.append("-IPTC:Province-State=\(value)")
        }
        if let value = place.city {
            arguments.append("-IPTC:City=\(value)")
        }
        if let value = place.neighborhood {
            arguments.append("-IPTC:Sub-location=\(value)")
        }
        
        // Keywords
        if let value = place.route {
            arguments.append("-keywords=\(value)")
        }
        
        do {
            _ = try exiftool.execute(arguments: arguments)
        } catch {
            print("error: could not write to \(location.sourceURL.lastPathComponent)")
        }
        
        self.executing(false)
        self.finish(true)
        
    }
    
}
