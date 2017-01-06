//
//  OSMTileSource.swift
//  GLMap
//
//  Created by Evgen Bodunov on 11/21/16.
//  Copyright © 2016 Evgen Bodunov. All rights reserved.
//

import Foundation
import GLMap
import GLMapSwift

class OSMTileSource: GLMapRasterTileSource {
    let mirrors = ["https://a.tile.openstreetmap.org/%d/%d/%d.png",
                   "https://b.tile.openstreetmap.org/%d/%d/%d.png",
                   "https://c.tile.openstreetmap.org/%d/%d/%d.png"]
    
    override init?(cachePath: String?) {
        if cachePath != nil {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let path = documentsPath.appending(cachePath!)
            super.init(cachePath: path)
        } else {
            super.init(cachePath: nil)
        }
        self.validZoomMask = UInt32((1<<20)-1)
        
        //For retina devices we can make tile size a bit smaller.
        if(UIScreen.main.scale >= 2) {
            self.tileSize = 192
        }
        
        self.attributionText = "© OpenStreetMap contributors"
    }
    
    override func url(for pos: GLMapTilePos) -> URL? {
        let urlTemplate = mirrors[Int(arc4random_uniform(UInt32(mirrors.count)))]
        
        return URL(string: String(format: urlTemplate, pos.z, pos.x, pos.y))
    }
}
