/*
 * Copyright (c) 2009 Mo McRoberts.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 3. The names of the author(s) of this software may not be used to endorse
 * or promote products derived from this software without specific prior
 * written permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * AUTHORS OF THIS SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "p_ngdatabase.h"	

NSString *const NGDBErrorDomain = @"com.nexgenta.DBCore";
NSString *const NGDBNull = @"(NULL)";
NSString *const NGDBDefault = @"@@DEFAULT@@";

static NGDatabase *sharedDatabaseManager;

@implementation NGDatabase
{
	NSMutableDictionary *driverInfo;
	NSMutableDictionary *driverClasses;
}

+ (NGDatabase *)sharedDatabaseManager
{
	@synchronized(self) {
        if (sharedDatabaseManager == nil) {
            [[self alloc] init];
        }
    }
	return sharedDatabaseManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedDatabaseManager == nil) {
            return [super allocWithZone:zone];
        }
    }
    return sharedDatabaseManager;
}

- (id)init
{
    Class me = [self class];
    @synchronized(me) {
        if (sharedDatabaseManager == nil) {
            if (self = [super init]) {
                sharedDatabaseManager = self;
				driverClasses = [[NSMutableDictionary alloc] initWithCapacity:16];
				driverInfo = [[NSMutableDictionary alloc] initWithCapacity:16];
				[self addDriverClass:[NSDictionary dictionaryWithObjectsAndKeys:
					@"com.nexgenta.NGDatabase.SQLite", @"CFBundleIdentifier",
					@"NGSQLiteConnection", @"NSPrincipalClass",
					@"© 2009 Mo McRoberts.", @"NSHumanReadableCopyright",
					@"1.0", @"CFBundleVersion",
					@"SQLite", @"CFBundleName",
					@"English", @"CFBundleDevelopmentRegion",
					[NSArray arrayWithObjects:
						[NSDictionary dictionaryWithObjectsAndKeys:
							[NSArray arrayWithObjects:@"sqlite", @"sqlite3", nil], @"CFBundleURLSchemes", nil
						], nil], @"CFBundleURLTypes",
					nil]];
            }
        }
    }
    return sharedDatabaseManager;
}

- (BOOL)addDriverClass:(NSDictionary *)infoDictionary
{
	NSDictionary *infoDict;
	NSString *className;
	id urltypes, urldict, schemes, scheme;
	Class targ;
	size_t c, d, count;
	
	if(!(urltypes = [infoDictionary objectForKey:@"CFBundleURLTypes"]) || ![urltypes isKindOfClass:[NSArray class]])
	{
		NSLog(@"NGDatabase -addDriverClass:forScheme: CFBundleURLTypes key is absent");
		return FALSE;
	}
	if(!(className = [infoDictionary objectForKey:@"NSPrincipalClass"]))
	{
		NSLog(@"NGDatabase -addDriverClass:forScheme: NSPrincipalClass key is absent");
		return FALSE;
	}
	if(!(targ = NSClassFromString(className)))
	{
		NSLog(@"NGDatabase -addDriverClass:forScheme: specified NSPrincipalClass (%@) does not exist", className);
		return FALSE;
	}
	count = 0;
	infoDict = [infoDictionary copy];
	for(c = 0; c < [urltypes count]; c++)
	{
		urldict = [urltypes objectAtIndex:c];
		if(![urldict isKindOfClass:[NSDictionary class]])
		{
			continue;
		}
		if(!(schemes = [urldict objectForKey:@"CFBundleURLSchemes"]) || ![urltypes isKindOfClass:[NSArray class]])
		{
			continue;
		}
		for(d = 0; d < [schemes count]; d++)
		{
			scheme = [schemes objectAtIndex:d];
			NSLog(@"Registering scheme %@", scheme);
			[driverClasses setObject:targ forKey:scheme];
			[driverInfo setObject:infoDict forKey:scheme];
		}
	}
	[infoDict release];
	if(count)
	{
		return TRUE;
	}
	NSLog(@"NGDatabase -addDriverClass:forScheme: no URL schemes found to register");
	return FALSE;
}

- (Class)driverForScheme:(NSString *)scheme
{
	return (Class) [driverClasses objectForKey:scheme];
}

- (id)driverProperty:(NSString *)propertyName forScheme:(NSString *)scheme
{
	NSDictionary *dict;
	id prop;
	
	if((dict = [driverInfo objectForKey:scheme]))
	{
		if((prop = [dict objectForKey:propertyName]))
		{
			return prop;
		}
	}
	return nil;
}

- (NSDictionary *)driverInfoDictionaryForScheme:(NSString *)scheme
{
	NSDictionary *dict;
	
	if((dict = [driverInfo objectForKey:scheme]))
	{
		return dict;
	}
	return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)retain
{
	return self;
}

- (unsigned int)retainCount
{
	return UINT_MAX;
}

- (void)release
{
}
				
- (id)autorelease
{
	return self;
}

@end
