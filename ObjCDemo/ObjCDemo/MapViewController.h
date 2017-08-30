//
//  MapViewController.h
//  ObjCDemo
//
//  Created by Evgen Bodunov on 11/15/16.
//  Copyright © 2016 GetYourMap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLMap/GLMap.h>

#import "ImageGroup.h"

@interface MapViewController : UIViewController <CLLocationManagerDelegate>

@property (nonatomic, strong) NSNumber *demoScenario;

@property (readonly) ImageGroup *pins; // set of locations
@property (readonly) GLMapImageGroup *mapImageGroup; // object to manage both of them
@property (strong) Pin *pinToDelete;
@property (assign) CGPoint menuPos;

@end
