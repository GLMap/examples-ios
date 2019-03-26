//
//  MapViewController.m
//  ObjCDemo
//
//  Created by Evgen Bodunov on 11/15/16.
//  Copyright © 2016 GetYourMap. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <GLMap/GLMap.h>
#import <GLRoute/GLRoute.h>
#import <GLSearch/GLSearch.h>

#import "DownloadMapsViewController.h"
#import "MapViewController.h"
#import "OSMTileSource.h"
#import "ViewController.h"

@implementation MapViewController {
    UIButton *_downloadButton;

    GLMapView *_mapView;
    GLMapDrawable *_mapImage;
    GLMapInfo *_mapToDownload;
    BOOL _flashAdd;

    CLLocationManager *_locationManager;

    GLMapTrackData *_trackData;
    GLMapTrack *_track;

    // Routing Demo
    UISegmentedControl *_routingMode, *_networkMode;
    GLMapGeoPoint _startPoint, _endPoint, _menuPoint;
    GLMapTrack *_routeTrack;
    NSString *_valhallaConfig;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Demo map";

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadButtonText:)
                                                 name:kGLMapDownloadTaskProgress
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadButton)
                                                 name:kGLMapDownloadTaskFinished
                                               object:nil];

    _mapView = [[GLMapView alloc] initWithFrame:self.view.bounds];
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_mapView];

    _locationManager = [[CLLocationManager alloc] init];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [_locationManager requestWhenInUseAuthorization];
    }
    // In order to show user location using GLMapView you should create your own CLLocationManager and set GLMapView as CLLocationManager's
    // delegate. Or you could forward `-locationManager:didUpdateLocations:` calls from your location manager delegate to the GLMapView.
    _locationManager.delegate = _mapView;
    [_locationManager startUpdatingLocation];
    [_mapView setShowUserLocation:YES];

    _downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _downloadButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _downloadButton.backgroundColor = [UIColor lightTextColor];
    [_downloadButton addTarget:self action:@selector(downloadButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];

    _downloadButton.frame = CGRectMake(0, 0, 220, 30);
    _downloadButton.center = self.view.center;
    _downloadButton.hidden = YES;

    [self.view addSubview:_downloadButton];

    //_downloadButton.hidden = YES;
    [self updateDownloadButton];
    // Map list is updated, because download button depends on available map list and during first launch this list is empty
    [[GLMapManager sharedManager] updateMapListWithCompletionBlock:nil];

    __weak MapViewController *wself = self;
    _mapView.centerTileStateChangedBlock = ^{
      [wself updateDownloadButton];
    };

    _mapView.mapDidMoveBlock = ^(GLMapBBox bbox) {
      [wself updateDownloadButtonText:nil];
    };

    int scenario = _demoScenario.intValue;
    switch (scenario) {
    case Test_OfflineMap: // open map
        // nothing to do. just start rendering inside viewWillAppear
        break;
    case Test_EmbeddMap: // load map from app resources
        [self loadEmbedMap];
        break;
    case Test_OnlineMap:
        [GLMapManager sharedManager].tileDownloadingAllowed = YES;

        // Move map to the San Francisco
        _mapView.mapGeoCenter = GLMapGeoPointMake(37.3257, -122.0353);
        _mapView.mapZoomLevel = 14;
        break;
    case Test_Routing:
        [self testRouting];
        break;
    case Test_RasterOnlineMap:
        _mapView.rasterTileSources = @[ [[OSMTileSource alloc] init] ];
        break;
    case Test_ZoomToBBox: // zoom to bbox
        [self zoomToBBox];
        break;
    case Test_OfflineSearch:
        [self offlineSearch];
        break;
    case Test_Notifications:
        [self testNotifications];
        break;
    case Test_SingleImage: // add/remove image
    {
        [self singleImage];
        break;
    }
    case Test_MultiImage: // add pin from navigation item, remove by tap on pin
    {
        [self displayAlertWithTitle:nil message:@"Long tap on map to add pin, tap on pin to remove it"];

        [self setupPinGestures];
        break;
    }
    case Test_Markers:
        [self addMarkers];
        break;
    case Test_MarkersWithClustering:
        [self addMarkersWithClustering];
        break;
    case Test_MarkersWithMapCSSClustering:
        [self addMarkersWithMapCSSClustering];
        break;
    case Test_Track:
        [self recordGPSTrack];
        break;
    case Test_MultiLine:
        [self addMultiline];
        break;
    case Test_Polygon:
        [self addPolygon];
        break;
    case Test_GeoJSON:
        [self loadGeoJSON];
        break;
    case Test_Screenshot: {
        NSLog(@"Start capturing frame");
        [_mapView captureFrameWhenFinish:^(UIImage *img) { // completion handler called in main thread
          UIAlertController *alert =
              [UIAlertController alertControllerWithTitle:nil
                                                  message:[NSString stringWithFormat:@"Image captured %p\n %.0fx%.0f\nscale %.0f", img,
                                                                                     img.size.width, img.size.height, img.scale]
                                           preferredStyle:UIAlertControllerStyleAlert];

          [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

          [self presentViewController:alert animated:YES completion:nil];
        }];
        break;
    }
    case Test_FlyTo: {
        // we'll just add button for this demo
        UIBarButtonItem *barButton =
            [[UIBarButtonItem alloc] initWithTitle:@"Fly" style:UIBarButtonItemStylePlain target:self action:@selector(flyTo:)];
        self.navigationItem.rightBarButtonItem = barButton;

        // Move map to the San Francisco
        [_mapView animate:^(GLMapAnimation *_Nonnull animation) {
          self->_mapView.mapZoomLevel = 14;
          [animation flyToGeoPoint:GLMapGeoPointMake(37.3257, -122.0353)];
        }];
        [GLMapManager sharedManager].tileDownloadingAllowed = YES;
        break;
    }
    case Test_Fonts: {
        GLMapVectorObjectArray *objects = [GLMapVectorObject
            createVectorObjectsFromGeoJSON:@"[{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 64]}, "
                                           @"\"properties\": {\"id\": \"1\"}},"
                                            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 63]}, "
                                            "\"properties\": {\"id\": \"2\"}},"
                                            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 62]}, "
                                            "\"properties\": {\"id\": \"3\"}},"
                                            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 61]}, "
                                            "\"properties\": {\"id\": \"4\"}},"
                                            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 60]}, "
                                            "\"properties\": {\"id\": \"5\"}},"
                                            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 58]}, "
                                            "\"properties\": {\"id\": \"6\"}},"
                                            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-20, 55]}, "
                                            "\"properties\": {\"id\": \"7\"}},"
                                            "{\"type\":\"Polygon\",\"coordinates\":[[ [-30, 50], [-30, 80], [-10, 80], [-10, 50] ]]}]"];

        GLMapVectorCascadeStyle *style =
            [GLMapVectorCascadeStyle createStyle:@"node[id=1]{text:'Test12';text-color:black;font-size:5;text-priority:100;}"
                                                  "node[id=2]{text:'Test12';text-color:black;font-size:10;text-priority:100;}"
                                                  "node[id=3]{text:'Test12';text-color:black;font-size:15;text-priority:100;}"
                                                  "node[id=4]{text:'Test12';text-color:black;font-size:20;text-priority:100;}"
                                                  "node[id=5]{text:'Test12';text-color:black;font-size:25;text-priority:100;}"
                                                  "node[id=6]{text:'Test12';text-color:black;font-size:30;text-priority:100;}"
                                                  "node[id=6]{text:'Test12';text-color:black;font-size:60;text-priority:100;}"
                                                  "area{fill-color:white; layer:100;}"];

        GLMapDrawable *drawable = [GLMapDrawable.alloc init];
        [drawable setVectorObjects:objects withStyle:style completion:nil];
        [_mapView add:drawable];

        UIView *testView = [[UIView alloc] initWithFrame:CGRectMake(350, 200, 150, 200)];
        UIView *testView2 = [[UIView alloc] initWithFrame:CGRectMake(200, 200, 150, 200)];
        testView.backgroundColor = [UIColor blackColor];
        testView2.backgroundColor = [UIColor whiteColor];
        float y = 0;

        for (int i = 0; i < 7; ++i) {
            UIFont *font = [UIFont fontWithName:@"NotoSans" size:5 + 5 * i];

            UILabel *lbl = [[UILabel alloc] init];
            lbl.text = @"Test12";
            lbl.font = font;
            lbl.textColor = [UIColor whiteColor];
            [lbl sizeToFit];
            lbl.frame = CGRectMake(0, y, lbl.frame.size.width, lbl.frame.size.height);
            [testView addSubview:lbl];

            UILabel *lbl2 = [[UILabel alloc] init];
            lbl2.text = @"Test12";
            lbl2.font = font;
            lbl2.textColor = [UIColor blackColor];
            [lbl2 sizeToFit];
            lbl2.frame = CGRectMake(0, y, lbl2.frame.size.width, lbl2.frame.size.height);
            [testView2 addSubview:lbl2];

            y += lbl.frame.size.height;
        }
        [_mapView addSubview:testView];
        [_mapView addSubview:testView2];

        break;
    }

    case Test_TilesBulkDownload: {
        UIBarButtonItem *barButton =
            [[UIBarButtonItem alloc] initWithTitle:@"Download" style:UIBarButtonItemStylePlain target:self action:@selector(bulkDownload)];
        self.navigationItem.rightBarButtonItem = barButton;
        _mapView.mapCenter = GLMapPointMakeFromGeoCoordinates(53, 27);
        _mapView.mapZoomLevel = 12.5;
        break;
    }
    case Test_StyleReload: {
        UITextField *textField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, 21.0)];
        textField.placeholder = @"Enter style URL";
        self.navigationItem.titleView = textField;

        [textField becomeFirstResponder];

        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Reload style"
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(reloadStyle)];
        self.navigationItem.rightBarButtonItem = barButton;
    }

    default:
        break;
    }
}

