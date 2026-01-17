#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// --- THE ENGINE (Marked as "USED" so it doesn't disappear) ---
__attribute__((used)) 
static uintptr_t scan_for_job(const char* name) {
    uintptr_t base = (uintptr_t)_dyld_get_image_vmaddr_slide(0);
    // We only scan a tiny 1MB window to stay under the "Low Memory" radar
    for (uintptr_t i = base + 0x2000000; i < base + 0x3000000; i += 8) {
        if (memcmp((void*)i, name, strlen(name)) == 0) return i;
    }
    return 0;
}

@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UILabel *status;
@end

@implementation iOSStrapMenu
- (void)runScript {
    self.status.text = @"[ LOADING ]";
    self.status.textColor = [UIColor whiteColor];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        uintptr_t job = scan_for_job("WaitingHybridScriptsJob");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (job) {
                self.status.text = @"[ LINKED ]";
                self.status.textColor = [UIColor cyanColor];
                // Execution logic goes here
            } else {
                self.status.text = @"[ NOT FOUND ]";
                self.status.textColor = [UIColor redColor];
            }
        });
    });
}
@end
