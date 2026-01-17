#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <stdint.h>

// --- ADVANCED MEMORY SCANNER ---
uintptr_t scan_for_sig(const char* target, size_t len) {
    vm_address_t addr = 0;
    vm_size_t size;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name;

    while (vm_region_64(mach_task_self(), &addr, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS) {
        if ((info.protection & VM_PROT_READ) && (info.protection & VM_PROT_EXECUTE)) {
            for (uintptr_t i = (uintptr_t)addr; i < (uintptr_t)(addr + size - len); i++) {
                if (memcmp((void*)i, target, len) == 0) return i;
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
        self.layer.cornerRadius = 20;
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [UIColor systemBlueColor].CGColor;
        self.userInteractionEnabled = YES;

        // DRAGGABLE MENU GESTURE
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuPan:)];
        [self addGestureRecognizer:pan];

        _status = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 20)];
        _status.text = @"BLOCKSS V2 | DRAGGABLE";
        _status.textColor = [UIColor cyanColor];
        _status.textAlignment = NSTextAlignmentCenter;
        _status.font = [UIFont boldSystemFontOfSize:10];
        [self addSubview:_status];

        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(10, 40, frame.size.width - 20, frame.size.height - 105)];
        _scriptBox.backgroundColor = [UIColor blackColor];
        _scriptBox.textColor = [UIColor greenColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:12];
        _scriptBox.text = @"game.Workspace.Gravity = 0";
        _scriptBox.layer.cornerRadius = 8;
        [self addSubview:_scriptBox];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(10, frame.size.height - 50, frame.size.width - 20, 40);
        btn.backgroundColor = [UIColor systemBlueColor];
        btn.layer.cornerRadius = 10;
        [btn setTitle:@"EXECUTE" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
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

// THE ENGINE BRIDGE
- (void)runScript {
    _status.text = @"STATUS: LINKING...";
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 1. Find the Job via name string
        uintptr_t job_name_addr = scan_for_sig("WaitingHybridScriptsJob", 23);
        
        if (job_name_addr) {
            // 2. BRUTE FORCE SCANNER: Try common offsets for the Lua State
            // Usually 0x1F8 (504) or 0x200 (512)
            uintptr_t offsets[] = {504, 512, 496, 520};
            uintptr_t loadstring = scan_for_sig("\x55\x48\x89\xE5\x41\x57\x41\x56", 8);
            uintptr_t pcall = scan_for_sig("\x40\x53\x48\x83\xEC\x20", 6);

            for (int i = 0; i < 4; i++) {
                uintptr_t rL = *(uintptr_t*)(job_name_addr + offsets[i]);
                if (rL && loadstring && pcall) {
                    typedef int(*r_loadstring)(uintptr_t L, const char* s, const char* n, int e);
                    typedef int(*r_pcall)(uintptr_t L, int na, int nr, int ef);
                    
                    ((r_loadstring)loadstring)(rL, [self.scriptBox.text UTF8String], "@Blockss", 0);
                    ((r_pcall)pcall)(rL, 0, 0, 0);
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                _status.text = @"STATUS: EXECUTED!";
                _status.textColor = [UIColor greenColor];
                AudioServicesPlaySystemSound(1520);
            });
        }
    });
}
@end

// --- DRAGGABLE CIRCULAR BUTTON ---
@interface BlockssButton : UIButton
@end

@implementation BlockssButton
static iOSStrapMenu *sharedMenu;

- (void)tapped { 
    sharedMenu.hidden = !sharedMenu.hidden; 
    if (!sharedMenu.hidden) [sharedMenu.superview bringSubviewToFront:sharedMenu];
}

- (void)handleButtonPan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.superview];
}
@end

// --- INIT ---
__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                for (UIWindow *w in ws.windows) { if (w.isKeyWindow) { win = w; break; } }
            }
        }
        if (!win) return;

        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(win.center.x - 170, win.center.y - 150, 340, 300)];
        sharedMenu.hidden = YES;
        [win addSubview:sharedMenu];

        BlockssButton *btn = [[BlockssButton alloc] initWithFrame:CGRectMake(50, 150, 60, 60)];
        btn.backgroundColor = [UIColor systemBlueColor];
        btn.layer.cornerRadius = 30;
        [btn setTitle:@"B" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:btn action:@selector(handleButtonPan:)];
        [btn addGestureRecognizer:p];
        [win addSubview:btn];
    });
}