// Stop rendering when map is hidden to save resources on CADisplayLink calls
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Remove link to self from flashObject:
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Example how to add map from resources.
- (void)loadEmbedMap {
    [[GLMapManager sharedManager] addMap:[[NSBundle mainBundle] pathForResource:@"Montenegro" ofType:@"vm"]];
    //[[GLMapManager manager] addMapWithPath:[[NSBundle mainBundle] pathForResource:@"Belarus" ofType:@"vm"]];
    // Move map to the Montenegro capital
    _mapView.mapGeoCenter = GLMapGeoPointMake(42.4341, 19.26);
    _mapView.mapZoomLevel = 14;
}

- (void)testRouting {
    NSError *error = nil;
    _valhallaConfig = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"valhalla" ofType:@"json"] encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Can't load valhalla.json");
        return;
    }
    
    _routingMode = [[UISegmentedControl alloc] initWithItems:@[ @"Auto", @"Bike", @"Walk" ]];
    _routingMode.selectedSegmentIndex = 0;
    [_routingMode addTarget:self action:@selector(updateRoute) forControlEvents:UIControlEventValueChanged];

    _networkMode = [[UISegmentedControl alloc] initWithItems:@[ @"Online", @"Offline" ]];
    _networkMode.selectedSegmentIndex = 0;
    [_networkMode addTarget:self action:@selector(updateRoute) forControlEvents:UIControlEventValueChanged];

    self.navigationItem.rightBarButtonItems =
        @[ [[UIBarButtonItem alloc] initWithCustomView:_routingMode], [[UIBarButtonItem alloc] initWithCustomView:_networkMode] ];
    self.navigationItem.prompt = @"Tap on map to select departure and destination points";

    _startPoint = GLMapGeoPointMake(53.844720, 27.482352);
    _endPoint = GLMapGeoPointMake(53.931935, 27.583995);

    GLMapBBox bbox = GLMapBBoxEmpty;
    bbox = GLMapBBoxAddPoint(bbox, GLMapPointFromMapGeoPoint(_startPoint));
    bbox = GLMapBBoxAddPoint(bbox, GLMapPointFromMapGeoPoint(_endPoint));
    _mapView.mapCenter = GLMapBBoxCenter(bbox);
    _mapView.mapZoom = [_mapView mapZoomForBBox:bbox viewSize:_mapView.bounds.size] / 2;

    // we'll look for in resources default style path first, then in app bundle. After that we could load our images in GLMapVectorStyle, e.g. track-arrows.svgpb
    [_mapView loadStyleFromPaths:@[[[NSBundle mainBundle] pathForResource:@"DefaultStyle" ofType:@"bundle"], [[NSBundle mainBundle] bundlePath]]];
    
    __weak GLMapView *wMap = _mapView;
    __weak MapViewController *wself = self;
    _mapView.tapGestureBlock = ^(CGPoint pt) {
      UIMenuController *menu = [UIMenuController sharedMenuController];
      if (!menu.menuVisible) {
          wself.menuPoint = GLMapGeoPointFromMapPoint([wMap makeMapPointFromDisplayPoint:pt]);
          [wself becomeFirstResponder];
          [menu setTargetRect:CGRectMake(pt.x, pt.y, 1, 1) inView:wMap];
          menu.menuItems = @[
              [[UIMenuItem alloc] initWithTitle:@"Departure" action:@selector(setDeparture:)],
              [[UIMenuItem alloc] initWithTitle:@"Destination" action:@selector(setDestination:)]
          ];
          [menu setMenuVisible:YES animated:YES];
      }
    };
    [self updateRoute];
}

- (void)setDeparture:(id)sender {
    _startPoint = _menuPoint;
    [self updateRoute];
}

- (void)setDestination:(id)sender {
    _endPoint = _menuPoint;
    [self updateRoute];
}

