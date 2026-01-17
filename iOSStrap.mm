#import <UIKit/UIKit.h>
#import <dlfcn.h>

// This is the function signature for the execution engine
typedef void (*delta_execute_ptr)(const char*);

@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@property (nonatomic, strong) UILabel *status;
@end

@implementation iOSStrapMenu

- (void)runScript {
    // 1. Look for the engine in the loaded app memory
    void* handle = dlopen(NULL, RTLD_NOW);
    
    // 2. Try common Delta/Fluxus function names
    delta_execute_ptr run = (delta_execute_ptr)dlsym(handle, "execute");
    if (!run) run = (delta_execute_ptr)dlsym(handle, "run_script");
    if (!run) run = (delta_execute_ptr)dlsym(handle, "main_execute");

    if (run) {
        run([self.scriptBox.text UTF8String]);
        self.status.text = @"𝔅 | EXECUTED";
        self.status.textColor = [UIColor cyanColor];
    } else {
        self.status.text = @"𝔅 | ENGINE LINK ERROR";
        self.status.textColor = [UIColor orangeColor];
    }
}
@end
