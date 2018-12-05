#import "AppDelegate.h"

#if 11
#warning Will run scripts directly from app product's Resources
#define SIMPLE 1
#else
#warning Will install scripts in ~/Library/Application Scripts and run from there
#endif

@implementation AppDelegate

- (NSURL*)scriptUrlForScriptName:(NSString*)scriptName {
    NSError* error = nil;

#if SIMPLE
        NSURL* scriptUrl = [[NSBundle mainBundle] URLForResource:scriptName
                                                   withExtension:@"scpt"];
        if (!scriptUrl) {
            error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                        code:10003
                                    userInfo:@{
                                               NSLocalizedDescriptionKey : NSLocalizedString(@"Script missing from app package?", nil)
                                               }];
            NSLog(@"error 13: %@", error);
        }

        return scriptUrl;
#else
    NSURL* destinDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory
                                                              inDomain:NSUserDomainMask
                                                     appropriateForURL:nil
                                                                create:YES
                                                                 error:&error];
    /* At this point destinDir is:
     ~/Library/Application Scripts/com.sheepsystems.AppleScriptTest
     */
    if (error) {
        NSLog(@"error 2: %@", error);
    }

    NSURL* scriptUrl = nil;
    if (!error) {
        scriptUrl = [destinDir URLByAppendingPathComponent:scriptName];
        scriptUrl = [scriptUrl URLByAppendingPathExtension:@"scpt"];
    }

    return scriptUrl;
#endif
}

#if SIMPLE
#else
- (void)installScriptWithName:(NSString*)scriptName {
    NSError* error = nil;
    NSURL* sourceFile = nil;

    sourceFile  = [[NSBundle mainBundle] URLForResource:scriptName
                                          withExtension:@"scpt"];
    if (!sourceFile) {
        error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                    code:10003
                                userInfo:@{
                                           NSLocalizedDescriptionKey : NSLocalizedString(@"Script missing from app package?", nil)
                                           }];
        NSLog(@"error 3: %@", error);
    }

    if (!error) {
        NSURL* destination = [self scriptUrlForScriptName:scriptName];
		/* Maybe it would be cheaper to diff the existing installed file with
         our resource and only do this if there is a difference (presumably
         due to an update of the app.  But, whatever, this is guaranteed to
         work… */
		[[NSFileManager defaultManager] removeItemAtURL:destination
                                                  error:NULL];
        /* Ignored error since file might not exist. */

        [[NSFileManager defaultManager] copyItemAtURL:sourceFile
                                                toURL:destination
                                                error:&error];
        if (error) {
            NSLog(@"error 4: %@", error);
        } else {
            NSLog(@"Succeeded installing Safari.scpt");
        }
    }
}
#endif


- (void)applicationDidFinishLaunching:(NSNotification *)notification {
#if SIMPLE
#else
    [self installScriptWithName:@"Safari"];
    [self installScriptWithName:@"TextEdit"];
#endif
}

- (IBAction)testSafari:(id)sender {
    [self testAppNamed:@"Safari"];
}

- (IBAction)testTextEdit:(id)sender {
    [self testAppNamed:@"TextEdit"];
}

- (void)testAppNamed:(NSString*)appName {
    NSError* error = nil;
    NSUserAppleScriptTask* script = [[NSUserAppleScriptTask alloc] initWithURL:[self scriptUrlForScriptName:appName]
                                                                         error:&error];
    if (error) {
        NSLog(@"error 10: %@", error);
        [self updateResult:@"Failed loading script resource"
                scriptName:appName];
    } else {
        [script executeWithAppleEvent:nil
                    completionHandler:^(NSAppleEventDescriptor * _Nullable descriptor, NSError * _Nullable scriptError) {
                        if (!scriptError) {
                            NSMutableString* report = [NSMutableString new];
                            [report appendFormat:@"DATA: %@", descriptor];
                            [report appendString:@"\n\n"];
                            [report appendFormat:@"ERROR: %@", scriptError];
                            [self updateResult:[report copy]
                                    scriptName:appName];
                        } else {
                            NSLog(@"error 12: %@", scriptError);
                        }
                        }];
    }
}

- (void)updateResult:(NSString*)result
          scriptName:(NSString*)scriptName {
    NSString* string = [[NSString alloc] initWithFormat:
                        @"Ran: %@\n\nRESULT:\n\n%@",
                        [[self scriptUrlForScriptName:scriptName] path],
                        result];
    [self.textField performSelectorOnMainThread:@selector(setStringValue:)
                                     withObject:string
                                  waitUntilDone:NO];
}

@end
