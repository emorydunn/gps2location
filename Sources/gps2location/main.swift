import Foundation
import GPSLocationTagger
import Utility
import Basic

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
    case .apple:
        geocoder = AppleGeocoder()
    case .google:
        geocoder = GoogleGeocoder()
    }

    let updater = LocationUpdater(sourceURLs: options.input, geocoder: geocoder, exiftool: Exiftool(), dryRun: options.shouldPerformDryRun)
    
    updater.update { (_, _) in
        
    }
    
//    let terminalController = TerminalController(stream: stdoutStream as! LocalFileOutputByteStream)

//    let readBar = createProgressBar(forStream: stdoutStream, header: "Reading EXIF")
//    let readBar = ProgressBar(
//    readBar.
    
//    try updater.update() { success, total in
//        print("Updated \(success)/\(total)")
//        CFRunLoopStop(CFRunLoopGetMain())
//    }
//    CFRunLoopRun()
    
} catch {
    print(error)
}
