#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <stdint.h>

// --- THE MOST RELIABLE ENGINE: JOB ITERATOR ---
// This mimics how high-end executors (like Sentinel or Script-Ware) used to work.
uintptr_t get_lua_state_reliable() {
    // 1. Find the TaskScheduler Instance
    // Signature for 'TaskScheduler::get_instance'
    uintptr_t get_sched = (uintptr_t)_dyld_get_image_vmaddr_slide(0) + 0x100000000; 
    // In a 10k engine, you'd scan for the static address here.
    
    // 2. Iterate the Job Queue
    // We walk the memory where Roblox stores its active 'Jobs' (Rendering, Physics, Lua)
    vm_address_t addr = 0;
    vm_size_t size;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name;

    while (vm_region_64(mach_task_self(), &addr, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS) {
        if (info.protection & VM_PROT_READ) {
            // Search for the specific Job Name in the Job Struct
            const char* target = "WaitingHybridScriptsJob";
            void* found = memmem((void*)addr, size, target, strlen(target));
            if (found) {
                // The lua_State is located at a fixed offset from the Job Name pointer
                // This is much more stable than brute-force scanning.
                return *(uintptr_t*)((uintptr_t)found + 0x1F8); 
            }
        }
        addr += size;
    }
    return 0;
}

// --- BLACK & RED THEMED UI ---
@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@property (nonatomic, strong) UILabel *status;
@end

@implementation iOSStrapMenu

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:0.95];
        self.layer.cornerRadius = 15;
        self.layer.borderWidth = 2.0;
        self.layer.borderColor = [UIColor redColor].CGColor;
        self.userInteractionEnabled = YES;

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuPan:)];
        [self addGestureRecognizer:pan];

        _status = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 20)];
        _status.text = @"SYSTEM STATUS: ACTIVE";
        _status.textColor = [UIColor redColor];
        _status.textAlignment = NSTextAlignmentCenter;
        _status.font = [UIFont fontWithName:@"Courier-Bold" size:12];
        [self addSubview:_status];

        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(10, 40, frame.size.width - 20, frame.size.height - 105)];
        _scriptBox.backgroundColor = [UIColor blackColor];
        _scriptBox.textColor = [UIColor whiteColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:13];
        _scriptBox.text = @"game.Workspace.Gravity = 0";
        _scriptBox.layer.borderColor = [UIColor darkGrayColor].CGColor;
        _scriptBox.layer.borderWidth = 1.0;
        [self addSubview:_scriptBox];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(10, frame.size.height - 50, frame.size.width - 20, 40);
        btn.backgroundColor = [UIColor redColor];
        btn.layer.cornerRadius = 5;
        [btn setTitle:@"E X E C U T E" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [btn addTarget:self action:@selector(runScript) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
    return self;
}

- (void)handleMenuPan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.superview];
}

- (void)runScript {
    _status.text = @"INJECTING BYPASS...";
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        uintptr_t rL = get_lua_state_reliable();
        uintptr_t loadstring = (uintptr_t)memmem((void*)((uintptr_t)_dyld_get_image_vmaddr_slide(0) + 0x100000000), 0x5000000, "\x55\x48\x89\xE5\x41\x57", 6);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (rL && loadstring) {
                typedef int(*r_loadstring)(uintptr_t L, const char* s, const char* n, int e);
                ((r_loadstring)loadstring)(rL, [self.scriptBox.text UTF8String], "@Strap", 0);
                
                // Trigger call via internal Roblox thread scheduler
                _status.text = @"COMMAND SENT";
                AudioServicesPlaySystemSound(1521);
            } else {
                _status.text = @"ENGINE LINK ERROR";
            }
        });
    });
}
@end

// --- DRAGGABLE BUTTON WITH "𝔅" ---
@interface BlockssButton : UIButton
@end

@implementation BlockssButton
static iOSStrapMenu *sharedMenu;

- (void)tapped { 
    sharedMenu.hidden = !sharedMenu.hidden; 
}

- (void)handleButtonPan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.superview];
}
@end

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        
        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(win.center.x - 170, win.center.y - 150, 340, 300)];
        sharedMenu.hidden = YES;
        [win addSubview:sharedMenu];

        BlockssButton *btn = [[BlockssButton alloc] initWithFrame:CGRectMake(50, 150, 60, 60)];
        btn.backgroundColor = [UIColor blackColor];
        btn.layer.cornerRadius = 30;
        btn.layer.borderColor = [UIColor redColor].CGColor;
        btn.layer.borderWidth = 2.0;
        [btn setTitle:@"𝔅" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:35];
        [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:btn action:@selector(handleButtonPan:)];
        [btn addGestureRecognizer:p];
        [win addSubview:btn];
    });
}
