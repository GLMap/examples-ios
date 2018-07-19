//
//  ImageGroup.h
//  GLMap
//
//  Created by Arkadiy Tolkun on 8/30/17.
//  Copyright © 2017 Evgen Bodunov. All rights reserved.
//

#import <GLMap/GLMap.h>

@interface Pin : NSObject
@property(assign) GLMapPoint pos;
@property(assign) int imageID;
@end

@interface ImageGroup : NSObject <GLMapImageGroupDataSource>

- (void)addPin:(Pin *)pin;
- (void)removePin:(Pin *)pin;

- (NSUInteger)count;

- (Pin *)pinAtLocation:(CGPoint)pt atMap:(GLMapView *)mapView;

@end
