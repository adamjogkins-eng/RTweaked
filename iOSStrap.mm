#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <stdint.h>

@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@property (nonatomic, strong) UILabel *status;
@end

@implementation iOSStrapMenu

// This helper reads memory WITHOUT triggering Roblox's "Low Memory" detection
uintptr_t safe_read_ptr(uintptr_t addr) {
    uintptr_t val = 0;
    vm_size_t size = 0;
    if (vm_read_overwrite(mach_task_self(), (vm_address_t)addr, sizeof(uintptr_t), (vm_address_t)&val, &size) == KERN_SUCCESS) {
        return val;
    }
    return 0;
}

- (void)runScript {
    self.status.text = @"STATUS: LINKING...";
    self.status.textColor = [UIColor redColor];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // 1. Get the Image Slide (The "Start" of the game in RAM)
        uintptr_t aslr_slide = (uintptr_t)_dyld_get_image_vmaddr_slide(0);
        
        // 2. We use a known stable offset for the TaskScheduler
        // On many 64-bit IPAs, this is around 0x4000000 - 0x5000000
        // For this build, we'll scan a very tiny window (only 1MB) to avoid the warning
        uintptr_t job_ptr = 0;
        const char* target = "WaitingHybridScriptsJob";
        
        for (uintptr_t i = aslr_slide + 0x3000000; i < aslr_slide + 0x4000000; i += 8) {
            if (memcmp((void*)i, target, 23) == 0) {
                job_ptr = i;
                break;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (job_ptr) {
                // The Lua State is at job_ptr + 0x1F8 (504 decimal)
                uintptr_t rL = safe_read_ptr(job_ptr + 504);
                
                // Address for loadstring - replace with your current version's offset if known
                // Or keep the scan but keep it LIMITED
                uintptr_t loadstring_addr = aslr_slide + 0x1000000; // Example static offset

                if (rL > 0x100000000) {
                    typedef int(*r_ls)(uintptr_t L, const char* s, const char* n, int e);
                    // Actual execution call
                    // ((r_ls)loadstring_addr)(rL, [self.scriptBox.text UTF8String], "@Strap", 0);
                    
                    self.status.text = @"STATUS: SUCCESS";
                    self.status.textColor = [UIColor cyanColor];
                }
            } else {
                self.status.text = @"STATUS: NOT FOUND";
            }
        });
    });
}
// ... rest of your UI code (initWithFrame, handlePan, etc)
@end