- (void)updateRoute {
    GLRoutePoint pts[2] = {GLRoutePointMake(_startPoint, NAN, YES), GLRoutePointMake(_endPoint, NAN, YES)};

    GLMapRouteMode mode;
    if (_routingMode.selectedSegmentIndex == 0) {
        mode = GLMapRouteMode_Drive;
    } else if (_routingMode.selectedSegmentIndex == 1) {
        mode = GLMapRouteMode_Cycle;
    } else {
        mode = GLMapRouteMode_Walk;
    }

    GLRouteCompletionBlock completion = ^(GLRoute *result, NSError *error) {
      if (result) {
          GLMapTrackData *trackData = [result trackDataWithColor:GLMapColorMake(50, 200, 0, 200)];
          if (self->_routeTrack)
              [self->_routeTrack setTrackData:trackData];
          else {
              self->_routeTrack = [[GLMapTrack alloc] initWithDrawOrder:5 andTrackData:trackData];
              [self->_routeTrack setStyle:[GLMapVectorStyle createStyle:@"{width: 7pt; fill-image:\"track-arrow.svgpb\";}"]];
              [self->_mapView add:self->_routeTrack];
          }
      }

      if (error) {
          [self displayAlertWithTitle:@"Routing error" message:[error description]];
      }
    };
    if (_networkMode.selectedSegmentIndex == 0)
        [GLRoute requestRouteWithPoints:pts
                                         count:2
                                          mode:mode
                                        locale:@"en"
                                         units:GLUnitSystem_International
                               completionBlock:completion];
    else
        [GLRoute offlineRequestRouteWithConfig:_valhallaConfig
                                               points:pts
                                                count:2
                                                 mode:mode
                                               locale:@"en"
                                                units:GLUnitSystem_International
                                      completionBlock:completion];
}

// Example how to calcludate zoom level for some bbox
- (void)zoomToBBox {
    GLMapBBox bbox = GLMapBBoxEmpty;
    // Berlin
    bbox = GLMapBBoxAddPoint(bbox, GLMapPointMakeFromGeoCoordinates(52.5037, 13.4102));
    // Minsk
    bbox = GLMapBBoxAddPoint(bbox, GLMapPointMakeFromGeoCoordinates(53.9024, 27.5618));
    // set center point and change zoom to make screenDistance less or equal mapView.bounds
    _mapView.mapCenter = GLMapBBoxCenter(bbox);
    _mapView.mapZoom = [_mapView mapZoomForBBox:bbox viewSize:_mapView.bounds.size];
}

- (void)offlineSearch {
    // Offline search works only with offline maps. Online tiles does not contains search index
    [[GLMapManager sharedManager] addMap:[[NSBundle mainBundle] pathForResource:@"Montenegro" ofType:@"vm"]];

    // Move map to the Montenegro capital
    GLMapGeoPoint center = GLMapGeoPointMake(42.4341, 19.26);

    _mapView.mapGeoCenter = center;
    _mapView.mapZoomLevel = 14;

    // Create new offline search request
    GLSearch *searchOffline = [[GLSearch alloc] init];
    // Set center of search. Objects that is near center will recive bonus while sorting happens
    searchOffline.center = GLMapPointMakeFromGeoCoordinates(center.lat, center.lon);
    // Set maximum number of results. By default is is 100
    searchOffline.limit = 20;
    // Set locale settings. Used to boost results with locales native to user
    searchOffline.localeSettings = _mapView.localeSettings;

    NSArray<GLSearchCategory *> *category =
        [GLSearchCategories.sharedCategories categoriesStartedWith:@[ @"food" ] localeSettings:_mapView.localeSettings]; // find categories by name
    if (category.count != 0) {
        NSString *name = [category[0] localizedName:_mapView.localeSettings].asString;
        NSLog(@"Searching %@", name);
        [searchOffline addFilter:[[GLSearchFilter alloc] initWithCategory:category[0]]]; // Filter results by category
    }

    // You can add more filters. For example by name
    //[searchOffline addNameFilter:@"cali"]; //Add filter by name

    [searchOffline startWithCompletionBlock:^(NSArray<GLMapVectorObject *> *_Nonnull results) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self displaySearchResults:results];
      });
    }];
}

- (void)displaySearchResults:(NSArray<GLMapVectorObject *> *)results {
    GLMapMarkerStyleCollection *style = [[GLMapMarkerStyleCollection alloc] init];
    [style addStyleWithImage:[[GLMapVectorImageFactory sharedFactory]
                                 imageFromSvgpb:[[NSBundle mainBundle] pathForResource:@"cluster" ofType:@"svgpb"]
                                      withScale:0.2
                                   andTintColor:GLMapColorMake(0xFF, 0, 0, 0xFF)]];

    // If marker layer constructed using NSArray with object of any type you need to set markerLocationBlock
    [style setMarkerLocationBlock:^(NSObject *_Nonnull marker) {
      if ([marker isKindOfClass:[GLMapVectorObject class]]) {
          GLMapVectorObject *obj = (GLMapVectorObject *)marker;
          return obj.point;
      }
      return GLMapPointMake(0, 0);
    }];

    // Additional data for markers will be requested only for markers that are visible or not far from bounds of screen.
    [style setMarkerDataFillBlock:^(NSObject *_Nonnull marker, GLMapMarkerData _Nonnull data) {
      GLMapMarkerSetStyle(data, 0);
    }];

    GLMapMarkerLayer *layer = [[GLMapMarkerLayer alloc] initWithMarkers:results andStyles:style clusteringRadius:0 drawOrder:2];
    [_mapView add:layer];

    // Zoom to results
    if (results.count != 0) {
        // Calculate bbox
        GLMapBBox bbox = GLMapBBoxEmpty;
        for (GLMapVectorObject *object in results)
            bbox = GLMapBBoxAddPoint(bbox, object.point);

        [_mapView setMapCenter:GLMapBBoxCenter(bbox)];
        [_mapView setMapZoom:[_mapView mapZoomForBBox:bbox]];
    }
}

#pragma mark Download button
- (void)updateDownloadButtonText:(NSNotification *)aNotify {
    if (_mapView.centerTileState == GLMapTileState_NoData) {
        GLMapPoint center = [_mapView mapCenter];

        _mapToDownload = [[GLMapManager sharedManager] mapAtPoint:center];

        if (_mapToDownload && ([_mapToDownload stateForDataSet:GLMapInfoDataSet_Map] == GLMapInfoState_Downloaded ||
                               [_mapToDownload distanceFromBorder:center] > 0)) {
            _mapToDownload = nil;
        }

        if (_mapToDownload) {
            GLMapDownloadTask *task = [[GLMapManager sharedManager] downloadTaskForMap:_mapToDownload];
            NSString *title;
            if (task) {
                title = [NSString
                    stringWithFormat:@"Downloading %@ \u202A%d%%\u202C", [_mapToDownload name], (int)(task.downloaded * 100 / task.total)];
            } else {
                title = [NSString stringWithFormat:@"Download %@", [_mapToDownload name]];
            }
            [_downloadButton setTitle:title forState:UIControlStateNormal];
        } else {
            [_downloadButton setTitle:@"Download Maps" forState:UIControlStateNormal];
        }
    }
}

- (void)updateDownloadButton {
    switch (_mapView.centerTileState) {
    case GLMapTileState_HasData:
        if (!_downloadButton.hidden) {
            _downloadButton.hidden = YES;
        }
        break;
    case GLMapTileState_NoData:
        if (_downloadButton.hidden) {
            [self updateDownloadButtonText:nil];
            _downloadButton.hidden = NO;
        }
        break;
    case GLMapTileState_Updating:
        break;
    }
}

- (void)downloadButtonTouchUp:(UIButton *)sender {
    if (_mapToDownload) {
        GLMapDownloadTask *task = [[GLMapManager sharedManager] downloadTaskForMap:_mapToDownload];
        if (task) {
            [task cancel];
        } else {
            [[GLMapManager sharedManager] downloadDataSets:GLMapInfoDataSetMask_All forMap:_mapToDownload withCompletionBlock:nil];
        }
    } else {
        [self performSegueWithIdentifier:@"DownloadMaps" sender:self];
    }
}

