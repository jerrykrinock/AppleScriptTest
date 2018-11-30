#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSTextField* textField;

- (IBAction)testSafari:(id)sender;
- (IBAction)testTextEdit:(id)sender;


@end

