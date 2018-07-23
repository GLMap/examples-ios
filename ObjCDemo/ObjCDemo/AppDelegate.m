//
//  AppDelegate.m
//  ObjCDemo
//
//  Created by Evgen Bodunov on 11/14/16.
//  Copyright © 2016 GetYourMap. All rights reserved.
//

#import "AppDelegate.h"
#import <GLMap/GLMap.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Insert your API key from https://user.getyourmap.com/apps
    [GLMapManager sharedManager].apiKey = <#API key#>;

    return YES;
}

@end
