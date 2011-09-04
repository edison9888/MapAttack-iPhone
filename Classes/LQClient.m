//
//  LQClient.m
//  MapAttack
//
//  Created by Aaron Parecki on 2011-08-31.
//  Copyright 2011 Geoloqi.com. All rights reserved.
//

#import "LQClient.h"
#import "LQConfig.h"
#import "MapAttack.h"
#import "CJSONDeserializer.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import "MapAttackAppDelegate.h"

static NSString *const LQClientRequestNeedsAuthenticationUserInfoKey = @"LQClientRequestNeedsAuthenticationUserInfoKey";

@implementation LQClient

+ (LQClient *)single {
	static LQClient *singleton = nil;
    if(!singleton) {
		singleton = [[self alloc] init];
	}
	return singleton;
}

- (id) init
{
    self = [super init];
	if(!self) return nil;

	queue = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)dealloc {
	[queue release];
	[super dealloc];
}

- (NSString *)accessToken {
	return [[NSUserDefaults standardUserDefaults] stringForKey:LQAccessTokenKey];
}
- (void)setAccessToken:(NSString *)token {
//	if(token == nil) {
//		[[NSUserDefaults standardUserDefaults] removeObjectForKey:LQAccessTokenKey];
//	} else {
		[[NSUserDefaults standardUserDefaults] setObject:[[token copy] autorelease] forKey:LQAccessTokenKey];
//	}
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (ASIHTTPRequest *)appRequestWithURL:(NSURL *)url {
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setUsername:LQ_OAUTH_CLIENT_ID];
	[request setPassword:LQ_OAUTH_SECRET];
	return request;
}

- (id)appRequestWithURL:(NSURL *)url class:(NSString *)class {
	id request = [NSClassFromString(class) requestWithURL:url];
	[request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setUsername:LQ_OAUTH_CLIENT_ID];
	[request setPassword:LQ_OAUTH_SECRET];
	return request;
}

- (ASIHTTPRequest *)userRequestWithURL:(NSURL *)url {
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"OAuth %@", self.accessToken]];
//	NSMutableDictionary *dict = (request.userInfo ? [[NSMutableDictionary alloc] initWithDictionary:request.userInfo] : [[NSMutableDictionary alloc] init]);
//	request.userInfo = dict;
//	[dict setObject:[NSNumber numberWithBool:YES] forKey:LQClientRequestNeedsAuthenticationUserInfoKey];
	return request;
}

- (NSDictionary *)dictionaryFromResponse:(NSString *)response {
	NSError *err = nil;
	NSDictionary *res = [[CJSONDeserializer deserializer] deserializeAsDictionary:[response dataUsingEncoding:NSUTF8StringEncoding] error:&err];
	return res;
}

- (NSURL *)urlWithPath:(NSString *)path {
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", LQAPIBaseURL, path]];
}

- (NSString *)hardware
{
	size_t size;
	
	// Set 'oldp' parameter to NULL to get the size of the data
	// returned so we can allocate appropriate amount of space
	sysctlbyname("hw.machine", NULL, &size, NULL, 0); 
	
	// Allocate the space to store name
	char *name = malloc(size);
	
	// Get the platform name
	sysctlbyname("hw.machine", name, &size, NULL, 0);
	
	// Place name into a string
	NSString *machine = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
	
	// Done with this
	free(name);
	
	return machine;
}

