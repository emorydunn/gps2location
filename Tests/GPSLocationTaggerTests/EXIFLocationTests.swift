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
        
        
        XCTAssertNoThrow(
            try location.writeLocationInfo(from: PlacemarkMock(country: "United States"), exiftool: ExiftoolMockWriter())
        )
        XCTAssertNoThrow(
            try location.writeLocationInfo(from: PlacemarkMock(administrativeArea: "CA"), exiftool: ExiftoolMockWriter())
        )
        XCTAssertNoThrow(
            try location.writeLocationInfo(from: PlacemarkMock(locality: "Emeryville"), exiftool: ExiftoolMockWriter())
        )

    }
    
    func test_writePlacemark_active() {
        let latitude = 37.335013
        let longitude = -122.008934
        
        let location = EXIFLocation(
            sourceURL: tempFile(called: "CoreLocation.jpg"),
            latitude: latitude,
            longitude: longitude,
            status: .active
        )
        
        let writeExpectation = expectation(description: "writeExpectation")
        
        location.writeLocationInfo { success in
            if success == true {
                writeExpectation.fulfill()
            }
        }
        
        wait(for: [writeExpectation], timeout: 5)
    }
    
    func test_writePlacemark_void() {
        let latitude = 37.335013
        let longitude = -122.008934
        
        let location = EXIFLocation(
            sourceURL: tempFile(called: "CoreLocation.jpg"),
            latitude: latitude,
            longitude: longitude,
            status: .void
        )
        
        let writeExpectation = expectation(description: "writeExpectation")
        location.writeLocationInfo { success in
            if success == false {
                writeExpectation.fulfill()
            }
            
        }
        
        wait(for: [writeExpectation], timeout: 5)
        
    }

}
