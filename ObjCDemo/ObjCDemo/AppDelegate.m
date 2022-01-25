//
//  AppDelegate.m
//  ObjCDemo
//
//  Created by Evgen Bodunov on 11/14/16.
//  Copyright © 2016 GetYourMap. All rights reserved.
//

#import "AppDelegate.h"
#import <GLMapCore/GLMapCore.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Insert your API key from https://user.getyourmap.com/apps
    [GLMapManager activateWithApiKey:<#API key#> resourcesBundle:nil andStoragePath:nil];

    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
        navBarAppearance.backgroundColor = UIColor.systemFillColor;
        [navBarAppearance configureWithOpaqueBackground];
        [UINavigationBar appearance].standardAppearance = navBarAppearance;
        [UINavigationBar appearance].scrollEdgeAppearance = navBarAppearance;
    }
    return YES;
}

@end
