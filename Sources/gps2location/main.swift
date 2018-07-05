import Foundation
import GPSLocationTagger
import Utility

let version = Version(0, 1, 0)

let mainParser = ArgumentParser(usage: "[OPTIONS] FILE...", overview: "Updates image IPTC location from GPS coordinates")
let versionCommand = mainParser.add(option: "--version", kind: Bool.self, usage: "Prints the version and exits")
let googleMapsOption = mainParser.add(option: "--google", kind: Bool.self, usage: "Use Google Maps API")

let input = mainParser.add(positional: "file", kind: Array<String>.self, usage: "A single file, a directory of images, or a camera card")

do {
    let args = CommandLine.arguments.dropFirst()
    let results = try mainParser.parse(Array(args))
    
    if let _ = results.get(versionCommand) {
        print("gps2location \(version)")
        exit(0)
    }
    
    let geocoder: ReverseGeocoder
    if results.get(googleMapsOption)! {
        geocoder = GoogleGeocoder()
    } else {
        geocoder = AppleGeocoder()
    }
    
    guard let profilePath = results.get(input) else {
        exit(EXIT_FAILURE)
    }
    
    let urls = profilePath.map { URL(fileURLWithPath: $0) }
    
    // Test for DCIM
    let updater = LocationUpdater(sourceURLs: urls, geocoder: geocoder)

    try updater.update() {
        CFRunLoopStop(CFRunLoopGetMain())
    }
    CFRunLoopRun()

} catch let error as ArgumentParserError {
    print(error)
} catch _ as Swift.DecodingError {
    print("ERROR: Could not read metadata from input")
//} catch let error as EXIFToolError {
//    print(error.localizedDescription)
//    
} catch {
    print("Unknown error")
    print()
    print(error)
}
