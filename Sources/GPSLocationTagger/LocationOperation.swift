//
//  LocationOperation.swift
//  GPSLocationTagger
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation


class LocationOperation: DAOperation {
    
    let location: EXIFLocation
    let geocoder: ReverseGeocoder
    let completionHandler: (Bool) -> Void
    
    init(withLocation location: EXIFLocation, geocoder: ReverseGeocoder, completionHandler: @escaping (Bool) -> Void) {
        self.location = location
        self.geocoder = geocoder
        self.completionHandler = completionHandler
    }
    
    override func start() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        location.writeLocationInfo(geocoder: geocoder) { success in
//            print("\(self.location.sourceURL.lastPathComponent) -> Operation complete: \(success)")
            self.completionHandler(success)
            self.executing(false)
            self.finish(true)
        }
        
    }
    
}
