//
//  EXIFLocationTests.swift
//  GPSLocationTaggerTests
//
//  Created by Emory Dunn on 2018-07-01.
//

import XCTest
import CoreLocation
@testable import GPSLocationTagger

class EXIFLocationTests: XCTestCase {

    func tempFile(called name: String) -> URL {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        return tempDir.appendingPathComponent(name)
    }
    
    func writeTestFile(to url: URL) {
        let process = Process()
        process.launchPath = "/usr/local/bin/convert"
        process.arguments = [
            "-size",
            "800x800",
            "xc:white",
            url.path
        ]
        
        process.launch()
        process.waitUntilExit()
    }
    
    

    func testLocation() {
        let latitude = 37.335013
        let longitude = -122.008934
        
        let location = EXIFLocation(
            sourceURL: tempFile(called: "CoreLocation.xmp"),
            latitude: latitude,
            longitude: longitude,
            status: .active
        )
        
        XCTAssertEqual(location.asCoreLocation(), CLLocation(latitude: latitude, longitude: longitude))
        
    }
    
    func test_ReverseGeocode() {
        let latitude = 37.335013
        let longitude = -122.008934
        
        let location = EXIFLocation(
            sourceURL: tempFile(called: "CoreLocation.xmp"),
            latitude: latitude,
            longitude: longitude,
            status: .active
        )
        
        let placemarkExpectation = expectation(description: "Placemark")
        
        location.reverseGeocodeLocation { placemark in
            guard placemark != nil else {
                XCTAssert(false)
                return
            }
            
            placemarkExpectation.fulfill()
            
        }
        
        wait(for: [placemarkExpectation], timeout: 5)
        
    }
    
    func test_writePlacemark() {
        let latitude = 37.335013
        let longitude = -122.008934
        
        let location = EXIFLocation(
            sourceURL: tempFile(called: "CoreLocation.jpg"),
            latitude: latitude,
            longitude: longitude,
            status: .active
        )
        
        let testPlace = PlacemarkMock(
            country: "United States",
            administrativeArea: "CA",
            locality: "San Francisco"
        )

        XCTAssertNoThrow(
            try location.writeLocationInfo(from: testPlace, exiftool: ExiftoolMockWriter())
//            try location.writeLocationInfo(from: testPlace, exiftool: ExiftoolMockWriter())
        )
        
//        location.reverseGeocodeLocation { placemark in
//            guard placemark != nil else {
//                XCTAssert(false)
//                return
//            }
//
//            do {
//                XCTAssertNoThrow(try location.writeLocationInfo(from: placemark!))
//            } catch {
//                print(error)
//            }
//
//            placemarkExpectation.fulfill()
//
//        }
//
//        wait(for: [placemarkExpectation], timeout: 5)
    }

}
