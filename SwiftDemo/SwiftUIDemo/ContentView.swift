import GLMap
import SwiftUI

struct ContentView: View {
    @State private var center = GLMapGeoPoint(lat: 41.1579, lon: -8.6291) // Porto

    var body: some View {
        GLMapViewRepresentable(center: $center, zoomLevel: 14) { center = $0 }
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Text("Tap the map to move its center")
                    .padding()
                    .background(.regularMaterial, in: Capsule())
                    .padding()
            }
    }
}

#Preview {
    ContentView()
}
