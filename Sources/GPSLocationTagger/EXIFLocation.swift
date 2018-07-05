//
//  EXIFLocation.swift
//  GPSLocationTagger
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation
import CoreLocation

//public enum EXIFToolError: Error {
//    case writeError(message: String, command: String)
//    case noImages(URL)
//
//    public var localizedDescription: String {
//        switch self {
//        case .writeError(let message, let command):
//            return """
//            \(message)
//            \(command)
//            """
//        case .noImages(let url):
//            return "No images were found at \(url.path)"
//        }
//    }
//}

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
    
    public func asCoreLocation() -> CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
//    public func reverseGeocodeLocation(_ completionHandler: @escaping (IPTCLocatable?) -> Void) {
//
//        let geocoder = CLGeocoder()
//        geocoder.reverseGeocodeLocation(self.asCoreLocation()) { (placemarks, error) in
//            if error == nil {
//                let firstLocation = placemarks?[0]
//                completionHandler(firstLocation)
//            }
//            else {
//                // An error occurred during geocoding.
//                print(error!.localizedDescription)
//                completionHandler(nil)
//            }
//        }
//    }
    
    func writeLocationInfo(from placemark: IPTCLocatable, exiftool: ExiftoolProtocol = Exiftool()) throws {
        var arguments = [
            sourceURL.path,
            "-m"
        ]
        if let value = placemark.country {
            arguments.append("-IPTC:Country-PrimaryLocationName=\(value)")
        }
        if let value = placemark.state {
            arguments.append("-IPTC:Province-State=\(value)")
        }
        if let value = placemark.city {
            arguments.append("-IPTC:City=\(value)")
        }
        
        _ = try exiftool.execute(arguments: arguments)


    }
    
    public func writeLocationInfo(geocoder: ReverseGeocoder, _ completionHandler: @escaping (Bool) -> Void) {
        switch status {
        case .active:
            geocoder.reverseGeocodeLocation(self) { placemark in
                guard let place = placemark else {
                    print("\(self.sourceURL.lastPathComponent) -> Skipping, File has no placemark")
                    completionHandler(false)
                    return
                }
                do {
                    print("\(self.sourceURL.lastPathComponent) -> Updating location \(place.country ?? "none"), \(place.state ?? "none"), \(place.city ?? "none")")
                    try self.writeLocationInfo(from: place)
                    completionHandler(true)
                } catch {
                    print(error)
                    completionHandler(false)
                }
                
            }
        case .void:
            print("\(self.sourceURL.lastPathComponent) -> Skipping, GPS status void")
            completionHandler(false)
        }

    }
    
}

extension EXIFLocation {
    
    public static func exifLocation(for url: URL, exiftool: ExiftoolProtocol = Exiftool()) throws -> [EXIFLocation] {
        
        return try exiftool.execute(arguments: [
            url.path,
            "-n", "-q", "-json",
            "-GPSLatitude", "-GPSLongitude", "-GPSStatus"
            ])
//
//        let process = Process()
//        let stdOutPipe = Pipe()
//
//        process.launchPath = "/usr/local/bin/exiftool"
//        process.arguments = [
//            url.path,
//            "-n", "-q", "-json",
//            "-GPSLatitude", "-GPSLongitude", "-GPSStatus"
//        ]
//
//        process.standardOutput = stdOutPipe
//
////        print(
////            """
////            running shell command:
////            \(process.launchPath!) \
////            \(process.arguments!.joined(separator: " "))
////            """
////        )
//
//        process.launch()
//
//        // Process Pipe into a String
//        let stdOutputData = stdOutPipe.fileHandleForReading.readDataToEndOfFile()
////        let stdOutString = String(bytes: stdOutputData, encoding: String.Encoding.utf8)
//
//        process.waitUntilExit()
//
//        if stdOutputData.isEmpty {
//            throw EXIFToolError.noImages(url)
//        }
//        let decoder = JSONDecoder()
//        let locations = try decoder.decode(Array<EXIFLocation>.self, from: stdOutputData)
//
//        return locations
        
    }
}
