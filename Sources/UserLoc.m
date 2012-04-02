//
//  UserLocDelegate.m
//  getloc
//
//  Created by Garrett Walbridge on 4/1/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "UserLoc.h"

#pragma mark Constants

// address to acquire user's external IP
const char* __extIPAddressURL = "http://www.dyndns.org/cgi-bin/check_ip.cgi";

// address to geolocate the user via IP
const char* __geolocatorURL = "http://freegeoip.net/csv/";

// labels for command line output
const char* __ipAddressLabel	= "IP address: ";
const char* __latitudeLabel		= "Latitude:   ";
const char* __longitudeLabel	= "Longitude:  ";
const char* __cityLabel			= "City:       ";
const char* __regionLabel		= "Region:     ";
const char* __countryLabel		= "Country:    ";



@implementation UserLoc

#pragma mark -
#pragma mark Synthesizations

@synthesize running=__running;
@synthesize located=__located;
@synthesize runtime=__secs;
@synthesize source=__source;

@synthesize locationManager=__locMgr;

@synthesize latitude=__lat;
@synthesize longitude=__long;

@synthesize city=__city;
@synthesize region=__region;
@synthesize country=__country;
@synthesize ip=__ip;

#pragma mark -
#pragma mark Internal methods

-(void) __stop
{
	switch(self->__source)
	{
		case CoreLocation:
			[self->__locMgr stopUpdatingLocation];
			break;

		case IPGeoCoding:
			// no-op in this case
			break;
	}

	self->__running = NO;
}

-(void) __start
{
	self->__running = YES;

	switch(self->__source)
	{
		case CoreLocation:
			[self->__locMgr startUpdatingLocation];
			break;

		case IPGeoCoding:
		{
			NSError* error = nil;
			NSScanner* scanner = nil;
			NSString* text = nil;
			NSArray* elements = nil;
			
			if(self->__verbose)
			{
				printf("Acquiring external IP address...\n");
			}
			
			// setup the URL for acquiring the IP and get the data
			NSURL* ipURL = [NSURL URLWithString:[NSString stringWithCString:__extIPAddressURL encoding:NSUTF8StringEncoding]];
			NSString* html = [NSString stringWithContentsOfURL:ipURL encoding:NSUTF8StringEncoding error:&error];
			if(error)
			{
				if(self->__verbose)
				{
					NSLog(@"Error: could not acquire current location; external IP address server is inaccessible.");
				}
				break;
			}
			
			// scan through IP data string...
			scanner = [NSScanner scannerWithString:html];
			while([scanner isAtEnd] == NO)
			{
				// find start of first tag
				[scanner scanUpToString:@"<" intoString:nil];

				// find end of tag
				[scanner scanUpToString:@">" intoString:&text];

                // replace the found tag with a space
				html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@" "];
				
				// break up with space as the delimiter
				elements = [html componentsSeparatedByString:@" "];
				
				// get the IP address from the proper element
                self->__ip = [elements objectAtIndex:[elements indexOfObject:@"Address:"] + 1];
			}

			if(self->__verbose)
			{
				printf("Geolocating via IP address...\n");
			}
			
			// now build the geolocator URL with the IP and get the data
			NSURL* geoURL = [NSURL URLWithString:[NSString stringWithFormat:@"%s%@", __geolocatorURL, self->__ip]];
			NSString* csv = [NSString stringWithContentsOfURL:geoURL encoding:NSUTF8StringEncoding error:&error];
			if(error)
			{
				if(self->__verbose)
				{
					NSLog(@"Error: could not acquire current location; geolocation server is inaccessible.");
				}
				break;
			}
			
			// split the comma separate values and store the location data
			elements = [csv componentsSeparatedByString:@","];
			self->__country = [elements objectAtIndex:1];
			self->__region = [elements objectAtIndex:3];
			self->__city = [elements objectAtIndex:5];
			self->__lat = [[elements objectAtIndex:7] doubleValue];
			self->__long = [[elements objectAtIndex:8] doubleValue];
			
			// mark our process as complete!
			self->__located = YES;
			
			[self __stop];
			break;
		}
	}
}

