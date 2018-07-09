//
//  PlacemarkMock.swift
//  GPSLocationTaggerTests
//
//  Created by Emory Dunn on 2018-07-02.
//

import Foundation
import CoreLocation
import GPSLocationTagger

class PlacemarkMock: IPTCLocatable {
    
    var _country: String? = nil
    var _administrativeArea: String? = nil
    var _locality: String? = nil
    
    init(country: String? = nil, administrativeArea: String? = nil, locality: String? = nil) {
        
        self._country = country
        self._administrativeArea = administrativeArea
        self._locality = locality

    }

    var country: String? {
        return _country
    }
    
    var state: String? {
        return _administrativeArea
    }
    
    var city: String? {
        return _locality
    }
}
