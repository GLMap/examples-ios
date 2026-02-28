import Foundation
import GLMap
import GLMapSwift

class OSMTileSource: GLMapRasterTileSource {
    private let mirrors = [
        "https://a.tile.openstreetmap.org/%d/%d/%d.png",
        "https://b.tile.openstreetmap.org/%d/%d/%d.png",
        "https://c.tile.openstreetmap.org/%d/%d/%d.png",
    ]

    override init?(cachePath: String?) {
        if let cachePath {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            super.init(cachePath: (documentsPath as NSString).appendingPathComponent(cachePath))
        } else {
            super.init(cachePath: nil)
        }
        validZoomMask = UInt32((1 << 20) - 1)

        attributionText = "\u{00A9} OpenStreetMap contributors"
    }

    override func url(for pos: GLMapTilePos) -> URL? {
        let urlTemplate = mirrors[Int.random(in: 0 ..< mirrors.count)]
        return URL(string: String(format: urlTemplate, pos.z, pos.x, pos.y))
    }
}
