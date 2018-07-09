//
//  EXIFLocation.swift
//  GPSLocationTagger
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation
import CoreLocation

public struct EXIFLocation: Codable {
    public let sourceURL: URL
    
    public let latitude: Double
    public let longitude: Double
    public let status: GPSStatus
    
    public enum GPSStatus: String, Codable {
        case active = "A"
        case void = "V"
    }
    
    enum CodingKeys: String, CodingKey {
        case sourceURL = "SourceFile"
        case latitude = "GPSLatitude"
        case longitude = "GPSLongitude"
        case status = "GPSStatus"
    }

    public init(sourceURL: URL, latitude: Double, longitude: Double, status: GPSStatus) {
        self.sourceURL = sourceURL
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // exiftool returns un-escaped URLS
        // JSONDecoder is looking for an escaped string, and fails
        let urlString = try values.decode(String.self, forKey: .sourceURL)
        self.sourceURL = URL(fileURLWithPath: urlString)
        
        self.latitude = try values.decode(Double.self, forKey: .latitude)
        self.longitude = try values.decode(Double.self, forKey: .longitude)
        self.status = try values.decode(GPSStatus.self, forKey: .status)
    }
    
}