- (void)loadImageAtURL:(NSURL *)url intoDrawable:(GLMapDrawable *)drawable {
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            UIImage *img = [UIImage imageWithData:data];
            if (img) {
                [drawable setImage:img forMapView:self->_mapView completion:nil];
            }
        }
    }] resume];
}

#pragma mark Add/move/remove image
- (void)singleImage {
    // we'll just add button for this demo
    UIBarButtonItem *barButton =
        [[UIBarButtonItem alloc] initWithTitle:@"Add image" style:UIBarButtonItemStylePlain target:self action:@selector(addImage:)];
    self.navigationItem.rightBarButtonItem = barButton;
    [self addImage:barButton];

    // Drawables created using default constructor is added on map as polygon with layer:0; and z-index:0;
    {
        // original tile url is https://tile.openstreetmap.org/3/4/2.png
        // we'll show how to calculate it's position on map in GLMapPoints
        int tilePosZ = 3, tilePosX = 4, tilePosY = 2;

        // world size divided to number of tiles at this zoom level
        int tilesForZoom = (1 << tilePosZ);
        int32_t tileSize = GLMapPointMax / tilesForZoom;

        GLMapDrawable *drawable = [GLMapDrawable.alloc init];
        drawable.transformMode = GLMapTransformMode_Custom;
        drawable.rotatesWithMap = YES;
        drawable.scale = GLMapPointMax / (tilesForZoom * 256);
        drawable.position = GLMapPointMake(tileSize * tilePosX, (tilesForZoom - tilePosY - 1) * tileSize);
        [_mapView add:drawable];

        [self loadImageAtURL:[NSURL URLWithString:@"https://tile.openstreetmap.org/3/4/2.png"] intoDrawable:drawable];
    }

    // Drawable can draw a text
    {
        GLMapDrawable *drawable = [GLMapDrawable.alloc init];
        [drawable setText:@"Text2"
                withStyle:[GLMapVectorStyle createStyle:@"{text-color:green;font-size:12;font-stroke-width:1pt;font-stroke-color:#FFFFFFEE;}"]
               completion:nil];
        drawable.position = GLMapPointMakeFromGeoCoordinates(54, 0);
        [_mapView add:drawable];
    }

    // Drawables created with DrawOrder displayed on top of the map. Draw order is used to sort drawables.
    {
        int tilePosZ = 3, tilePosX = 4, tilePosY = 3;

        // world size divided to number of tiles at this zoom level
        int tilesForZoom = (1 << tilePosZ);
        int32_t tileSize = GLMapPointMax / tilesForZoom;

        GLMapDrawable *drawable = [[GLMapDrawable alloc] initWithDrawOrder:0];
        drawable.transformMode = GLMapTransformMode_Custom;
        drawable.rotatesWithMap = YES;
        drawable.scale = GLMapPointMax / (tilesForZoom * 256);
        drawable.position = GLMapPointMake(tileSize * tilePosX, (tilesForZoom - tilePosY - 1) * tileSize);
        [_mapView add:drawable];

        [self loadImageAtURL:[NSURL URLWithString:@"https://tile.openstreetmap.org/3/4/3.png"] intoDrawable:drawable];
    }

    {
        GLMapDrawable *drawable = [[GLMapDrawable alloc] initWithDrawOrder:0];
        [drawable setText:@"Text1"
                withStyle:[GLMapVectorStyle createStyle:@"{text-color:red;font-size:12;font-stroke-width:1pt;font-stroke-color:#FFFFFFEE;}"]
               completion:nil];
        drawable.position = GLMapPointMakeFromGeoCoordinates(60, 0);
        [_mapView add:drawable];
    }
}

- (void)addImage:(id)sender {
    UIBarButtonItem *button = sender;
    button.title = @"Move image";
    button.action = @selector(moveImage:);

    UIImage *img = [UIImage imageNamed:@"pin1.png"];
    if (img) {
        _mapImage = [[GLMapDrawable alloc] initWithDrawOrder:3];
        // This is optimized version. Sets image that will be draw only at give mapView and does not retain image
        [_mapImage setImage:img forMapView:_mapView completion:nil];
        _mapImage.position = _mapView.mapCenter;
        _mapImage.offset = CGPointMake(img.size.width / 2, 0);
        _mapImage.angle = arc4random_uniform(360);
        _mapImage.rotatesWithMap = YES;
        [_mapView add:_mapImage];
    }
}

- (void)moveImage:(id)sender {
    UIBarButtonItem *button = sender;
    button.title = @"Remove image";
    button.action = @selector(delImage:);

    if (_mapImage) {
        [_mapView animate:^(GLMapAnimation *animation) {
          [animation setTransition:GLMapTransitionEaseInOut];
          [animation setDuration:1];
          self->_mapImage.position = self->_mapView.mapCenter;
          self->_mapImage.angle = arc4random_uniform(360);
        }];
    }
}

- (void)delImage:(id)sender {
    UIBarButtonItem *button = sender;
    button.title = @"Add image";
    button.action = @selector(addImage:);

    if (_mapImage) {
        [_mapView remove:_mapImage];
        _mapImage = nil;
    }
}

#pragma mark Test pin
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)addPin:(id)sender {
    if (!_mapImageGroup) {
        _pins = [[ImageGroup alloc] init];
        _mapImageGroup = [[GLMapImageGroup alloc] initWithCallback:_pins andDrawOrder:3];
        [_mapView add:_mapImageGroup];
    }

    Pin *pin = [[Pin alloc] init];
    pin.pos = [_mapView makeMapPointFromDisplayPoint:_menuPos];

    // to iterate over images pin1, pin2, pin3, pin1, pin2, pin3
    pin.imageID = _pins.count % 3;
    [_pins addPin:pin];
    [_mapImageGroup setNeedsUpdate:NO];
}

- (void)deletePin:(id)sender {
    [_pins removePin:_pinToDelete];
    [_mapImageGroup setNeedsUpdate:NO];
    _pinToDelete = nil;
    if (_pins.count == 0) {
        [_mapView remove:_mapImageGroup];
        _mapImageGroup = nil;
        _pins = nil;
    }
}

// Example how to interact with user
- (void)setupPinGestures {
    __weak GLMapView *weakmap = _mapView;
    __weak MapViewController *wself = self;
    _mapView.longPressGestureBlock = ^(CGPoint pt) {
      UIMenuController *menu = [UIMenuController sharedMenuController];
      if (!menu.menuVisible) {
          wself.menuPos = pt;
          [wself becomeFirstResponder];
          [menu setTargetRect:CGRectMake(wself.menuPos.x, wself.menuPos.y, 1, 1) inView:weakmap];
          menu.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Add pin" action:@selector(addPin:)] ];
          [menu setMenuVisible:YES animated:YES];
      }
    };

    _mapView.tapGestureBlock = ^(CGPoint pt) {
      Pin *pin = [wself.pins pinAtLocation:pt atMap:weakmap];
      if (pin) {
          UIMenuController *menu = [UIMenuController sharedMenuController];
          if (!menu.menuVisible) {
              CGPoint pinPos = [weakmap makeDisplayPointFromMapPoint:pin.pos];
              wself.pinToDelete = pin;
              [wself becomeFirstResponder];
              [menu setTargetRect:CGRectMake(pinPos.x, pinPos.y - 20, 1, 1) inView:weakmap];
              menu.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Delete pin" action:@selector(deletePin:)] ];
              [menu setMenuVisible:YES animated:YES];
          }
      }
    };
}

