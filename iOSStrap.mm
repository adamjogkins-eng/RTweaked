#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <dlfcn.h> // Required for dynamic loading

// --- EXTERNAL ENGINE DEFINITIONS ---
// These are the common function names in Delta/Fluxus. 
// We declare them as 'weak' so the app doesn't crash if one is missing.
extern "C" void execute(const char* script) __attribute__((weak_import));
extern "C" void run_script(const char* script) __attribute__((weak_import));
extern "C" void fluxus_execute(const char* script) __attribute__((weak_import));

@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@property (nonatomic, strong) UITextView *console;
@property (nonatomic, strong) UILabel *status;
@end

@implementation iOSStrapMenu

- (void)log:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.console.text = [NSString stringWithFormat:@"%@\n> %@", self.console.text, text];
        [self.console scrollRangeToVisible:NSMakeRange(self.console.text.length, 0)];
    });
}

- (void)runScript {
    [self log:@"ATTEMPTING API EXECUTION..."];
    const char* code = [self.scriptBox.text UTF8String];

    // --- DYNAMIC API ROUTING ---
    // This checks which function Delta actually uses in this version
    if (execute != NULL) {
        execute(code);
        [self log:@"CALLED: _execute"];
    } else if (run_script != NULL) {
        run_script(code);
        [self log:@"CALLED: _run_script"];
    } else if (fluxus_execute != NULL) {
        fluxus_execute(code);
        [self log:@"CALLED: _fluxus_execute"];
    } else {
        [self log:@"ERROR: No valid API symbols found! Check your YAML logs."];
        self.status.text = @"STATUS: LINK ERROR";
        return;
    }

    self.status.text = @"STATUS: SENT";
    self.status.textColor = [UIColor greenColor];
}

// ... (Keep your existing initWithFrame and Scene Fix code from the previous version) ...

@end
