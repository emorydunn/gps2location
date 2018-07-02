//
//  PlacemarkMock.swift
//  GPSLocationTaggerTests
//
//  Created by Emory Dunn on 2018-07-02.
//

import Foundation
import CoreLocation

class PlacemarkMock: CLPlacemark {
    
    var _country: String?
    var _administrativeArea: String?
    var _locality: String?
    
    init(country: String? = nil, administrativeArea: String? = nil, locality: String? = nil) {
        
        self._country = country
        self._administrativeArea = administrativeArea
        self._locality = locality
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var country: String? {
        return _country
    }
    
    override var administrativeArea: String? {
        return _administrativeArea
    }
    
    override var locality: String? {
        return _locality
    }
}
