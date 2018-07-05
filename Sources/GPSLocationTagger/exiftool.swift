//
//  exiftool.swift
//  GPSLocationTagger
//
//  Created by Emory Dunn on 2018-07-02.
//

import Foundation

public typealias TraceFunction = (_ command: String?, _ response: Data?) -> Void

public struct ProcessResult {
    let terminationStatus: Int32
    let response: Data
}

public enum ExiftoolError: Error {
    case responseNotZero(process: Process)
}

public class Exiftool: ExiftoolProtocol {
    
    public var exiftoolLocation: String
    public var trace: TraceFunction?
    
    public required init(exiftool: String = "/usr/local/bin/exiftool", trace: TraceFunction? = nil) {
        self.exiftoolLocation = exiftool
        self.trace = trace
    }
}



public protocol ExiftoolProtocol {
    
    var exiftoolLocation: String { get set }
    var trace: TraceFunction? { get set }
    
    init(exiftool: String, trace: TraceFunction?)
    
    func execute(arguments: [String]) throws -> ProcessResult
    
    func execute<T: Decodable>(arguments: [String]) throws -> T
    
}

extension ExiftoolProtocol {
    
    public func execute(arguments: [String]) throws -> ProcessResult {
        let process = Process()
        let stdOutPipe = Pipe()
        
        process.launchPath = exiftoolLocation
        process.arguments = arguments
        
        process.standardOutput = stdOutPipe
        process.standardError = stdOutPipe
        
        trace?("""
            \(process.launchPath!) \
            \(process.arguments!.joined(separator: " "))
            """, nil)

        process.launch()
        
        // Process Pipe into Data
        let stdOutputData = stdOutPipe.fileHandleForReading.readDataToEndOfFile()

        process.waitUntilExit()
        trace?(nil, stdOutputData)
        
        if process.terminationStatus != 0 {
            throw ExiftoolError.responseNotZero(process: process)
        }
        
        return ProcessResult(terminationStatus: process.terminationStatus, response: stdOutputData)
    }
    
    public func execute<T: Decodable>(arguments: [String]) throws -> T {
        let decoder = JSONDecoder()
        let data: ProcessResult = try execute(arguments: arguments)
        
        return try decoder.decode(T.self, from: data.response)

    }
    
}
