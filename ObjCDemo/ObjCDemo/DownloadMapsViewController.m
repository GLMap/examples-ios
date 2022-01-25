//
//  DownloadMapsViewController.m
//  ObjCDemo
//
//  Created by Evgen Bodunov on 11/15/16.
//  Copyright © 2016 GetYourMap. All rights reserved.
//

#import "DownloadMapsViewController.h"
#import <GLMap/GLMap.h>
#import <GLMapCore/GLMapCore.h>

@implementation DownloadMapsViewController

- (void)updateMaps {
    [[GLMapManager sharedManager] updateMapListWithCompletionBlock:^(NSArray *fetchedMaps, BOOL mapListUpdated, NSError *error) {
      if (!error && mapListUpdated)
          [self setMaps:fetchedMaps];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_mapsOnDevice == nil && _mapsOnServer == nil && _allMaps == nil) {
        // Just opened Map list
        NSArray *cachedMapList = [[GLMapManager sharedManager] cachedMapList];
        if (cachedMapList)
            [self setMaps:cachedMapList];

        [self updateMaps];
    } else {
        // refresh map list, in case we deleted submap
        [self setMaps:_allMaps];
    }

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(mapUpdated:) name:kGLMapInfoStateChanged object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(progressUpdated:) name:kGLMapDownloadTaskProgress object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [NSNotificationCenter.defaultCenter removeObserver:self name:kGLMapInfoStateChanged object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:kGLMapDownloadTaskProgress object:nil];
}

- (NSArray *)unrollMapArray:(NSArray *)maps {
    NSMutableArray *unrolledArray = [NSMutableArray arrayWithCapacity:maps.count];
    for (GLMapInfo *info in maps) {
        if (info.subMaps) {
            NSString *groupName = (info.names)[@"en"];
            if ([groupName isEqualToString:@"Africa"] || [groupName isEqualToString:@"Oceania"] ||
                [groupName isEqualToString:@"Caribbean countries"]) {
                [unrolledArray addObjectsFromArray:info.subMaps];
                continue;
            }
        }
        [unrolledArray addObject:info];
    }
    return unrolledArray;
}

- (NSArray *)sortMaps:(NSArray *)maps byDistanceFromLocation:(GLMapGeoPoint)location {
    return [maps sortedArrayUsingComparator:^NSComparisonResult(GLMapInfo *obj1, GLMapInfo *obj2) {
      double a = [obj1 distanceFrom:location];
      double b = [obj2 distanceFrom:location];

      if (a < b)
          return NSOrderedAscending;
      if (a > b)
          return NSOrderedDescending;

      return NSOrderedSame;
    }];
}

- (NSArray *)sortMapsByName:(NSArray *)maps forLocale:(NSString *)localeName {
    return [maps sortedArrayUsingComparator:^NSComparisonResult(GLMapInfo *obj1, GLMapInfo *obj2) {
      return [[obj1 nameInLanguage:localeName] compare:[obj2 nameInLanguage:localeName]];
    }];
}

- (BOOL)isOnDevice:(GLMapInfo *)info {
    return [info stateForDataSet:GLMapInfoDataSet_Map] != GLMapInfoState_NotDownloaded ||
           [info stateForDataSet:GLMapInfoDataSet_Navigation] != GLMapInfoState_NotDownloaded;
}

- (void)setMaps:(NSArray *)maps {
    // Detect and pass user location there. If there is no location detected yet, just don't sort an array by location. ;)
    // GLMapGeoPoint userLocation = GLMapGeoPointMake(40.7, -73.9);
    // maps = [self sortMaps:maps byDistanceFromLocation:userLocation];
    maps = [self sortMapsByName:maps forLocale:@"en"];

    _allMaps = maps;

    NSMutableArray *mapsOnDevice = [[NSMutableArray alloc] init];
    NSMutableArray *mapsOnServer = [[NSMutableArray alloc] init];
    for (GLMapInfo *info in _allMaps) {
        if (info.subMaps.count) {
            NSUInteger downloadedSubMaps = 0;
            for (GLMapInfo *subInfo in info.subMaps) {
                if ([self isOnDevice:subInfo]) {
                    downloadedSubMaps++;
                }
            }

            if (downloadedSubMaps) {
                [mapsOnDevice addObject:info];
            }
            if (downloadedSubMaps != (info.subMaps).count) {
                [mapsOnServer addObject:info];
            }
        } else if ([self isOnDevice:info]) {
            [mapsOnDevice addObject:info];
        } else {
            [mapsOnServer addObject:info];
        }
    }

    _mapsOnDevice = mapsOnDevice;
    _mapsOnServer = mapsOnServer;
    [self.tableView reloadData];
}

- (void)mapUpdated:(NSNotification *)aNotify {
    [self setMaps:_allMaps];
}

- (void)progressUpdated:(NSNotification *)aNotify {
    GLMapDownloadTask *task = aNotify.object;
    [self updateCellForMap:task.map];
}

- (void)updateCellForMap:(GLMapInfo *)map {
    if (_mapsOnDevice) {
        NSUInteger idx = [_mapsOnDevice indexOfObject:map];
        if (idx != NSNotFound) {
            [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForItem:idx inSection:0] ]
                                  withRowAnimation:UITableViewRowAnimationNone];
        } else {
            [self setMaps:_allMaps];
        }
    }
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return _mapsOnDevice.count;
    return _mapsOnServer.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"Maps on device";
    return @"Maps on server";
}

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];

    GLMapInfo *map = nil;
    if (indexPath.section == 0) {
        map = _mapsOnDevice[indexPath.row];

        if ([map.subMaps count]) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = @"";
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;

            GLMapDownloadTask *task = [GLMapManager.sharedManager downloadTaskForMap:map dataSet:GLMapInfoDataSet_Map];
            if (task) {
                double progress = task ? task.downloaded * 100.0 / task.total : 0;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Downloading %.2f%%", progress];
            } else if ([map haveState:GLMapInfoState_NeedUpdate inDataSets:GLMapInfoDataSetMask_All]) {
                cell.detailTextLabel.text = @"Update";
            } else if ([map haveState:GLMapInfoState_NeedResume inDataSets:GLMapInfoDataSetMask_All]) {
                cell.detailTextLabel.text = @"Resume";
            } else {
                cell.accessoryView = nil;

                int64_t size = [map sizeOnDiskForDataSets:GLMapInfoDataSetMask_All];
                if (size != 0) {
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f %@", (double)size / (1000 * 1000), @"MB"];
                } else {
                    cell.detailTextLabel.text = nil;
                }
            }
        }
    } else {
        map = _mapsOnServer[indexPath.row];
        if ([map.subMaps count]) {
            cell.detailTextLabel.text = @"";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            double sizeInMB = (double)[map sizeOnServerForDataSets:GLMapInfoDataSetMask_All] / (1000 * 1000);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f %@", sizeInMB, @"MB"];
        }
    }
    cell.textLabel.text = [map nameInLanguage:@"en"];
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"openSubmap"]) {
        DownloadMapsViewController *vc = (DownloadMapsViewController *)segue.destinationViewController;
        GLMapInfo *map = sender;
        vc.title = [map nameInLanguage:@"en"];
        [vc setMaps:map.subMaps];
    }
}

