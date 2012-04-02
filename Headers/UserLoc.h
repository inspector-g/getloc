//
//  UserLocDelegate.h
//  getloc
//
//  Created by Garrett Walbridge on 4/1/12.
//  Copyright (c) 2012. All rights reserved.
//



typedef enum
{
	CoreLocation	= 1,
	IPGeoCoding		= 2
} UserLocSource;

@interface UserLoc : NSObject <CLLocationManagerDelegate>
{
	@private
		BOOL __verbose;
		
		BOOL __running;
		BOOL __located;
		NSUInteger __secs;
		NSUInteger __timeout;
		UserLocSource __source;
		
		CLLocationManager* __locMgr;
		
		double __lat;
		double __long;
		
		NSString* __city;
		NSString* __region;
		NSString* __country;
		NSString* __ip;
}

@property (readonly) BOOL running;
@property (readonly) BOOL located;
@property (readonly) NSUInteger runtime;
@property (readonly) UserLocSource source;

@property (readonly) CLLocationManager* locationManager;

@property (readonly) double latitude;
@property (readonly) double longitude;

@property (readonly) NSString* city;
@property (readonly) NSString* region;
@property (readonly) NSString* country;
@property (readonly) NSString* ip;

-(id) initWithSource:(UserLocSource)source_ verbose:(BOOL)verbose_ timeout:(NSUInteger)timeout_;
-(void) dealloc;
-(void) update:(id)sender_;

-(void) printIPWithLabel:(BOOL)label_;
-(void) printCityWithLabel:(BOOL)label_;
-(void) printRegionWithLabel:(BOOL)label_;
-(void) printCountryWithLabel:(BOOL)label_;
-(void) printCoordinatesWithLabels:(BOOL)labels_;
-(void) printAllWithLabels:(BOOL)labels_;

@end
