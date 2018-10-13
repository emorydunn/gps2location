//
//  OptionParser.swift
//  gps2location
//
//  Created by Emory Dunn on 2018-07-08.
//

import Foundation
import Utility
import POSIX
import Basic

enum GeocodingAPI: String, ArgumentKind {

    case apple
    case google
    
    public init(argument: String) throws {
        guard let api = GeocodingAPI(rawValue: argument) else {
            throw ArgumentConversionError.unknown(value: argument)
        }
        self = api
    }
    
    static var completion: ShellCompletion = ShellCompletion.none
    
}

struct Options {
    var input: [Foundation.URL] = []
    var api = GeocodingAPI.google
    var shouldPrintVersion: Bool = false
    var shouldPerformDryRun: Bool = false
}

struct OptionParser {
    let options: Options
    private let parser: ArgumentParser
    
    init(arguments: [String]) {
        parser = ArgumentParser(usage: "[OPTIONS] FILE...", overview: "Updates image IPTC location from GPS coordinates")
        
        let binder = ArgumentBinder<Options>()
        binder.bind(
            positional: parser.add(
                positional: "file",
                kind: [Foundation.URL].self,
                optional: false,
                usage: "A single file, a directory of images, or a camera card"
            ),
            to: {
                $0.input = $1
        })
        binder.bind(
            option: parser.add(
                option: "--api",
                kind: GeocodingAPI.self,
                usage: "Geocoding API to use (google|apple) [default: google]"
            ),
            to: {
                $0.api = $1
        })
        binder.bind(
            option: parser.add(
                option: "--version",
                kind: Bool.self,
                usage: "Prints the version and exits"
            ),
            to: {
                $0.shouldPrintVersion = $1
        })
        binder.bind(
            option: parser.add(
                option: "--dry-run",
                kind: Bool.self,
                usage: "Only perform lookup, don't update metadata"
            ),
            to: {
                $0.shouldPerformDryRun = $1
        })
        
        do {
            let result = try parser.parse(arguments)
            var options = Options()
            try binder.fill(parseResult: result, into: &options)
            self.options = options
            
        } catch {
            switch error {
            case ArgumentParserError.expectedArguments(let parser, _):
                print(error)
                print()
                parser.printUsage(on: stderrStream)
            default:
                print(error)
            }
            POSIX.exit(1)

        }
    }
}


extension Foundation.URL: ArgumentKind {
    public init(argument: String) throws {
        self.init(fileURLWithPath: argument)
    }
    
    public static var completion: ShellCompletion = .filename

}
