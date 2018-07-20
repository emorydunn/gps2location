import Foundation
import GPSLocationTagger
import Utility
import Basic

let version = Version(0, 1, 0)


let parser = OptionParser(arguments: Array(CommandLine.arguments.dropFirst()))
let options = parser.options

if options.shouldPrintVersion {
    print("gps2location \(version)")
    exit(0)
}

let geocoder: ReverseGeocoder
switch options.api {
case .apple:
    geocoder = AppleGeocoder()
case .google:
    geocoder = GoogleGeocoder()
}
let exiftool = Exiftool(trace: nil)

let updater = LocationUpdater(sourceURLs: options.input, geocoder: geocoder, exiftool: exiftool, dryRun: options.shouldPerformDryRun)

updater.update { (success, total, _) in
    print("\nUpdated \(success) / \(total)")
    
}
