//
//  IPTCLocation.swift
//  GPSLocationTagger
//
//  Created by Emory Dunn on 2018-07-02.
//

import Foundation
import CoreLocation

public protocol IPTCLocation {
    
    var country: String? { get }
    var state: String? { get }
    var city: String?  { get }
    
}

extension CLPlacemark: IPTCLocation {
    
    public var state: String? {
        return self.administrativeArea
    }
    
    public var city: String? {
        return self.locality
    }
    
    
}
