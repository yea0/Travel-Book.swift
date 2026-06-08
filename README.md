# Travel Book

Travel Book is a UIKit iOS app for saving memorable places on a map. Users can drop a pin with a long press, add a place name and note, then revisit saved locations from a Core Data backed list.

## Highlights

- Save travel locations with a title, note, latitude, and longitude.
- Browse saved places in a reusable table view.
- Open saved places on the map with their original annotation.
- Edit existing places and save the updated location details.
- Delete saved places with standard table swipe actions.
- Persist data locally with Core Data.
- Center the map on the user's current location when permission is granted.

## Tech Stack

- Swift
- UIKit
- MapKit
- CoreLocation
- Core Data
- Storyboards

## Project Structure

```text
TravelBook/
  TravelBook/
    PlacesListViewController.swift # Saved places list
    ViewController.swift     # Map and place detail screen
    AppDelegate.swift        # App lifecycle and Core Data stack
    SceneDelegate.swift      # Scene lifecycle
    Base.lproj/              # Storyboard files
    TravelBook.xcdatamodeld/ # Core Data model
```

## Getting Started

1. Open `TravelBook/TravelBook.xcodeproj` in Xcode.
2. Select a simulator or a physical iPhone target.
3. Build and run the `TravelBook` scheme.
4. Allow location access when prompted.
5. Long-press the map to drop a pin, enter details, and tap `Save`.

## Core Data Model

The app stores each place in the `Place` entity:

- `id`: UUID
- `title`: String
- `subtitle`: String
- `latitude`: Double
- `longitude`: Double

## Recent Improvements

- Replaced force-heavy Core Data reads with guarded fetch handling.
- Added input validation so empty names and missing map pins are not saved.
- Added edit support for existing saved places.
- Added swipe-to-delete support in the saved places list.
- Added table view reuse, empty-state messaging, and sorted results.
- Improved location permission messaging and stopped repeated map recentering after the first location update.

## Roadmap

- Add search and filtering for saved places.
- Add unit tests around Core Data persistence.
- Add snapshot tests for the list and detail screens.
- Add custom map annotation views.
- Add an export/share flow for saved locations.
