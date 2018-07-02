//
//  LocationOperation.swift
//  GPSLocationTagger
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation


class LocationOperation: DAOperation {
    
    let location: EXIFLocation
    
    init(withLocation location: EXIFLocation) {
        self.location = location
    }
    
    override func start() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        location.writeLocationInfo { success in
            print("\(self.location.sourceURL.lastPathComponent) -> Operation complete: \(success)")
            
            self.executing(false)
            self.finish(true)
        }
        
    }
    
}