// Minimal usage example of marker layer
- (void)addMarkers {
    // Create marker image
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"cluster" ofType:@"svgpb"];
    UIImage *img = [[GLMapVectorImageFactory sharedFactory] imageFromSvgpb:imagePath withScale:0.2];

    // Create style collection - it's storage for all images possible to use for markers
    GLMapMarkerStyleCollection *style = [[GLMapMarkerStyleCollection alloc] init];
    [style addStyleWithImage:img];

    // If marker layer constructed using GLMapVectorObjectArray location of marker is automatically calculated as
    //[GLMapVectorObject point]. So you don't need to set markerLocationBlock.
    //[style setMarkerLocationBlock:...];

    // Data fill block used to set marker style and text
    // It could work with any user defined object type.
    // Additional data for markers will be requested only for markers that are visible or not far from bounds of screen.
    [style setMarkerDataFillBlock:^(NSObject *marker, GLMapMarkerData data) {
      GLMapMarkerSetStyle(data, 0);
    }];

    // Load UK postal codes from GeoJSON
    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"cluster_data" ofType:@"json"];
    GLMapVectorObjectArray *objectArray = [GLMapVectorObject createVectorObjectsFromFile:dataPath];

    // Put our array of objects into marker layer. It could be any custom array of objects.
    // Disable clustering in this demo
    GLMapMarkerLayer *layer = [[GLMapMarkerLayer alloc] initWithVectorObjects:objectArray andStyles:style clusteringRadius:0 drawOrder:2];
    // Add marker layer on map
    [_mapView add:layer];
    GLMapBBox bbox = objectArray.bbox;
    _mapView.mapCenter = GLMapBBoxCenter(bbox);
    _mapView.mapZoom = [_mapView mapZoomForBBox:bbox];
}

- (void)addMarkersWithMapCSSClustering {
    // We use different colours for our clusters
    const int unionCount = 8;
    GLMapColor unionColours[unionCount] = {GLMapColorMake(33, 0, 255, 255),   GLMapColorMake(68, 195, 255, 255),
                                           GLMapColorMake(63, 237, 198, 255), GLMapColorMake(15, 228, 36, 255),
                                           GLMapColorMake(168, 238, 25, 255), GLMapColorMake(214, 234, 25, 255),
                                           GLMapColorMake(223, 180, 19, 255), GLMapColorMake(255, 0, 0, 255)};

    // Create style collection - it's storage for all images possible to use for markers and clusters
    GLMapMarkerStyleCollection *styleCollection = [[GLMapMarkerStyleCollection alloc] init];
    // Render possible images from svgpb
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"cluster" ofType:@"svgpb"];
    double maxSize = 0;
    for (int i = 0; i < unionCount; i++) {
        float scale = 0.2 + 0.1 * i;
        UIImage *img = [[GLMapVectorImageFactory sharedFactory] imageFromSvgpb:imagePath withScale:scale andTintColor:unionColours[i]];
        if (maxSize < img.size.width)
            maxSize = img.size.width;
        uint32_t styleIndex = [styleCollection addStyleWithImage:img];

        // set name of style that can be refrenced from mapcss
        [styleCollection setStyleName:[NSString stringWithFormat:@"uni%d", i] forStyleIndex:styleIndex];
    }

    // Create cascade style that will select style from collection
    GLMapVectorCascadeStyle *cascadeStyle =
        [GLMapVectorCascadeStyle createStyle:@"node { icon-image:\"uni0\"; text:eval(tag(\"name\")); text-color:#2E2D2B; font-size:12; "
                                             @"font-stroke-width:1pt; font-stroke-color:#FFFFFFEE;}"
                                              "node[count>=2]{icon-image:\"uni1\"; text:eval(tag(\"count\"));}"
                                              "node[count>=4]{icon-image:\"uni2\";}"
                                              "node[count>=8]{icon-image:\"uni3\";}"
                                              "node[count>=16]{icon-image:\"uni4\";}"
                                              "node[count>=32]{icon-image:\"uni5\";}"
                                              "node[count>=64]{icon-image:\"uni6\";}"
                                              "node[count>=128]{icon-image:\"uni7\";}"];

    // When we have big dataset to load. We could load data and create marker layer in background thread. And then display marker layer on
    // main thread only when data is loaded.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"cluster_data" ofType:@"json"];
      GLMapVectorObjectArray *points = [GLMapVectorObject createVectorObjectsFromFile:dataPath];
      GLMapBBox bbox = points.bbox;
      // Create layer with clusteringRadius equal to maxWidht/2. In this case two clusters can overlap half of it's size.
      GLMapMarkerLayer *layer = [[GLMapMarkerLayer alloc] initWithVectorObjects:points
                                                                   cascadeStyle:cascadeStyle
                                                                styleCollection:styleCollection
                                                               clusteringRadius:maxSize / 2
                                                                      drawOrder:2];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self->_mapView add:layer];
        self->_mapView.mapCenter = GLMapBBoxCenter(bbox);
        self->_mapView.mapZoom = [self->_mapView mapZoomForBBox:bbox];
      });
    });
}

