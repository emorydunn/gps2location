# GPSLocationTagger

A tool to add reverse geocoded IPTC information from a files GPS coordinates. 

## Usage

```
OVERVIEW: Updates image IPTC location from GPS coordinates

USAGE: gps2location [OPTIONS] FILE...

OPTIONS:
  --api       Geocoding API to use, defaults to Google [ google | apple ]
  --dry-run   Only perform lookup, don't update metadata
  --version   Prints the version and exits
  --help      Display available options

POSITIONAL ARGUMENTS:
  file        A single file, a directory of images, or a camera card
```

## Details

Embedded GPS coordinates are reverse geocoded into Country, State, City, and Location IPTC tags. If a route is provided by the geocoding API it will be added as an keyword tag. Images that don't have GPS coordinates or whose corrdinates are tagged as `void` the image will not be tagged. 

## Memory Cards

If the input path contains a `DCIM` directory it is treated as a memory card.  Any valid DCIM-spec dirctories will have their contents tagged. The contents of the input directory are ignored. 