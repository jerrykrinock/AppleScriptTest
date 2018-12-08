#import "AppDelegate.h"


@interface AppDelegate ()

@property (assign) ScriptSource scriptSource;
@property (assign) Executor executor;

@end


@implementation AppDelegate

- (IBAction)changeToAppResources:(id)sender {
    self.scriptSource = ScriptSourceAppResources;
}

- (IBAction)changeToUsersLibrary:(id)sender {
    self.scriptSource = ScriptSourceUsersLibrary;
}

- (IBAction)changeToNSUserAppleScriptTask:(id)sender {
    self.executor = ExecutorNSUserAppleScriptTask;
}

- (IBAction)changeToNSAppleScript:(id)sender {
    self.executor = ExecutorNSAppleScript;
}

- (IBAction)install:(id)sender {
    [self installScriptWithName:@"Safari"];
    [self installScriptWithName:@"TextEdit"];
}


- (NSURL*)scriptUrlForScriptName:(NSString*)scriptName
                          source:(ScriptSource)scriptSource {
    NSError* error = nil;
    NSURL* scriptUrl = nil;

    switch(scriptSource) {
        case ScriptSourceAppResources:
            scriptUrl  = [[NSBundle mainBundle] URLForResource:scriptName
                                                 withExtension:@"scpt"];
            if (!scriptUrl) {
                error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                            code:10003
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey : NSLocalizedString(@"Script missing from app package?", nil)
                                                   }];
                NSLog(@"error 13: %@", error);
            }
            break;
        case ScriptSourceUsersLibrary:;
            NSURL* dir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory
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

            if (!error) {
                scriptUrl = [dir URLByAppendingPathComponent:scriptName];
                scriptUrl = [scriptUrl URLByAppendingPathExtension:@"scpt"];
            }
            break;
    }

    return scriptUrl;
}

- (void)installScriptWithName:(NSString*)scriptName {
    NSError* error = nil;
    NSURL* sourceFile = [self scriptUrlForScriptName:scriptName
                                              source:ScriptSourceAppResources];

    if (!sourceFile) {
        error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                    code:10003
                                userInfo:@{
                                           NSLocalizedDescriptionKey : NSLocalizedString(@"Script missing from app package?", nil)
                                           }];
        NSLog(@"error 3: %@", error);
    }

    if (!error) {
        NSURL* destination = [self scriptUrlForScriptName:scriptName
                                                   source:ScriptSourceUsersLibrary];
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


- (IBAction)testSafari:(id)sender {
    [self testAppNamed:@"Safari"];
}

- (IBAction)testTextEdit:(id)sender {
    [self testAppNamed:@"TextEdit"];
}

- (void)testAppNamed:(NSString*)appName {
    [self.textField performSelectorOnMainThread:@selector(setStringValue:)
                                     withObject:@"Waiting for script to run…"
                                  waitUntilDone:NO];
    NSError* error = nil;
    NSURL* scriptUrl = [self scriptUrlForScriptName:appName
                                             source:self.scriptSource];
    switch(self.executor) {
        case ExecutorNSUserAppleScriptTask: {
            NSUserAppleScriptTask* script = [[NSUserAppleScriptTask alloc] initWithURL:scriptUrl
                                                                                 error:&error];
            if (error) {
                [self formatAndDisplayResult:nil
                                       error:error
                                     appName:appName];
            } else {
                [script executeWithAppleEvent:nil
                            completionHandler:^(NSAppleEventDescriptor * _Nullable descriptor, NSError * _Nullable scriptError) {
                                [self formatAndDisplayResult:descriptor
                                                       error:error
                                                     appName:appName];
                            }];
            }
            break;
        }
        case ExecutorNSAppleScript: {
            NSDictionary* errorDic = nil;
            NSAppleScript* script = [[NSAppleScript alloc] initWithContentsOfURL:scriptUrl
                                                                           error:&errorDic];
            NSAppleEventDescriptor* descriptor = nil;
            NSError* error = nil;
            if (script) {
                NSDictionary* errorDic = nil;
                descriptor = [script executeAndReturnError:&errorDic];
                if (errorDic) {
                    error = [NSError errorWithDomain:@"AppleScriptTestErrorDomain"
                                                code:911911
                                            userInfo:@{
                                                       NSLocalizedDescriptionKey : [errorDic objectForKey:NSAppleScriptErrorMessage]
                                                       }];
                }
            } else {
                error = [NSError errorWithDomain:@"AppleScriptTestErrorDomain"
                                            code:912912
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey : @"Failed loading script resource"
                                                   }];
            }
            [self formatAndDisplayResult:descriptor
                                   error:error
                                 appName:appName];
        }
    }
}

- (void)formatAndDisplayResult:(NSAppleEventDescriptor* _Nullable)descriptor
                         error:(NSError* _Nullable)error
                       appName:(NSString*)appName {
    NSMutableString* report = [NSMutableString new];
    [report appendFormat:@"DATA: %@", descriptor];
    [report appendString:@"\n\n"];
    [report appendFormat:@"ERROR: %@", error];
    NSString* string = [[NSString alloc] initWithFormat:
                        @"Ran: %@\n\nRESULT:\n\n%@",
                        [[self scriptUrlForScriptName:appName
                                               source:self.scriptSource] path],
                        report];
    [self.textField performSelectorOnMainThread:@selector(setStringValue:)
                                     withObject:string
                                  waitUntilDone:NO];
}

@end 