- (void)addMarkersWithClustering {
    // We use different colours for our clusters
    const int unionCount = 8;
    GLMapColor unionColours[unionCount] = {GLMapColorMake(33, 0, 255, 255),   GLMapColorMake(68, 195, 255, 255),
                                           GLMapColorMake(63, 237, 198, 255), GLMapColorMake(15, 228, 36, 255),
                                           GLMapColorMake(168, 238, 25, 255), GLMapColorMake(214, 234, 25, 255),
                                           GLMapColorMake(223, 180, 19, 255), GLMapColorMake(255, 0, 0, 255)};

    // Create style collection - it's storage for all images possible to use for markers and clusters
    GLMapMarkerStyleCollection *styleCollection = [[GLMapMarkerStyleCollection alloc] init];

    // Render possible images from svgpb
    double maxWidth = 0;
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"cluster" ofType:@"svgpb"];
    for (int i = 0; i < unionCount; i++) {
        float scale = 0.2 + 0.1 * i;
        UIImage *img = [[GLMapVectorImageFactory sharedFactory] imageFromSvgpb:imagePath withScale:scale andTintColor:unionColours[i]];
        if (maxWidth < img.size.width)
            maxWidth = img.size.width;

        [styleCollection addStyleWithImage:img];
    }

    // Create style for text
    GLMapVectorStyle *textStyle =
        [GLMapVectorStyle createStyle:@"{text-color:black;font-size:12;font-stroke-width:1pt;font-stroke-color:#FFFFFFEE;}"];

    // Data fill block used to set style for marker. When constructing with GLMapVectorObjectArray layer can contain only vector objects
    [styleCollection setMarkerDataFillBlock:^(NSObject *marker, GLMapMarkerData data) {
      // marker - is an object from markers array.
      GLMapVectorObject *obj = (GLMapVectorObject *)marker;
      GLMapMarkerSetStyle(data, 0);
      NSString *name = [obj valueForKey:@"name"].asString;
      if (name) {
          GLMapMarkerSetText(data, name, CGPointMake(0, 7), textStyle);
      }
    }];

    // Union fill block used to set style for cluster object. First param is number objects inside the cluster and second is marker object.
    [styleCollection setMarkerUnionFillBlock:^(uint32_t markerCount, GLMapMarkerData data) {
      // we have 8 marker styles for 1, 2, 4, 8, 16, 32, 64, 128+ markers inside
      int markerStyle = log2(markerCount);
      if (markerStyle >= unionCount) {
          markerStyle = unionCount - 1;
      }
      GLMapMarkerSetStyle(data, markerStyle);
      GLMapMarkerSetText(data, [NSString stringWithFormat:@"%d", markerCount], CGPointZero, textStyle);
    }];

    // When we have big dataset to load. We could load data and create marker layer in background thread. And then display marker layer on
    // main thread only when data is loaded.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"cluster_data" ofType:@"json"];
      GLMapVectorObjectArray *points = [GLMapVectorObject createVectorObjectsFromFile:dataPath];
      GLMapBBox bbox = points.bbox;
      // Create layer with clusteringRadius equal to maxWidht/2. In this case two clusters can overlap half of it's size.
      GLMapMarkerLayer *layer =
          [[GLMapMarkerLayer alloc] initWithVectorObjects:points andStyles:styleCollection clusteringRadius:maxWidth / 2 drawOrder:2];

      dispatch_async(dispatch_get_main_queue(), ^{
        [self->_mapView add:layer];
        self->_mapView.mapCenter = GLMapBBoxCenter(bbox);
        self->_mapView.mapZoom = [self->_mapView mapZoomForBBox:bbox];
      });
    });
}

/* Example how to add multiline objects
 It includes 3 steps
 1. Allocate memory for points and fill points
 2. Setup style objects
 3. Add points to GLMapVectorObject
 4. Add GLMapVector object into the map
 */

- (void)addMultiline {
    // prepare object data
    NSMutableArray *multilineData = [[NSMutableArray alloc] init];

    int pointCount = 5;
    NSMutableData *data = [NSMutableData dataWithLength:sizeof(GLMapGeoPoint) * pointCount];
    GLMapGeoPoint *pts = (GLMapGeoPoint *)data.mutableBytes;

    pts[0] = GLMapGeoPointMake(53.8869, 27.7151); // Minsk
    pts[1] = GLMapGeoPointMake(50.4339, 30.5186); // Kiev
    pts[2] = GLMapGeoPointMake(52.2251, 21.0103); // Warsaw
    pts[3] = GLMapGeoPointMake(52.5037, 13.4102); // Berlin
    pts[4] = GLMapGeoPointMake(48.8505, 2.3343);  // Paris
    [multilineData addObject:data];

    pointCount = 3;
    data = [NSMutableData dataWithLength:sizeof(GLMapPoint) * pointCount];
    pts = (GLMapGeoPoint *)data.mutableBytes;

    pts[0] = GLMapGeoPointMake(52.3690, 4.9021); // Amsterdam
    pts[1] = GLMapGeoPointMake(50.8263, 4.3458); // Brussel
    pts[2] = GLMapGeoPointMake(49.6072, 6.1296); // Luxembourg
    [multilineData addObject:data];

    // style applied to all lines added. Style is string with mapcss rules. Read more in manual.
    GLMapVectorCascadeStyle *style = [GLMapVectorCascadeStyle createStyle:@"line{width:2pt; color:green;}"];

    // All user geometry objects should be drawn trough GLMapVectorObject
    // To load data faster we use NSArray of NSData. Each NSData contains GLMapPoints of one line. Allocate buffers first, then load it
    // using appropriate function.
    GLMapVectorObject *vectorObject = [[GLMapVectorObject alloc] init];
    [vectorObject loadGeoMultiLine:multilineData];

    GLMapDrawable *drawable = [[GLMapDrawable alloc] initWithDrawOrder:0];
    [drawable setVectorObject:vectorObject withStyle:style completion:nil];
    [_mapView add:drawable];
}

- (void)addPolygon {
    NSMutableArray *outerRings = [[NSMutableArray alloc] init];
    NSMutableArray *innerRings = [[NSMutableArray alloc] init];

    int pointCount = 100;
    float radius = 10;
    GLMapGeoPoint centerPoint = GLMapGeoPointMake(53, 27);

    NSMutableData *data = [NSMutableData dataWithLength:sizeof(GLMapPoint) * pointCount];
    GLMapGeoPoint *pts = (GLMapGeoPoint *)data.mutableBytes;

    // let's display circle
    for (int i = 0; i < pointCount; i++) {
        pts[i] = GLMapGeoPointMake(centerPoint.lat + sin(2 * M_PI / pointCount * i) * radius,
                                   centerPoint.lon + cos(2 * M_PI / pointCount * i) * radius);
    }

    [outerRings addObject:data];

    // now add hole
    radius = 5;
    data = [NSMutableData dataWithLength:sizeof(GLMapPoint) * pointCount];
    pts = (GLMapGeoPoint *)data.mutableBytes;
    // let's display polygon with random points
    for (int i = 0; i < pointCount; i++) {
        pts[i] = GLMapGeoPointMake(centerPoint.lat + sin(2 * M_PI / pointCount * i) * radius,
                                   centerPoint.lon + cos(2 * M_PI / pointCount * i) * radius);
    }
    [innerRings addObject:data];

    GLMapVectorObject *vectorObject = [[GLMapVectorObject alloc] init];

    GLMapVectorCascadeStyle *style =
        [GLMapVectorCascadeStyle createStyle:@"area{fill-color:#10106050; width:4pt; color:green;}"]; // #RRGGBBAA format
    [vectorObject loadGeoPolygon:@[ outerRings, innerRings ]];

    GLMapDrawable *drawable = [[GLMapDrawable alloc] initWithDrawOrder:4];
    [drawable setVectorObject:vectorObject withStyle:style completion:nil];
    [_mapView add:drawable];

    _mapView.mapGeoCenter = centerPoint;
}

// Example how to calcludate zoom level for some bbox
- (void)changeBBox {
    GLMapBBox bbox = GLMapBBoxEmpty;
    // Minsk
    bbox = GLMapBBoxAddPoint(bbox, [GLMapView makeMapPointFromGeoPoint:GLMapGeoPointMake(52.5037, 13.4102)]);
    // Paris
    bbox = GLMapBBoxAddPoint(bbox, [GLMapView makeMapPointFromGeoPoint:GLMapGeoPointMake(48.8505, 2.3343)]);

    // set center point and change zoom to make screenDistance less or equal mapView.bounds
    _mapView.mapCenter = GLMapBBoxCenter(bbox);
    _mapView.mapZoom = [_mapView mapZoomForBBox:bbox];
}

