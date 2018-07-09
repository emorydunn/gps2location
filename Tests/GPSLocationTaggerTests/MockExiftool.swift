//
//  MockExiftool.swift
//  GPSLocationTaggerTests
//
//  Created by Emory Dunn on 2018-07-02.
//

import Foundation
@testable import GPSLocationTagger

class ExiftoolMockWriter: ExiftoolProtocol {
    var exiftoolLocation: String
    
    var trace: TraceFunction?
    
    required init(exiftool: String, trace: TraceFunction?) {
        self.exiftoolLocation = exiftool
        self.trace = trace
    }
    
    convenience init() {
        self.init(exiftool: "", trace: nil)
    }
    
    public func execute(arguments: [String]) throws -> ProcessResult {

        let response = """
        1 directories scanned
        3 image files updated
        """
        let data = response.data(using: .utf8, allowLossyConversion: false)
        
        return ProcessResult(terminationStatus: 0, response: data!)
    }
    
    public func execute<T: Decodable>(arguments: [String]) throws -> T {
        let decoder = JSONDecoder()
        let data: ProcessResult = try execute(arguments: arguments)
        
        return try decoder.decode(T.self, from: data.response)
        
    }

}

class ExiftoolMockReader: ExiftoolProtocol {
    var exiftoolLocation: String
    
    var trace: TraceFunction?
    
    required init(exiftool: String, trace: TraceFunction?) {
        self.exiftoolLocation = exiftool
        self.trace = trace
    }
    
    convenience init() {
        self.init(exiftool: "", trace: nil)
    }
    
    public func execute(arguments: [String]) throws -> ProcessResult {
        print("Accpeting args: \(arguments)")
        
        let url = URL(fileURLWithPath: "/")
        let images = [
            EXIFLocation(sourceURL: url, latitude: 100, longitude: -100, status: .active),
            EXIFLocation(sourceURL: url, latitude: 200, longitude: -200, status: .active),
            EXIFLocation(sourceURL: url, latitude: 100, longitude: -100, status: .void),
            ]
        
        let encoder = JSONEncoder()
        let data = try! encoder.encode(images)
        
        print("Returning mock data")
        return ProcessResult(terminationStatus: 0, response: data)
    }
    
    public func execute<T: Decodable>(arguments: [String]) throws -> T {
        let decoder = JSONDecoder()
        let data: ProcessResult = try execute(arguments: arguments)
        
        return try decoder.decode(T.self, from: data.response)
        
    }
    
}
