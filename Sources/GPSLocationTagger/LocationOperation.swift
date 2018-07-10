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
    
    var place: IPTCLocatable? = nil
    var statusText: String = "Geocode pending"
    
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

                self.place = place
                if place == nil {
                    self.statusText = "\(self.location.sourceURL.lastPathComponent) -> Could not fetch place"
                } else {
                    self.statusText = ""
                }
                
                
                self.executing(false)
                self.finish(true)
            }
        case .void:

            self.statusText = "\(self.location.sourceURL.lastPathComponent) -> GPS status void"
            self.executing(false)
            self.finish(true)
        }
    }
    
}

class ExifWriterOperation: DAOperation {
    
    let location: EXIFLocation
    var place: IPTCLocatable?
    
    let exiftool: ExiftoolProtocol
    let dryRun: Bool
    
    var success = false
    var statusText = "Write pending"
    
    init(location: EXIFLocation, place: IPTCLocatable?, exiftool: ExiftoolProtocol, dryRun: Bool) {
        self.location = location
        self.place = place
        self.exiftool = exiftool
        self.dryRun = dryRun
    }
    
    override func start() {
        guard isCancelled == false, let place = place else {
            self.statusText = ""
            finish(true)
            return
        }

        self.statusText = "\(self.location.sourceURL.lastPathComponent) -> \(place.description)"
        
        if dryRun {
            success = true
            self.finish(true)
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
            success = true
        } catch {
            self.statusText = "\(self.location.sourceURL.lastPathComponent) -> Could not write EXIF"
        }
        
        self.executing(false)
        self.finish(true)
        
    }
    
}
