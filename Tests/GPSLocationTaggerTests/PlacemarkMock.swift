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
    
    var country: String?
    var state: String?
    var city: String?
    var route: String?
    var neighborhood: String?
    
    init(country: String? = nil, state: String? = nil, city: String? = nil, route: String? = nil, neighborhood: String? = nil) {
    
        self.country = country
        self.state = state
        self.city = city
        self.route = route
        self.neighborhood = neighborhood
    }

}
