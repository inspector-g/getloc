//
//  main.m
//  getloc
//
//  Created by Garrett Walbridge on 4/1/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <getopt.h>
#import <libgen.h>

#import "UserLoc.h"



#define SUCCESS		0
#define NO_LOCATION	1
#define SHOWED_HELP	2
#define INVALID_OPT	3
#define PRINT_USAGE() printf("usage: %s [-%s] [-t <seconds>]\n", basename(argv[0]), optsNoArgs)



int main(int argc, char* const argv[])
{
	// constants for supported command line arguments
	static const char ipShort		= 'a';	// 'a' for address
	static const char countryShort	= 'c';	// 'c' for country
	static const char helpShort		= 'h';	// 'c' for country
	static const char labelsShort	= 'l';	// 'l' for labels
	static const char cityShort		= 'm';	// 'm' for municipality
	static const char coordsShort	= 'p';	// 'p' for position (or point)
	static const char regionShort	= 'r';	// 'r' for region
	static const char timeoutShort	= 't';	// 't' for timeout
	static const char verboseShort	= 'v';	// 'v' for verbose

	static const char ipLong[]		= "ipaddress";
	static const char countryLong[]	= "country";
	static const char helpLong[]	= "help";
	static const char labelsLong[]	= "labels";
	static const char cityLong[]	= "city";
	static const char coordsLong[]	= "coordinates";
	static const char regionLong[]	= "region";
	static const char timeoutLong[]	= "timeout";
	static const char verboseLong[]	= "verbose";
	
	// string of valid argument chars for getopt functions
	const char validOpts[] = { ipShort, countryShort, helpShort, labelsShort, cityShort, coordsShort, regionShort, timeoutShort, ':', verboseShort, '\0' };
	const char optsNoArgs[] = { ipShort, countryShort, helpShort, labelsShort, cityShort, coordsShort, regionShort, verboseShort, '\0' };

	// flags for command line args
	BOOL showAll = YES;
	BOOL showIP = NO, showCoords = NO, showCity = NO, showRegion = NO, showCountry = NO, showLabels = NO, verbose = NO;
	
	// default timeout of 30 seconds
	NSUInteger timeout = 30;

	// arguments structs for getopt_long()
	struct option longOpts[] = 
	{
		{ipLong,		no_argument,		NULL, ipShort},
		{countryLong,	no_argument,		NULL, countryShort},
		{helpLong,		no_argument,		NULL, helpShort},
		{labelsLong,	no_argument,		NULL, labelsShort},
		{cityLong,		no_argument,		NULL, cityShort},
		{coordsLong,	no_argument,		NULL, coordsShort},
		{regionLong,	no_argument,		NULL, regionShort},
		{timeoutLong,	required_argument,	NULL, timeoutShort},
		{verboseLong,	no_argument,		NULL, verboseShort}
	};

	// loop through all command line args
	int ch = 0;
	while( (ch = getopt_long(argc, argv, validOpts, longOpts, NULL)) != -1 )
	{
		switch(ch)
		{
			case ipShort:
				showAll = NO;
				showIP = YES;
				break;

			case countryShort:
				showAll = NO;
				showCountry = YES;
				break;

			case helpShort:
				PRINT_USAGE();
				printf("\n");
				printf("Without any options, %s prints the user's external IP address, latitude,\n", basename(argv[0]));
				printf("longitude, city, region, and country, with preceding labels.\n\n");
				printf("%s recognizes the following options:\n", basename(argv[0]));
				printf("    -%c or --%-12s Prints the user's external IP address.\n", ipShort, ipLong);
				printf("    -%c or --%-12s Prints the user's country.\n", countryShort, countryLong);
				printf("    -%c or --%-12s Prints this help screen.\n", helpShort, helpLong);
				printf("    -%c or --%-12s Output labels (ignored if no other options given).\n", labelsShort, labelsLong);
				printf("    -%c or --%-12s Prints the user's city.\n", cityShort, cityLong);
				printf("    -%c or --%-12s Prints the user's latitude and longitude.\n", coordsShort, coordsLong);
				printf("    -%c or --%-12s Prints the user's region (i.e. state, province, etc.).\n", regionShort, regionLong);
				printf("    -%c or --%-12s Specifies timeout in seconds. Integer argument required.\n", timeoutShort, timeoutLong);
				printf("    -%c or --%-12s Utilize verbose output.\n", verboseShort, verboseLong);
				return SHOWED_HELP;

			case labelsShort:
				showAll = NO;
				showLabels = YES;
				break;

			case cityShort:
				showAll = NO;
				showCity = YES;
				break;

			case coordsShort:
				showAll = NO;
				showCoords = YES;
				break;

			case regionShort:
				showAll = NO;
				showRegion = YES;
				break;

			case timeoutShort:
				timeout = atoi(optarg);
				break;

			case verboseShort:
				verbose = YES;
				break;
			
			default:
				PRINT_USAGE();
				return INVALID_OPT;
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
	return (ul.located ? SUCCESS : NO_LOCATION);
}
