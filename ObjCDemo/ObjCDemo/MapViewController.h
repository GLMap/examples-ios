//
//  MapViewController.h
//  ObjCDemo
//
//  Created by Evgen Bodunov on 11/15/16.
//  Copyright © 2016 GetYourMap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLMap/GLMap.h>

@class Pin;

@interface MapViewController : UIViewController

@property (nonatomic, strong) NSNumber *demoScenario;

@property (readonly) NSArray *imageIDs; // set of images
@property (readonly) NSMutableArray *pins; // set of locations
@property (readonly) GLMapImageGroup *mapImageGroup; // object to manage both of them
@property (strong) Pin *pinToDelete;
@property (assign) CGPoint menuPos;

@end
