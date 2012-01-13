//
//  FirstViewController.m
//  MapAttack
//
//  Created by Aaron Parecki on 2011-08-11.
//  Copyright 2011 Geoloqi.com. All rights reserved.
//

#import "MapViewController.h"
#import "CJSONSerializer.h"
#import "LQClient.h"
#import "AuthView.h"
#import "MapAttackAppDelegate.h"


#define MAX_ICON_SIZE 32
#define DEFAULT_ICON_SIZE 72

@implementation MapViewController

@synthesize webView, activityIndicator; //, mSlider;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

//- (void)awakeFromNib {
//    [mSlider setMaxValue: MAX_ICON_SIZE];
//    [mSlider setDoubleValue: DEFAULT_ICON_SIZE];
//}



- (void)loadURL:(NSString *)url {
	// If we don't have authentication tokens here, then pop up the login page to get their email and initials
	if(![[LQClient single] isLoggedIn]) {
		[lqAppDelegate.tabBarController presentModalViewController:[[AuthView alloc] init] animated:YES];
	} else {
		[webView loadRequest:[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[url stringByAppendingFormat:@"?access_token=%@&user_id=%@&team=%@", [[LQClient single] accessToken], [[LQClient single] userID], [[LQClient single] team]]]]];
		[lqAppDelegate.read reconnect];
		DLog(@"Loading URL in game view %@", [url stringByAppendingFormat:@"?access_token=%@&user_id=%@&team=%@", [[LQClient single] accessToken], [[LQClient single] userID], [[LQClient single] team]]);
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"BlankGame" ofType:@"html"]isDirectory:NO]]];

    //	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:LQMapAttackWebURL]]];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mapAttackDataBroadcastReceived:)
												 name:LQMapAttackDataNotification
											   object:nil];
}

- (void)mapAttackDataBroadcastReceived:(NSNotification *)notification {
	DLog(@"got data broadcast");
	
//	[[CJSONSerializer serializer] serializeDictionary:[notification userInfo]];

    DLog(@"%@", [NSString stringWithFormat:@"if(typeof LQHandlePushData != \"undefined\") { "
				  "LQHandlePushData(%@); }", [[notification userInfo] objectForKey:@"json"]]);
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"if(typeof LQHandlePushData != \"undefined\") { "
													 "LQHandlePushData(%@); }", [[notification userInfo] objectForKey:@"json"]]];
	
	
//	DLog(@"%@", [NSString stringWithFormat:@"if(typeof LQHandlePushData != \"undefined\") { "
//		   "LQHandlePushData(%@); }", [[CJSONSerializer serializer] serializeDictionary:[notification userInfo]]]);
//	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"if(typeof LQHandlePushData != \"undefined\") { "
//													 "LQHandlePushData(%@); }", [[CJSONSerializer serializer] serializeDictionary:[notification userInfo]]]];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

/*
- (void)zoomMapToLocation:(CLLocation *)location
{
    MKCoordinateSpan span;
    span.latitudeDelta  = 0.03;
    span.longitudeDelta = 0.03;
    
    MKCoordinateRegion region;
    
    [map setCenterCoordinate:location.coordinate animated:YES];
    
    region.center = location.coordinate;
    region.span   = span;
    
    [map setRegion:region animated:YES];
}

- (IBAction)tappedLocate:(id)sender
{
    CLLocation *location;
    
	//    if(location = [[Geoloqi sharedInstance] currentLocation])
	//    {
	//        [self zoomMapToLocation:location];
	//    }
	//    else if(mapView.userLocationVisible)
	//    {
	location = map.userLocation.location;
	[self zoomMapToLocation:location];
	//    }
}
*/

- (void)webViewDidFinishLoad:(UIWebView *)w {
	self.activityIndicator.alpha = 0.0;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {     
	self.activityIndicator.alpha = 1.0;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	//[read disconnect];
}


- (void)dealloc {
	[webView release];
    [super dealloc];
}

@end