#pragma mark -
#pragma mark UserLoc lifecycle

-(id) initWithSource:(UserLocSource)source_ verbose:(BOOL)verbose_ timeout:(NSUInteger)timeout_
{
	if( !(self = [super init]) )
		return self;

	self->__verbose = verbose_;
	self->__timeout = timeout_;

	// default values
	self->__running = NO;
	self->__located = NO;
	self->__secs = 0;
	self->__source = source_;
	
	self->__locMgr = nil;
	
	self->__lat = 0.0;
	self->__long = 0.0;
	
	self->__city = @"";
	self->__region = @"";
	self->__country = @"";
	self->__ip = @"";

	switch(self->__source)
	{
		case CoreLocation:
			// create and setup our location manager object
			self->__locMgr = [[CLLocationManager alloc] init];
			self->__locMgr.delegate = self;
			self->__locMgr.desiredAccuracy = kCLLocationAccuracyBest;
			break;

		case IPGeoCoding:
			// no-op in this case
			break;
	}

	// start the show!
	[self __start];

	return self;
}

-(void) dealloc
{
	switch(self->__source)
	{
		case CoreLocation:
			[self->__locMgr release];
			break;

		case IPGeoCoding:
			// no-op in this case
			break;
	}
	
	[super dealloc];
}

#pragma mark -
#pragma mark Location messages

-(void) update:(id)sender_
{
	// increment the counter and check if we should timeout
	if(++self->__secs < self->__timeout)
		return;

	// if we get here, then make sure the sender really is our timer
	if(!sender_ || [sender_ isKindOfClass:[NSTimer class]] == NO)
		return;

	// stop must come before timer invalidation
	[self __stop];

	NSTimer* timer = (NSTimer*) sender_;
	[timer invalidate];
}

-(void) locationManager:(CLLocationManager*)manager_ didUpdateToLocation:(CLLocation*)newLoc_ fromLocation:(CLLocation*)oldLoc_
{
	// ignore updates where nothing we care about changed
	if(
		newLoc_.coordinate.latitude == oldLoc_.coordinate.latitude &&
		newLoc_.coordinate.longitude == oldLoc_.coordinate.longitude &&
		newLoc_.horizontalAccuracy == oldLoc_.horizontalAccuracy
	)
	{
		return;
	}

	self->__lat = newLoc_.coordinate.latitude;
	self->__long = newLoc_.coordinate.longitude;

	// TODO reverse geolocate from the user's lat/long

	// mark our process as complete!
	self->__located = YES;

	[self __stop];
}

-(void) locationManager:(CLLocationManager*)manager_ didFailWithError:(NSError*)error_
{
	if(self->__verbose)
	{
		NSLog(@"Error: could not acquire current location; CoreLocation failed.");
	}

	// just stop; no way to really recover from this
	[self __stop];
}

#pragma mark -
#pragma mark Command line output

-(void) printIPWithLabel:(BOOL)label_
{
	printf("%s%s\n", (label_ ? __ipAddressLabel : ""), [self->__ip UTF8String]);
}

-(void) printCoordinatesWithLabels:(BOOL)labels_
{
	printf("%s%.6lf\n", (labels_ ? __latitudeLabel : ""), self->__lat);
	printf("%s%.6lf\n", (labels_ ? __longitudeLabel : ""), self->__long);
}

-(void) printCityWithLabel:(BOOL)label_
{
	printf("%s%s\n", (label_ ? __cityLabel : ""), [self->__city UTF8String]);
}

-(void) printRegionWithLabel:(BOOL)label_
{
	printf("%s%s\n", (label_ ? __regionLabel : ""), [self->__region UTF8String]);
}

-(void) printCountryWithLabel:(BOOL)label_
{
	printf("%s%s\n", (label_ ? __countryLabel : ""), [self->__country UTF8String]);
}

-(void) printAllWithLabels:(BOOL)labels_
{
	[self printIPWithLabel:labels_];
	[self printCoordinatesWithLabels:labels_];
	[self printCityWithLabel:labels_];
	[self printRegionWithLabel:labels_];
	[self printCountryWithLabel:labels_];
}

@end
