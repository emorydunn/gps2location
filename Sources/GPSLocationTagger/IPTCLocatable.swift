//
//  IPTCLocation.swift
//  GPSLocationTagger
//
//  Created by Emory Dunn on 2018-07-02.
//

import Foundation
import CoreLocation

public protocol IPTCLocatable {
    
    var country: String? { get }
    var state: String? { get }
    var city: String?  { get }
    var route: String? { get }
    var neighborhood: String? { get }
    
}

struct IPTCLocation: IPTCLocatable {
    var country: String?
    var state: String?
    var city: String?
    var route: String?
    var neighborhood: String?
}

extension CLPlacemark: IPTCLocatable {
    
    public var state: String? {
        return self.administrativeArea
    }
    
    public var city: String? {
        return self.locality
    }
    

    public var route: String? {
        return self.thoroughfare
    }
    
    public var neighborhood: String? {
        return self.subLocality
    }

}

