#import "AppDelegate.h"

@implementation AppDelegate

- (IBAction)testSafari:(id)sender {
    [self testAppNamed:@"Safari"];
}

- (IBAction)testTextEdit:(id)sender {
    [self testAppNamed:@"TextEdit"];
}

- (void)testAppNamed:(NSString*)appName {
    NSURL* scriptUrl = [[NSBundle mainBundle] URLForResource:appName
                                               withExtension:@"scpt"];
    NSDictionary* errorDic = nil;
    NSAppleScript* script = [[NSAppleScript alloc] initWithContentsOfURL:scriptUrl
                                                                   error:&errorDic];
    /*SSYDBL*/ NSLog(@"script source: %@", script.source) ;

    if (script) {
        self.textField.stringValue = @"Waiting…";
        NSDictionary* error = nil;
        NSAppleEventDescriptor* descriptor = [script executeAndReturnError:&error];
        NSMutableString* report = [NSMutableString new];
        [report appendString:@"RESULT:\n"];
        [report appendFormat:@"Script returned error: %@\n", [error objectForKey:NSAppleScriptErrorMessage]];
        [report appendFormat:@"Script returned data: %@", descriptor];
        self.textField.stringValue = [report copy];
    } else {
        self.textField.stringValue = @"Failed loading script resource";
    }
}

@end
