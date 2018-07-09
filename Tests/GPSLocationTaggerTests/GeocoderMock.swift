//
//  GeocoderMock.swift
//  GPSLocationTaggerTests
//
//  Created by Emory Dunn on 2018-07-09.
//

import Foundation
import GPSLocationTagger

class GeocoderMock: ReverseGeocoder {
    func reverseGeocodeLocation(_ location: EXIFLocation, completionHandler: @escaping (IPTCLocatable?) -> Void) {
        let place = PlacemarkMock(country: nil, state: nil, city: nil, route: nil, neighborhood: nil)
        completionHandler(place)
    }
}
