//
//  ReadQueueTests.swift
//  GPSLocationTaggerTests
//
//  Created by Emory Dunn on 2018-07-09.
//

import XCTest
@testable import GPSLocationTagger

class QueueTests: XCTestCase {


    func testReadQueue() {
        let updater = LocationUpdater(
            sourceURL: URL(fileURLWithPath: NSTemporaryDirectory()),
            geocoder: GeocoderMock(),
            exiftool: ExiftoolMockReader(),
            dryRun: true
        )
        
        let locations = updater.addToQueue(updater.sourceURLs)
        
        XCTAssertEqual(locations.count, 3)
   
    }
    
    func testGeocodeQueue() {
        let updater = LocationUpdater(
            sourceURL: URL(fileURLWithPath: NSTemporaryDirectory()),
            geocoder: GeocoderMock(),
            exiftool: ExiftoolMockReader(),
            dryRun: true
        )
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
        let locations = [
            EXIFLocation(sourceURL: url, latitude: 100, longitude: -100, status: .active),
            EXIFLocation(sourceURL: url, latitude: 200, longitude: -200, status: .active),
            EXIFLocation(sourceURL: url, latitude: 100, longitude: -100, status: .void),
            ]
        
        updater.exifWriteQueue.isSuspended = true
        updater.addToQueue(locations, waitUntilFinished: true)
        
        XCTAssertEqual(updater.exifWriteQueue.operationCount, 2)
        
    }
    

}