/*
- (void)dequeueUserRequestIfPossible {
	if(queue.count > 0 && self.accessToken) {
		ASIHTTPRequest *request = (ASIHTTPRequest *)[queue objectAtIndex:0];
		[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"OAuth %@", @"xxx"]];
		[request startAsynchronous];
		[queue removeObjectAtIndex:0];
	} else if(!authenticationRequest) {
		__block ASIFormDataRequest *request = [self appRequestWithURL:[self urlWithPath:@"oauth/token"] class:@"ASIFormDataRequest"];
		[request setPostValue:@"refresh_token" forKey:@"grant_type"];
		[request setPostValue:[self refreshToken] forKey:@"refresh_token"];
		[request setCompletionBlock:^{
			NSDictionary *responseDict = [self dictionaryFromResponse:[request responseString]];
			// Store access token
			self.accessToken = (NSString *)[responseDict objectForKey:@"access_token"];
			[authenticationRequest release];
			authenticationRequest = nil;
			[self dequeueUserRequestIfPossible];
		}];
		authenticationRequest = [request retain];
	}
}

- (void)enqueueUserRequest:(ASIHTTPRequest *)inRequest {
	__block ASIHTTPRequest *request = inRequest;
	[request setCompletionBlock:^{
		if (request.completionBlock)
			request.completionBlock();
		[self dequeueUserRequestIfPossible];
	}];
	[queue addObject:request];
	[self dequeueUserRequestIfPossible];
}
*/

- (void)runRequest:(ASIHTTPRequest *)inRequest callback:(LQHTTPRequestCallback)callback {
	__block ASIHTTPRequest *request = inRequest;
	[request setCompletionBlock:^{
		callback(nil, [self dictionaryFromResponse:[request responseString]]);
	}];
	[request setFailedBlock:^{
		NSLog(@"Request Failed %@", request);
		callback(request.error, nil);
	}];
	[request startAsynchronous];
}

#pragma mark public methods

- (BOOL)isLoggedIn {
	NSLog(@"Is logged in? %@", self.accessToken);
	return self.accessToken != nil;
}

/*
- (NSString *)refreshToken {
	return [[NSUserDefaults standardUserDefaults] stringForKey:LQRefreshTokenKey];
}
*/

- (void)sendPushToken:(NSString *)token {
	// TODO: Send this device token to the Geoloqi API
}

- (void)createNewAccountWithEmail:(NSString *)email initials:(NSString *)initials callback:(LQHTTPRequestCallback)callback {
	NSURL *url = [self urlWithPath:@"user/create_anon"];
	__block ASIFormDataRequest *request = [self appRequestWithURL:url class:@"ASIFormDataRequest"];

	[request setPostValue:initials forKey:@"name"];

	UIDevice *d = [UIDevice currentDevice];
	[request setPostValue:[NSString stringWithFormat:@"%@ %@", d.systemName, d.systemVersion] forKey:@"platform"];
	[request setPostValue:[self hardware] forKey:@"hardware"];

	const unsigned *tokenBytes = [[MapAttackAppDelegate UUID] bytes];
	NSString *hexDeviceID = [NSString stringWithFormat:@"%08x%08x%08x%08x",
						  ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]), ntohl(tokenBytes[3])];	
	[request setPostValue:hexDeviceID forKey:@"device_id"];
	
	[request setCompletionBlock:^{
		NSDictionary *responseDict = [self dictionaryFromResponse:[request responseString]];
		// [[NSUserDefaults standardUserDefaults] setObject:(NSString *)[responseDict objectForKey:@"refresh_token"] forKey:LQRefreshTokenKey];
		[[NSUserDefaults standardUserDefaults] setObject:email forKey:LQAuthEmailAddressKey];
		[[NSUserDefaults standardUserDefaults] setObject:initials forKey:LQAuthInitialsKey];
		self.accessToken = (NSString *)[responseDict objectForKey:@"access_token"];  // this runs synchronize
		callback(nil, responseDict);
	}];
	[request startAsynchronous];
}

- (void)getNearbyLayers:(LQHTTPRequestCallback)callback {
	NSURL *url = [self urlWithPath:[NSString stringWithFormat:@"layer/nearby?latitude=45.5246&longitude=-122.6843&application_id=%@", MapAttackAppID]];
	__block ASIHTTPRequest *request;
	if([self isLoggedIn]) {
		request = [self userRequestWithURL:url];
	} else {
		request = [self appRequestWithURL:url];
	}
	[self runRequest:request callback:callback];
}

- (void)logout {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:LQAuthEmailAddressKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:LQAuthInitialsKey];
	self.accessToken = nil;
}

@end


