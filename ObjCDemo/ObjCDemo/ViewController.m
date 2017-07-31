//
//  ViewController.m
//  ObjCDemo
//
//  Created by Evgen Bodunov on 11/14/16.
//  Copyright © 2016 GetYourMap. All rights reserved.
//

#import "ViewController.h"
#import "MapViewController.h"
#import <GLMap/GLMap.h>

@interface ViewController ()
@end

@implementation ViewController {
    NSArray *_tableItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"GLMap examples";
    
    _tableItems = @[
                    @{@"name":@"Open offline map"},
                    @{@"name":@"Open embedd map"},
                    @{@"name":@"Open online map", @"descr": @"Downloads tiles one by one"},
                    @{@"name":@"Raster online map", @"descr": @"Downloads raster tiles one by one from custom tile source"},
                    @{@"name":@"Zoom to bbox"},
                    @{@"name":@"Offline Search"},
                    @{@"name":@"Notification test"},
                    @{@"name":@"GLMapImage demo", @"descr":@"For one pin or any other image"},
                    @{@"name":@"GLMapImageGroup demo", @"descr":@"For large set of pins with smaller set of images"},
                    @{@"name":@"GLMapMarkerLayer demo"},
                    @{@"name":@"GLMapMarkerLayer with clustering"},
                    @{@"name":@"GLMapMarkerLayer with mapcss clustering"},

                    @{@"name":@"Add multiline"},
                    @{@"name":@"Add polygon"},
                    @{@"name":@"Load GeoJSON"},
                    @{@"name":@"Take screenshot"},
                    @{@"name":@"Fonts"},
                    @{@"name":@"Fly to"},
                    
                    @{@"name":@"Style live reload"},
                    @{@"name":@"Download offline map"}
                    ];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[GLMapManager sharedManager] clearCaches];
    
    // temporary
    //[self performSegueWithIdentifier:@"Map" sender:[NSNumber numberWithInteger:13]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _tableItems.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"SimpleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSDictionary *cellInfo = _tableItems[indexPath.row];
    
    cell.textLabel.text = cellInfo[@"name"];
    cell.detailTextLabel.text = cellInfo[@"descr"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == Test_DownloadMap) {
        [self performSegueWithIdentifier:@"DownloadMaps" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"Map" sender:@(indexPath.row)];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Map"]) {
        MapViewController *mapVC = (MapViewController *)segue.destinationViewController;
        mapVC.demoScenario = sender;
    }
}

@end
