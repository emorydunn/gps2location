import Foundation
import GPSLocationTagger
import Utility

let version = Version(0, 1, 0)

do {
    let parser = OptionParser(arguments: Array(CommandLine.arguments.dropFirst()))
    let options = parser.options
    
    if options.shouldPrintVersion {
        print("gps2location \(version)")
        exit(0)
    }
    
    let geocoder: ReverseGeocoder
    switch options.api {
    case "apple":
        geocoder = AppleGeocoder()
    case "google":
        geocoder = GoogleGeocoder()
    default:
        geocoder = GoogleGeocoder()
    }
    
    let urls = options.input.map { URL(fileURLWithPath: $0) }
    
    let updater = LocationUpdater(sourceURLs: urls, geocoder: geocoder, dryRun: options.shouldPerformDryRun)
    
    try updater.update() { success, total in
        print("Updated \(success)/\(total)")
        CFRunLoopStop(CFRunLoopGetMain())
    }
    CFRunLoopRun()
    
} catch {
    print(error)
}
