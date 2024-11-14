//
//  GLMapViewRepresentable.swift
//  GLMapSwift
//
//  Created by Evgen Bodunov on 25.04.23.
//  Copyright © 2023 Evgen Bodunov. All rights reserved.
//

import GLMap
import SwiftUI

#if os(iOS)
    private typealias ViewRepresentable = UIViewRepresentable
#elseif os(macOS)
    private typealias ViewRepresentable = NSViewRepresentable
#endif

public typealias MapTapBlock = (GLMapGeoPoint) -> Void

/// This class is made as an example of integrating GLMapView and SwiftUI.
/// It is suitable for simple cases when you need to open a specific location on the map.
/// If you are developing complex logic and will be displaying many objects or interacting with the map,
/// you may need to modify it or work within UIViewControllerRepresentable.
public struct GLMapViewRepresentable: ViewRepresentable {
    public typealias UIViewType = GLMapView

    @Binding var geoCenter: GLMapGeoPoint
    @Binding var zoomLevel: Double

    let showsUserLocation: Bool = false
    let followUser: Bool = false

    let onTap: MapTapBlock?

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject {
        var parent: GLMapViewRepresentable

        init(_ parent: GLMapViewRepresentable) {
            self.parent = parent
        }
    }

    public init(geoCenter: Binding<GLMapGeoPoint> = .constant(GLMapGeoPoint(lat: 53, lon: 27)),
                zoomLevel: Binding<Double> = .constant(5.0),
                onTap: MapTapBlock? = nil)
    {
        _geoCenter = geoCenter
        _zoomLevel = zoomLevel
        self.onTap = onTap
    }

    func makeMapView(_: Context) -> GLMapView {
        let mapView = GLMapView()
        mapView.tapGestureBlock = { [weak mapView] gestureRecognizer in
            guard let onTap, let mapView else { return }
            // convert it there, because there outside there is no access to GLMapView
            let point = gestureRecognizer.location(in: mapView)
            onTap(mapView.makeGeoPoint(fromDisplay: point))
        }
        return mapView
    }

    func updateMapView(_ mapView: GLMapView, context _: Context) {
        mapView.animate { anim in
            mapView.mapZoomLevel = zoomLevel
            anim.fly(to: geoCenter)
        }
    }

    #if os(iOS)
        public func makeUIView(context: Context) -> GLMapView {
            return makeMapView(context)
        }

        public func updateUIView(_ mapView: GLMapView, context: Context) {
            updateMapView(mapView, context: context)
        }
    #else
        public func makeNSView(context: Context) -> GLMapView {
            return makeMapView(context)
        }

        public func updateNSView(_ mapView: GLMapView, context: Context) {
            updateMapView(mapView, context: context)
        }
    #endif
}