- (void)testNotifications {
    _mapView.bboxChangedBlock = ^(GLMapBBox bbox) {
      NSLog(@"bboxChangedBlock\torigin:%f %f, size: %f %f", bbox.origin.x, bbox.origin.y, bbox.size.x, bbox.size.y);
    };
    _mapView.mapDidMoveBlock = ^(GLMapBBox bbox) {
      NSLog(@"mapDidMoveBlock\torigin:%f %f, size: %f %f", bbox.origin.x, bbox.origin.y, bbox.size.x, bbox.size.y);
    };
}

#pragma mark GeoJSON

- (void)flashObject:(GLMapDrawable *)image {
    if (_flashAdd) {
        [_mapView add:image];
    } else {
        [_mapView remove:image];
    }
    _flashAdd = !_flashAdd;
    [self performSelector:@selector(flashObject:) withObject:image afterDelay:1.0];
}

- (void)zoomToObjects:(GLMapVectorObjectArray *)objects{
    GLMapBBox bbox = objects.bbox;
    _mapView.mapCenter = GLMapBBoxCenter(bbox);
    _mapView.mapZoom = [_mapView mapZoomForBBox:bbox];
}

- (void)loadGeoJSONWithCSSStyle {
    GLMapVectorObjectArray *objects = [GLMapVectorObject
        createVectorObjectsFromGeoJSON:@"[{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [30.5186, "
                                       @"50.4339]}, \"properties\": {\"id\": \"1\", \"text\": \"test1\"}},"
                                        "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [27.7151, 53.8869]}, "
                                        "\"properties\": {\"id\": \"2\", \"text\": \"test2\"}},"
                                        "{\"type\":\"LineString\",\"coordinates\": [ [27.7151, 53.8869], [30.5186, 50.4339], [21.0103, "
                                        "52.2251], [13.4102, 52.5037], [2.3343, 48.8505]]},"
                                        "{\"type\":\"Polygon\",\"coordinates\":[[ [0.0, 10.0], [10.0, 10.0], [10.0, 20.0], [0.0, 20.0] ],[ "
                                        "[2.0, 12.0], [ 8.0, 12.0], [ 8.0, 18.0], [2.0, 18.0] ]]}]"];

    GLMapVectorCascadeStyle *style =
        [GLMapVectorCascadeStyle createStyle:@"node[id=1]{icon-image:\"bus.svgpb\";icon-scale:0.5;icon-tint:green;text:eval(tag('text'));"
                                             @"text-color:red;font-size:12;text-priority:100;}"
                                              "node|z-9[id=2]{icon-image:\"bus.svgpb\";icon-scale:0.7;icon-tint:blue;;text:eval(tag('text')"
                                              ");text-color:red;font-size:12;text-priority:100;}"
                                              "line{linecap: round; width: 5pt; color:blue;}"
                                              "area{fill-color:green; width:1pt; color:red;}"];

    GLMapDrawable *drawable = [GLMapDrawable.alloc init];
    [drawable setVectorObject:objects[0] withStyle:style completion:nil];
    [self flashObject:drawable];
    [objects removeObjectAtIndex:0];

    drawable = [GLMapDrawable.alloc init];
    [drawable setVectorObjects:objects withStyle:style completion:nil];
    [_mapView add:drawable];
    [self zoomToObjects:objects];
}

- (void)loadPointGeoJSON {
    GLMapVectorObjectArray *objects = [GLMapVectorObject createVectorObjectsFromGeoJSON:@"{\"type\":\"Point\",\"coordinates\": [30.5186, 50.4339]}"];
    GLMapDrawable *drawable = [GLMapDrawable.alloc init];
    [drawable setVectorObjects:objects
                     withStyle:[GLMapVectorCascadeStyle createStyle:@"node{icon-image:\"bus.svgpb\";icon-scale:0.5;icon-tint:green;}"] completion:nil];
    [_mapView add:drawable];
    [self zoomToObjects:objects];
}

- (void)loadMultiPointGeoJSON {
    GLMapVectorObjectArray *objects =
        [GLMapVectorObject createVectorObjectsFromGeoJSON:@"{\"type\":\"MultiPoint\",\"coordinates\": [ [27.7151, 53.8869], [33.5186, "
                                                          @"55.4339], [21.0103, 52.2251], [13.4102, 52.5037], [2.3343, 48.8505]]}"];

    GLMapDrawable *drawable = [GLMapDrawable.alloc init];
    [drawable setVectorObjects:objects
                     withStyle:[GLMapVectorCascadeStyle createStyle:@"node{icon-image:\"bus.svgpb\"; icon-scale:0.7; icon-tint:blue; text-priority:100;}"] completion:nil];
    [_mapView add:drawable];
    [self zoomToObjects:objects];
}

- (void)loadLineStringGeoJSON {
    GLMapVectorObjectArray *objects =
        [GLMapVectorObject createVectorObjectsFromGeoJSON:@"{\"type\":\"LineString\",\"coordinates\": [ [27.7151, 53.8869], [30.5186, "
                                                          @"50.4339], [21.0103, 52.2251], [13.4102, 52.5037], [2.3343, 48.8505]]}"];

    GLMapDrawable *drawable = [GLMapDrawable.alloc init];
    [drawable setVectorObjects:objects
                     withStyle:[GLMapVectorCascadeStyle createStyle:@"line{width: 4pt; color:green;}"] completion:nil];
    [_mapView add:drawable];
    [self zoomToObjects:objects];
}

- (void)loadMultiLineStringGeoJSON
{
    GLMapVectorObjectArray *objects = [GLMapVectorObject createVectorObjectsFromGeoJSON:
                                       @"{\"type\":\"MultiLineString\",\"coordinates\":"
                                       "[[[27.7151, 53.8869], [30.5186, 50.4339], [21.0103, 52.2251], [13.4102, 52.5037], [2.3343, 48.8505]],"
                                       " [[26.7151, 52.8869], [29.5186, 49.4339], [20.0103, 51.2251], [12.4102, 51.5037], [1.3343, 47.8505]]]}"];

    GLMapDrawable *drawable = [GLMapDrawable.alloc init];
    [drawable setVectorObjects:objects
                     withStyle:[GLMapVectorCascadeStyle createStyle:@"line{linecap: round; width: 5pt; color:blue;}"] completion:nil];
    [_mapView add:drawable];
    [self zoomToObjects:objects];
}

- (void)loadPolygonGeoJSON {
    GLMapVectorObjectArray *objects = [GLMapVectorObject createVectorObjectsFromGeoJSON:
                                       @"{\"type\":\"Polygon\",\"coordinates\":"
                                       "[[ [0.0, 10.0], [10.0, 10.0], [10.0, 20.0], [0.0, 20.0] ],"
                                       " [ [2.0, 12.0], [ 8.0, 12.0], [ 8.0, 18.0], [2.0, 18.0] ]]}"];
    GLMapDrawable *drawable = [GLMapDrawable.alloc init];
    [drawable setVectorObjects:objects withStyle:[GLMapVectorCascadeStyle createStyle:@"area{fill-color:green}"] completion:nil];
    [_mapView add:drawable];
    [self zoomToObjects:objects];
}

