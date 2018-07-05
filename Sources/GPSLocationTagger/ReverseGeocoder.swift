//
//  ReverseGeocoder.swift
//  GPSLocationTagger
//
//  Created by Emory Dunn on 7/4/18.
//

import Foundation
import CoreLocation

public protocol ReverseGeocoder {
    func reverseGeocodeLocation(_ location: EXIFLocation, completionHandler: @escaping (IPTCLocatable?) -> Void)
}

public class AppleGeocoder: ReverseGeocoder {
    
    public init() {
        
    }
    
    public func reverseGeocodeLocation(_ location: EXIFLocation, completionHandler: @escaping (IPTCLocatable?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location.asCoreLocation()) { (placemarks, error) in
            if error == nil {
                let firstLocation = placemarks?[0]
                completionHandler(firstLocation)
            }
            else {
                // An error occurred during geocoding.
                print(error!.localizedDescription)
                completionHandler(nil)
            }
        }
    }
}

public class GoogleGeocoder: ReverseGeocoder {
    
    public init() {
        
    }
    
    public func reverseGeocodeLocation(_ location: EXIFLocation, completionHandler: @escaping (IPTCLocatable?) -> Void) {
        
        guard let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(location.latitude),\(location.longitude)") else {
                completionHandler(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, let dict = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                 completionHandler(nil)
                return
            }
            
            completionHandler(self.extractPlace(from: dict))
        }
        
        task.resume()

    }
    
    func extractPlace(from json: [String: Any]) -> IPTCLocatable? {
        
        guard let results = json["results"] as? [[String: Any]], let firstResult = results.first else {
            return nil
        }
        
        guard let addressComponents = firstResult["address_components"] as? [[String: Any]] else {
            return nil
        }
        
        let places = addressComponents.compactMap { json in
            GooglePlace(fromJSONDict: json)
        }
        
        var location = IPTCLocation(country: nil, state: nil, city: nil)
        places.forEach { place in
            if place.types.contains("country") {
                location.country = place.longName
            } else if place.types.contains("administrative_area_level_1") {
                location.state = place.longName
            } else if place.types.contains("locality") {
                location.city = place.longName
            }
            
        }
        return location
        
    }

}

struct GooglePlace: Decodable {
    let longName: String
    let shortName: String
    let types: [String]
    
    enum CodingKeys: String, CodingKey {
        case longName = "long_name"
        case shortName = "short_name"
        case types
    }
    
    init?(fromJSONDict json: [String: Any]) {
        guard let longName = json["long_name"] as? String, let shortName = json["short_name"] as? String, let types = json["types"] as? [String] else {
            return nil
        }
        self.longName = longName
        self.shortName = shortName
        self.types = types
    }
}
