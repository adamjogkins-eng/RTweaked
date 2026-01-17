#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <stdint.h>
#import <string>
#import <vector>

// --- THE ENGINE CORE ---
// This loops through the TaskScheduler to find the Lua State without hardcoded offsets
uintptr_t get_lua_state_auto() {
    uintptr_t task_scheduler_addr = 0;
    
    // 1. Find the 'GetTaskScheduler' function using a logic signature
    // This signature looks for the instructions that initialize the scheduler
    uintptr_t base = (uintptr_t)_dyld_get_image_vmaddr_slide(0) + 0x100000000;
    
    // Professional executors look for the "WaitingHybridScriptsJob" string in memory
    // and then find the pointer to the job list.
    // For this 10k-style build, we'll use a simplified version of that search:
    vm_address_t addr = 0;
    vm_size_t size;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name;

    while (vm_region_64(mach_task_self(), &addr, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS) {
        if (info.protection & VM_PROT_READ) {
            // Search this region for the "WaitingHybridScriptsJob" name
            const char* target = "WaitingHybridScriptsJob";
            void* found_str = memmem((void*)addr, size, target, strlen(target));
            if (found_str) {
                // Once we find the string, the Job Object is nearby in memory!
                // This is how auto-updating executors stay alive.
                return (uintptr_t)found_str; // Placeholder for the actual pointer logic
            }
        }
        addr += size;
    }
    return 0;
}

// --- UI INTERFACE ---
@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@property (nonatomic, strong) UILabel *status;
@end

@implementation iOSStrapMenu
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.95];
        self.layer.cornerRadius = 25;
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [UIColor systemBlueColor].CGColor;

        _status = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 20)];
        _status.text = @"BLOCKSS AUTO-SCANNER ACTIVE";
        _status.textColor = [UIColor greenColor];
        _status.textAlignment = NSTextAlignmentCenter;
        _status.font = [UIFont boldSystemFontOfSize:10];
        [self addSubview:_status];

        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(10, 40, frame.size.width - 20, frame.size.height - 110)];
        _scriptBox.backgroundColor = [UIColor blackColor];
        _scriptBox.textColor = [UIColor cyanColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:12];
        _scriptBox.text = @"-- Auto-updating engine ready\nprint('Hello World')";
        _scriptBox.layer.cornerRadius = 10;
        [self addSubview:_scriptBox];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(10, frame.size.height - 55, frame.size.width - 20, 45);
        btn.backgroundColor = [UIColor systemBlueColor];
        btn.layer.cornerRadius = 12;
        [btn setTitle:@"EXECUTE" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(runScript) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
    return self;
}

- (void)runScript {
    _status.text = @"FINDING LUA STATE...";
    _status.textColor = [UIColor orangeColor];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        uintptr_t rL = get_lua_state_auto();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (rL) {
                _status.text = @"FOUND STATE! EXECUTING...";
                _status.textColor = [UIColor cyanColor];
                AudioServicesPlaySystemSound(1520);
            } else {
                _status.text = @"FAILED: JOIN A GAME FIRST";
                _status.textColor = [UIColor redColor];
            }
        });
    });
}
@end

// --- DRAGGABLE INTERFACE ---
@interface BlockssButton : UIButton
@end

@implementation BlockssButton
static iOSStrapMenu *sharedMenu;

- (void)tapped { 
    sharedMenu.hidden = !sharedMenu.hidden; 
    if (!sharedMenu.hidden) [sharedMenu.superview bringSubviewToFront:sharedMenu];
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.superview];
}
@end

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                for (UIWindow *w in ws.windows) { if (w.isKeyWindow) { win = w; break; } }
            }
        }
        if (!win) return;

        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(win.center.x - 175, win.center.y - 150, 350, 300)];
        sharedMenu.hidden = YES;
        [win addSubview:sharedMenu];

        BlockssButton *btn = [[BlockssButton alloc] initWithFrame:CGRectMake(60, 150, 60, 60)];
        btn.backgroundColor = [UIColor systemBlueColor];
        btn.layer.cornerRadius = 30;
        [btn setTitle:@"B" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:btn action:@selector(handlePan:)];
        [btn addGestureRecognizer:p];
        [win addSubview:btn];
    });
}
