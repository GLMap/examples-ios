//
//  DownloadMapsViewController.h
//  ObjCDemo
//
//  Created by Evgen Bodunov on 11/15/16.
//  Copyright © 2016 GetYourMap. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadMapsViewController : UITableViewController
{
    NSArray *_allMaps;
    NSMutableArray *_mapsOnDevice, *_mapsOnServer;
}

-(void) setMaps:(NSArray *)maps;

@end
