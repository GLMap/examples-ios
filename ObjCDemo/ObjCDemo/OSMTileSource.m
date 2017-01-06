//
//  OSMTileSource.m
//  ObjCDemo
//
//  Created by Evgen Bodunov on 11/15/16.
//  Copyright © 2016 GetYourMap. All rights reserved.
//

#import "OSMTileSource.h"

@implementation OSMTileSource
{
    NSArray *_mirrors;
}

-(instancetype) init
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cacheDir = [paths[0] stringByAppendingPathComponent:@"RasterCache"];
    [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:NO attributes:nil error:nil];
    if(self = [super initWithCachePath:[cacheDir stringByAppendingPathComponent:@"osm.cache"]])
    {
        _mirrors = @[@"https://a.tile.openstreetmap.org/%d/%d/%d.png",
                     @"https://b.tile.openstreetmap.org/%d/%d/%d.png",
                     @"https://c.tile.openstreetmap.org/%d/%d/%d.png",
                     ];
        
        self.validZoomMask = (1<<20)-1; //Set as valid zooms all levels from 0 to 19
        
        //For retina devices we can make tile size a bit smaller.
        if([UIScreen mainScreen].scale >=2)
        {
            self.tileSize = 192;
        }
        
        self.attributionText = @"© OpenStreetMap contributors"; //Change attribution text
    }
    return self;
}

-(NSURL *_Nullable) urlForTilePos:(GLMapTilePos) pos
{
    NSString *mirror = _mirrors[rand()%_mirrors.count];
    NSString *url = [NSString stringWithFormat:mirror, pos.z, pos.x, pos.y];
    NSLog(@"Requested url: %@", url);
    return [NSURL URLWithString:url];
}

@end
