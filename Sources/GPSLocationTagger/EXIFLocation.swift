//
//  EXIFLocation.swift
//  GPSLocationTagger
//
//  Created by Emory Dunn on 2018-07-01.
//

import Foundation
import CoreLocation

public enum EXIFToolError: Error {
    case writeError(message: String, command: String)
    case noImages(URL)
    
    public var localizedDescription: String {
        switch self {
        case .writeError(let message, let command):
            return """
            \(message)
            \(command)
            """
        case .noImages(let url):
            return "No images were found at \(url.path)"
        }
    }
}

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
    
    public func reverseGeocodeLocation(_ completionHandler: @escaping (CLPlacemark?) -> Void) {
//        print("\(self.sourceURL.lastPathComponent) -> reverse geocode start")
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(self.asCoreLocation()) { (placemarks, error) in
            if error == nil {
                let firstLocation = placemarks?[0]
//                print("\(self.sourceURL.lastPathComponent) -> reverse geocode complete")
                completionHandler(firstLocation)
            }
            else {
                // An error occurred during geocoding.
//                print("\(self.sourceURL.lastPathComponent) -> reverse geocode error")
                completionHandler(nil)
            }
        }
//        print("_returning from reverseGeocodeLocation")
    }
    
    func writeLocationInfo(from placemark: CLPlacemark) throws {
        #if os(Linux)
            let process = Task()
        #else
            let process = Process()
        #endif
        let stdOutPipe = Pipe()
        
        process.standardOutput = stdOutPipe
        
        process.launchPath = "/usr/local/bin/exiftool"
        process.arguments = [
            sourceURL.path,
            "-m"
        ]
        
        if let value = placemark.country {
//            print("country \(value)")
            process.arguments?.append("-IPTC:Country-PrimaryLocationName=\(value)")
        }
        if let value = placemark.administrativeArea {
//            print("state \(value)")
            process.arguments?.append("-IPTC:Province-State=\(value)")
        }
        if let value = placemark.locality {
//            print("city \(value)")
            process.arguments?.append("-IPTC:City=\(value)")
        }
        
//        print(
//            """
//            running shell command:
//            \(process.launchPath!)
//            \(process.arguments!.joined(separator: " "))
//            """
//        )
        
        process.launch()
        // Process Pipe into a String
        let stdOutputData = stdOutPipe.fileHandleForReading.readDataToEndOfFile()
        let stdOutString = String(bytes: stdOutputData, encoding: String.Encoding.utf8)

        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw EXIFToolError.writeError(message: stdOutString ?? "", command: process.arguments!.joined(separator: " "))
//            return .success(stdout: stdOutString ?? "")
        }
        
//        return .failure(errout: stdOutString ?? "")

    }
    
    public func writeLocationInfo(_ completionHandler: @escaping (Bool) -> Void) {
        switch status {
        case .active:
//            print("\(self.sourceURL.lastPathComponent) -> Looking up")
            reverseGeocodeLocation { placemark in
                guard let place = placemark else {
                    print("\(self.sourceURL.lastPathComponent) -> Skipping, File has no placemark")
                    completionHandler(false)
                    return
                }
                do {
                    print("\(self.sourceURL.lastPathComponent) -> Updating location")
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
//        print("_returning from writeLocationInfo")
    }
    
}

extension EXIFLocation {
    
    public static func exifLocation(for url: URL) throws -> [EXIFLocation] {
        let process = Process()
        let stdOutPipe = Pipe()
        
        process.launchPath = "/usr/local/bin/exiftool"
        process.arguments = [
            url.path,
            "-n", "-q", "-json",
            "-GPSLatitude", "-GPSLongitude", "-GPSStatus"
        ]
        
        process.standardOutput = stdOutPipe
        
//        print(
//            """
//            running shell command:
//            \(process.launchPath!) \
//            \(process.arguments!.joined(separator: " "))
//            """
//        )
        
        process.launch()
        
        // Process Pipe into a String
        let stdOutputData = stdOutPipe.fileHandleForReading.readDataToEndOfFile()
//        let stdOutString = String(bytes: stdOutputData, encoding: String.Encoding.utf8)
    
        process.waitUntilExit()

        if stdOutputData.isEmpty {
            throw EXIFToolError.noImages(url)
        }
        let decoder = JSONDecoder()
        let locations = try decoder.decode(Array<EXIFLocation>.self, from: stdOutputData)

        return locations
        
    }
}
