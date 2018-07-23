//
//  ImageGroup.m
//  GLMap
//
//  Created by Arkadiy Tolkun on 8/30/17.
//  Copyright © 2017 Evgen Bodunov. All rights reserved.
//

#import "ImageGroup.h"

@implementation Pin
@end

@implementation ImageGroup {
    NSRecursiveLock *_lock;
    NSArray *_variants;
    NSMutableArray<Pin *> *_pins;
}

- (instancetype)init {
    if (self = [super init]) {
        _lock = [[NSRecursiveLock alloc] init];
        _pins = [[NSMutableArray alloc] init];

        // Static set of variants
        _variants = @[ [UIImage imageNamed:@"pin1.png"], [UIImage imageNamed:@"pin2.png"], [UIImage imageNamed:@"pin3.png"] ];
    }
    return self;
}

// While updating group - lock other operations
- (void)startUpdate {
    [_lock lock];
}

- (void)endUpdate {
    [_lock unlock];
}

- (NSInteger)getVariantsCount {
    return (uint32_t)_variants.count;
}

- (UIImage *_Nonnull)getVariant:(NSInteger)index offset:(CGPoint *_Nonnull)offset {
    UIImage *rv = _variants[index];
    *offset = CGPointMake(rv.size.width / 2, 0);
    return rv;
}

- (NSInteger)getImagesCount {
    return (uint32_t)_pins.count;
}

- (void)getImageInfo:(NSInteger)index vairiant:(uint32_t *_Nonnull)variant position:(GLMapPoint *_Nonnull)position {
    Pin *pin = _pins[index];
    *position = pin.pos;
    *variant = pin.imageID;
}

- (void)addPin:(Pin *)pin {
    [_lock lock];
    [_pins addObject:pin];
    [_lock unlock];
}

- (void)removePin:(Pin *)pin {
    [_lock lock];
    [_pins removeObject:pin];
    [_lock unlock];
}

- (NSUInteger)count {
    NSUInteger rv;
    [_lock lock];
    rv = _pins.count;
    [_lock unlock];
    return rv;
}

- (Pin *)pinAtLocation:(CGPoint)pt atMap:(GLMapView *)mapView;
{
    Pin *rv = nil;
    [_lock lock];
    CGRect tapRect = CGRectOffset(CGRectMake(-20, -20, 40, 40), pt.x, pt.y);
    for (Pin *pin in _pins) {
        CGPoint pinPos = [mapView makeDisplayPointFromMapPoint:pin.pos];
        if (CGRectContainsPoint(tapRect, pinPos)) {
            rv = pin;
            break;
        }
    }
    [_lock unlock];
    return rv;
}

@end
