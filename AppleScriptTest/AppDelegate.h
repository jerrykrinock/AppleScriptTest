#import <Cocoa/Cocoa.h>

enum ScriptSource_enum
{
    ScriptSourceAppResources = 0,
    ScriptSourceUsersLibrary = 1
};
typedef enum ScriptSource_enum ScriptSource ;

enum Executor_enum
{
    ExecutorNSAppleScript = 0,
    ExecutorNSUserAppleScriptTask = 1
};
typedef enum Executor_enum Executor;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSTextField* textField;

- (IBAction)testSafari:(id)sender;
- (IBAction)testTextEdit:(id)sender;

@property (readonly) ScriptSource scriptSource;
@property (readonly) Executor executor;

- (IBAction)changeToAppResources:(id)sender;
- (IBAction)changeToUsersLibrary:(id)sender;

- (IBAction)changeToNSUserAppleScriptTask:(id)sender;
- (IBAction)changeToNSAppleScript:(id)sender;

- (IBAction)install:(id)sender;

@end