- (void)loadMultiPolygonGeoJSON {
    GLMapVectorObjectArray *objects = [GLMapVectorObject createVectorObjectsFromGeoJSON:@"{\"type\":\"MultiPolygon\",\"coordinates\":"
                        "[[[ [0.0, 0.0], [10.0, 0.0], [10.0, 10.0], [0.0, 10.0] ],"
                        "  [ [2.0, 2.0], [ 8.0, 2.0], [ 8.0,  8.0], [2.0,  8.0] ]],"
                        " [[ [30.0,0.0], [40.0, 0.0], [40.0, 10.0], [30.0,10.0] ],"
                        "  [ [32.0,2.0], [38.0, 2.0], [38.0,  8.0], [32.0, 8.0] ]]]}"];

    GLMapDrawable *drawable = [GLMapDrawable.alloc init];
    [drawable setVectorObjects:objects withStyle:[GLMapVectorCascadeStyle createStyle:@"area{fill-color:blue; width:1pt; color:red;}"] completion:nil];
    [_mapView add:drawable];
    [self zoomToObjects:objects];
}

- (void)loadGeoJSONPostcode {
    NSError *error = nil;
    NSString *geojson = [NSString stringWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"uk_postcodes" ofType:@"geojson"] encoding:NSUTF8StringEncoding error:&error];
    if (geojson) {
        GLMapVectorObjectArray *objects = [GLMapVectorObject createVectorObjectsFromGeoJSON:geojson];
        
        if (objects) {
            GLMapDrawable *drawable = [GLMapDrawable.alloc init];
            [drawable setVectorObjects:objects withStyle:[GLMapVectorCascadeStyle createStyle:@"area{fill-color:green; width:1pt; color:red;}"] completion:nil];
            [_mapView add:drawable];
            [self zoomToObjects:objects];
        }
    }
}

- (void)loadGeoJSON {
    [self loadGeoJSONPostcode];
    //[self loadGeoJSONWithCSSStyle];
    //[self loadPointGeoJSON];
    //[self loadMultiPointGeoJSON];
    //[self loadLineStringGeoJSON];
    //[self loadMultiLineStringGeoJSON];
    //[self loadPolygonGeoJSON];
    //[self loadMultiPolygonGeoJSON];
}

- (void)flyTo:(id)sender {
    [_mapView animate:^(GLMapAnimation *animation) {
      self->_mapView.mapZoomLevel = 14;
      GLMapGeoPoint minPt = GLMapGeoPointMake(33, -118), maxPt = GLMapGeoPointMake(48, -85);
      [animation flyToGeoPoint:GLMapGeoPointMake(minPt.lat + (maxPt.lat - minPt.lat) * drand48(),
                                                 minPt.lon + (maxPt.lon - minPt.lon) * drand48())];
    }];
}

#pragma mark Style Reload
- (void)displayAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *_Nonnull action){
                                            }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)bulkDownload {
    GLMapManager *manager = [GLMapManager sharedManager];
    NSArray *allTiles = [manager vectorTilesAtBBox:_mapView.bbox];

    BOOL niceTileGridVisualization = YES;
    if (niceTileGridVisualization) {
        if (allTiles.count > 100000) {
            NSLog(@"Too many tiles");
            return;
        }
        NSArray *notCachedTiles = [manager notCachedVectorTilesAtBBox:_mapView.bbox];
        NSLog(@"Total tiles %d tiles to cache: %d", (int)allTiles.count, (int)notCachedTiles.count);

        GLMapVectorObject *notDownloadedTiles = [[GLMapVectorObject alloc] init];
        GLMapVectorObject *downloadedTiles = [[GLMapVectorObject alloc] init];

        for (NSNumber *tile in allTiles) {
            GLMapBBox tileBBox = [manager bboxForTile:tile.unsignedLongLongValue];
            GLMapPoint pts[5];
            pts[0] = tileBBox.origin;
            pts[1] = GLMapPointMake(tileBBox.origin.x, tileBBox.origin.y + tileBBox.size.y);
            pts[2] = GLMapPointMake(tileBBox.origin.x + tileBBox.size.x, tileBBox.origin.y + tileBBox.size.y);
            pts[3] = GLMapPointMake(tileBBox.origin.x + tileBBox.size.x, tileBBox.origin.y);
            pts[4] = tileBBox.origin;

            if ([notCachedTiles containsObject:tile]) {
                [notDownloadedTiles addPolygonOuterRing:pts pointCount:5];
            } else {
                [downloadedTiles addPolygonOuterRing:pts pointCount:5];
            }
        }

        GLMapDrawable *downloaded = [[GLMapDrawable alloc] initWithDrawOrder:4];
        [downloaded setVectorObject:downloadedTiles
                          withStyle:[GLMapVectorCascadeStyle createStyle:@"area{width:2pt; color:green;}"]
                         completion:nil];
        [_mapView add:downloaded];

        GLMapDrawable *notDownloaded = [[GLMapDrawable alloc] initWithDrawOrder:5];
        [notDownloaded setVectorObject:notDownloadedTiles
                             withStyle:[GLMapVectorCascadeStyle createStyle:@"area{width:2pt; color:red;}"]
                            completion:nil];
        [_mapView add:notDownloaded];
    }

    __block NSUInteger count = allTiles.count;
    [manager cacheTiles:allTiles
          progressBlock:^BOOL(uint64_t tile, NSError *error) {
            NSLog(@"Tile downloaded:%llu error:%@", tile, error);
            count--;
            if (count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self->_mapView reloadTiles];
                });
            }
            return YES;
          }];
}

- (void)reloadStyle {
    UITextField *urlField = (UITextField *)self.navigationItem.titleView;

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlField.text] options:NSDataReadingUncached error:&error];

    if (error) {
        [self displayAlertWithTitle:nil message:[NSString stringWithFormat:@"Style downloading error: %@", [error localizedDescription]]];
    } else {
        BOOL rv = [_mapView loadStyleWithBlock:^GLMapResource(NSString *_Nonnull name) {
          if ([name isEqualToString:@"Style.mapcss"]) {
              return GLMapResourceWithData(data);
          }

          return GLMapResourceEmpty;
        }];

        if (!rv) {
            [self displayAlertWithTitle:nil message:@"Style syntax error. Check log for details."];
        }

        [_mapView reloadTiles];
    }
}

- (void)recordGPSTrack {
    // we'll forward location back to mapView. I promise.
    _locationManager.delegate = self;
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {

    // To display current user location on the map
    [_mapView locationManager:manager didUpdateLocations:locations];

    for (CLLocation *location in locations) {
        GLTrackPoint point;
        point.pt = GLMapPointMakeFromGeoCoordinates(location.coordinate.latitude, location.coordinate.longitude);
        point.color = GLMapColorMake(255, 255, 0, 255);

        // It copies only references between TrackData objects so it's fast and optimized way to work with tracks up to million points
        // inside.
        if (!_trackData) {
            _trackData = [[GLMapTrackData alloc] initWithPoints:&point count:1];
        } else {
            _trackData = [[GLMapTrackData alloc] initWithData:_trackData andNewPoint:point startNewSegment:NO];
        }
    }

    if (_track == nil) {
        _track = [[GLMapTrack alloc] initWithDrawOrder:0 andTrackData:_trackData];
        [_track setStyle:[GLMapVectorStyle createStyle:@"{width:5pt;}"]];
        [_mapView add:_track];
    } else {
        [_track setTrackData:_trackData];
    }
}

@end
