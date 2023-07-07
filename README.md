# National Carousel Association (NCA) Census Project

The National Carousel Association maintains a global census of carousel data. This project is a subset of the census repository which provides a home for the census data, stored in JSON files, as well as a page for displaying clickable lat/lon pins for carousels on a map of the world.

## Technologies Used

* [jQuery](https://api.jquery.com/) for HTML document traversal and modification
* [Apache Server-Side include (SSI)](https://httpd.apache.org/docs/2.4/howto/ssi.html) for HTML code re-use
* [JSON](https://www.json.org/json-en.html) for map data (Latitude/Longitude) storage
* [Google Maps API](https://developers.google.com/maps/documentation/javascript/examples) for map display
* [Perl](https://www.perl.org/) for census data parsing and display

## How It Works

The driver for the map is the inclusion of MapHeader.html, using SSI, with the jsonTitle variable set, as follows:

```
<!--#set var="jsonTitle" value="/USACensus/LatLongAll"-->
<!--#include virtual="/ssi/MapHeader.html"-->
```

MapHeader.html leverages JQuery to retrieve the map-canvas element, which it then attaches to a Google Map API object. A series of markers are then added to the map, one for each entry from the referenced JSON file.

In addition to displaying the pins on the map, each carousel is clickable, linking to a perl script displaying additional details about that particular carousel.