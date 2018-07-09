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

    func test_Init() {
        let latitude = 37.335013
        let longitude = -122.008934
        
        let location = EXIFLocation(
            sourceURL: tempFile(called: "CoreLocation.xmp"),
            latitude: latitude,
            longitude: longitude,
            status: .active
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try! encoder.encode(location)

        XCTAssertNoThrow(try decoder.decode(EXIFLocation.self, from: data))
        
    }
    

}