#pragma mark UITableViewDelegate
- (void)startDownloadingMap:(GLMapInfo *)map retryCount:(int)retryCount {
    if (retryCount > 0) {
        __weak DownloadMapsViewController *wself = self;
        [GLMapManager.sharedManager downloadDataSets:GLMapInfoDataSetMask_All
                                              forMap:map
                                 withCompletionBlock:^(GLMapDownloadTask *task) {
                                   if (task.error) {
                                       NSLog(@"Map downloading error: %@", task.error);
                                       // CURLE_OPERATION_TIMEDOUT = 28 http://curl.haxx.se/libcurl/c/libcurl-errors.html
                                       if ([task.error.domain isEqualToString:@"CURL"] && task.error.code == 28)
                                           [wself startDownloadingMap:map retryCount:retryCount - 1];
                                   }
                                 }];
    }
}

- (void)tableView:(UITableView *)tView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GLMapInfo *map = nil;
    if (indexPath.section == 0) {
        map = _mapsOnDevice[indexPath.row];
    } else {
        map = _mapsOnServer[indexPath.row];
    }

    if ([map.subMaps count]) {
        [self performSegueWithIdentifier:@"openSubmap" sender:map];
    } else {
        GLMapDownloadTask *task = [GLMapManager.sharedManager downloadTaskForMap:map dataSet:GLMapInfoDataSet_Map];
        if (task != nil)
            [task cancel];
        else
            [self startDownloadingMap:map retryCount:3];
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        GLMapInfo *info = _mapsOnDevice[indexPath.row];

        if (info.subMaps.count == 0)
            return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && editingStyle == UITableViewCellEditingStyleDelete) {
        GLMapInfo *map = _mapsOnDevice[indexPath.row];
        if (map) {
            [GLMapManager.sharedManager deleteDataSets:GLMapInfoDataSetMask_All forMap:map];
            [self setMaps:_allMaps];
        }
    }
}

@end
