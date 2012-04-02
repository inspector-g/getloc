//
//  main.m
//  getloc
//
//  Created by Garrett Walbridge on 4/1/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <getopt.h>

#import "UserLoc.h"



int main(int argc, char* const argv[])
{
	// constants for supported command line arguments
	static const char ipShort = 'a';		// 'a' for address
	static const char coordsShort = 'p';	// 'p' for position (or point)
	static const char cityShort = 'm';		// 'm' for municipality
	static const char regionShort = 'r';	// 'r' for region
	static const char countryShort = 'c';	// 'c' for country
	static const char labelsShort = 'l';	// 'l' for labels
	static const char verboseShort = 'v';	// 'v' for verbose
	static const char timeoutShort = 't';	// 't' for timeout
	
	// string of valid argument chars for getopt functions
	const char validArgs[] = { ipShort, coordsShort, cityShort, regionShort, countryShort, labelsShort, verboseShort, timeoutShort, ':', '\0' };

	// flags for command line args
	BOOL showAll = YES;
	BOOL showIP = NO, showCoords = NO, showCity = NO, showRegion = NO, showCountry = NO, showLabels = NO, verbose = NO;
	
	// default timeout of 30 seconds
	NSUInteger timeout = 30;

	// arguments structs for getopt_long()
	struct option longOpts[] = 
	{
		{"ipaddress",	no_argument, NULL, ipShort},
		{"coordinates",	no_argument, NULL, coordsShort},
		{"city",		no_argument, NULL, cityShort},
		{"region",		no_argument, NULL, regionShort},
		{"country",		no_argument, NULL, countryShort},
		{"labels",		no_argument, NULL, labelsShort},
		{"verbose",		no_argument, NULL, verboseShort},
		{"timeout",		required_argument, NULL, timeoutShort}
	};

	// loop through all command line args
	int ch = 0;
	while( (ch = getopt_long(argc, argv, validArgs, longOpts, NULL)) != -1 )
	{
		switch(ch)
		{
			case ipShort:
				showAll = NO;
				showIP = YES;
				break;

			case coordsShort:
				showAll = NO;
				showCoords = YES;
				break;

			case cityShort:
				showAll = NO;
				showCity = YES;
				break;

			case regionShort:
				showAll = NO;
				showRegion = YES;
				break;

			case countryShort:
				showAll = NO;
				showCountry = YES;
				break;

			case labelsShort:
				showAll = NO;
				showLabels = YES;
				break;

			case verboseShort:
				verbose = YES;
				break;

			case timeoutShort:
				timeout = atoi(optarg);
				break;
			
			default:
				// TODO show proper arg usage and bail
				break;
		}
	}

	// begin our "global" autorelease pool
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if(verbose)
	{
		// let the user know that things have started up
		printf("Trying to find user location...\n");
	}
	
	// instantiate a UserLoc object with just IP geocoding, for now
	UserLoc* ul = [[UserLoc alloc] initWithSource:IPGeoCoding verbose:verbose timeout:timeout];
	
	// get default run loop and set a timer for updating the UserLoc object
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	NSTimer* timer = [NSTimer timerWithTimeInterval:0.9999 target:ul selector:@selector(update:) userInfo:nil repeats:YES];
	[runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
	
	// check every second if the run loop should finish
	while( ul.running && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0001]] )
		;
	
	// if we get here, then the run loop finished because either the location was determined, or the process timed out
	if(ul.located)
	{
		if(showAll)
		{
			// showing all location elements always shows labels as well
			[ul printAllWithLabels:YES];
		}
		else
		{
			if(showIP)
			{
				[ul printIPWithLabel:showLabels];
			}
			
			if(showCoords)
			{
				[ul printCoordinatesWithLabels:showLabels];
			}
			
			if(showCity)
			{
				[ul printCityWithLabel:showLabels];
			}
			
			if(showRegion)
			{
				[ul printRegionWithLabel:showLabels];
			}
			
			if(showCountry)
			{
				[ul printCountryWithLabel:showLabels];
			}
		}
	}
	
	// clean up our memory!
	[ul release];
	[pool release];

	// bail with a simple return value (0 for located, 1 for not)
	return !ul.located;
}
