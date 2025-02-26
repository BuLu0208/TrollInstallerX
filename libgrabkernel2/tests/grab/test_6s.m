//
//  test_6s.m
//  libgrabkernel2
//
//  Created for testing iPhone 6s iOS 15.8.3 kernel download
//

#import <Foundation/Foundation.h>
#import "grabkernel.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSString *osStr = @"iPhone8,1";           // iPhone 6s
        NSString *build = @"19H380";             // iOS 15.8.3
        NSString *modelIdentifier = @"iPhone8,1"; // iPhone 6s
        NSString *boardconfig = @"n71";          // iPhone 6s boardconfig
        NSString *outPath = @"kernelcache_6s_15.8.3";
        
        bool success = grab_kernelcache_for(osStr, build, modelIdentifier, boardconfig, outPath);
        if (success) {
            NSLog(@"Successfully downloaded kernelcache to %@", outPath);
            return 0;
        } else {
            NSLog(@"Failed to download kernelcache");
            return 1;
        }
    }
}