import GLMap
import SwiftUI

#if os(iOS)
    private typealias PlatformViewRepresentable = UIViewRepresentable
#else
    private typealias PlatformViewRepresentable = NSViewRepresentable
#endif

struct GLMapViewRepresentable: PlatformViewRepresentable {
    @Binding var center: GLMapGeoPoint
    let zoomLevel: Double
    let onTap: (GLMapGeoPoint) -> Void

    func makeMapView() -> GLMapView {
        let map = GLMapView()
        map.tapGestureBlock = { [weak map] gesture in
            guard let map else { return }
            onTap(map.makeGeoPoint(fromDisplay: gesture.location(in: map)))
        }
        return map
    }

    func update(_ map: GLMapView) {
        map.mapGeoCenter = center
        map.mapZoomLevel = zoomLevel
    }

    #if os(iOS)
        func makeUIView(context _: Context) -> GLMapView { makeMapView() }
        func updateUIView(_ map: GLMapView, context _: Context) { update(map) }
    #else
        func makeNSView(context _: Context) -> GLMapView { makeMapView() }
        func updateNSView(_ map: GLMapView, context _: Context) { update(map) }
    #endif
}
