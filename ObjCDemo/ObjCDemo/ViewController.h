//
//  ViewController.h
//  ObjCDemo
//
//  Created by Evgen Bodunov on 11/14/16.
//  Copyright © 2016 GetYourMap. All rights reserved.
//

#import <UIKit/UIKit.h>

enum Test{
    Test_OfflineMap,
    Test_EmbeddMap,
    Test_OnlineMap,
    Test_OnlineRouting,
    Test_RasterOnlineMap,
    Test_ZoomToBBox,
    Test_OfflineSearch,
    Test_Notifications,
    Test_SingleImage,
    Test_MultiImage,
    Test_Markers,
    Test_MarkersWithClustering,
    Test_MarkersWithMapCSSClustering,
    Test_Track,
    Test_MultiLine,
    Test_Polygon,
    Test_GeoJSON,
    Test_Screenshot,
    Test_Fonts,
    Test_FlyTo,
    Test_TilesBulkDownload,

    Test_StyleReload,
    Test_DownloadMap,
};

@interface ViewController : UITableViewController

@end

