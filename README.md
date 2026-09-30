# GLMap iOS examples

This repository contains the reference applications for GLMap SDK 2.2.0. They use Swift Package Manager and the public GLMap binary frameworks.

## Run the examples

1. Open `SwiftDemo/SwiftDemo.xcodeproj` in Xcode.
2. Get an API key from the [GLMap User Dashboard](https://user.globus.software/apps/).
3. Replace `YOUR_API_KEY` locally in the application you want to run (do not commit a real key):
   - `SwiftDemo/SwiftDemo/AppDelegate.swift` for the UIKit catalog;
   - `SwiftDemo/SwiftUIDemo/SwiftUIDemoApp.swift` for the SwiftUI example.
4. Select an iOS simulator or device and run one of the schemes below.

Xcode downloads the GLMap package and binary frameworks when it resolves package dependencies for the first time.

## SwiftDemo

`SwiftDemo` is the UIKit reference application for iOS 15 and later. The catalog contains compact, self-contained examples for:

- map setup, styles, camera animation, and 3D terrain;
- images, markers, tracks, GeoJSON, and user location;
- online and offline search;
- online and offline routing;
- downloading maps and related offline data.

Each catalog screen focuses on one API and keeps setup next to the code that uses it. The **Demo Mode** button above the catalog runs one continuous, 26-second story on the Amalfi Coast: explore the map with contour lines, find a restaurant, reveal a walking route, then follow a simulated walker in 3D. The traversed route turns grey using `GLMapTrack.progressIndex` and `progressColor`; the camera and marker share the same distance-based timeline. The walking segment is explicitly labeled as an accelerated route preview, not real GPS navigation. It uses real online search results and routing data; the compact UI and animated markers are part of the demo app, not SDK-provided controls. Tap anywhere to return to the catalog. The individual screens remain the code examples to learn from.

### Tests

The `SwiftDemo` scheme includes simulator tests for screen lifecycle, bundled offline data, GeoJSON loading, and Demo Mode layout. Run them with **Product → Test** in Xcode; no API key is needed for these checks.

The timeline, distance-based track progress, and heading interpolation have standalone tests that do not require UIKit, an API key, or a simulator:

```sh
swiftc SwiftDemo/SwiftDemo/DemoMode/DemoTourMotion.swift tests/DemoTourMotionTests.swift -o /tmp/demo-motion-tests
/tmp/demo-motion-tests
```

All map markers — restaurants, start, arrival ring, and the simulated walker — use native `GLMapImage` drawables that account for terrain height. UIKit is used only for screen-space captions and panels. The grey traversed prefix is the same native track, recolored through `progressIndex` / `progressColor`. Camera bearing is spatially smoothed and interpolated along the shortest angular path; `mapOrigin` keeps the walker below screen center. No location-manager permission or real GPS feed is involved.

## SwiftUIDemo

`SwiftUIDemo` is a minimal SwiftUI integration for iOS 16.2 and later. It wraps `GLMapView` with `UIViewRepresentable`, keeps the map center in a SwiftUI binding, and handles map taps without adding an application-specific architecture layer.

## SDK 2.2.0 API notes

- Both apps check the Boolean result of `GLMapManager.activate(apiKey:)` before using the SDK. A failure means resource/storage initialization failed; this does not validate the API key.
- `GLMapSwift` re-exports the Core Swift conveniences, so existing `import GLMap` / `import GLMapSwift` clients continue to work with the modular SDK.
- `GeoJSONDemo` handles the result passed to `setVectorObjects` completion: `.ready`, `.superseded`, `.cancelled`, or `.failed`. Updates and completions run on the main thread; `.ready` means geometry is ready to draw, not that a frame has been presented. Examples that do not need the outcome omit the completion.

## More information

- [GLMap documentation](https://globus.software/docs)
- [GLMap website](https://globus.software/)
- [support@globus.software](mailto:support@globus.software)
