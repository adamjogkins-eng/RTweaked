#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/mach_vm.h> // Fixed: Missing header for vm_size_t
#import <stdint.h>

// --- UI DEFINITION ---
@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@property (nonatomic, strong) UILabel *status;
@end

// --- THE MAIN BOX (Implementation) ---
@implementation iOSStrapMenu

// Helper: Checks if memory is safe to touch without crashing
bool is_memory_readable(void *ptr, size_t size) {
    vm_size_t outSize;
    vm_offset_t outAddr;
    // This is the "Safe" way to check memory permission
    kern_return_t kr = mach_vm_read(mach_task_self(), (vm_address_t)ptr, size, &outAddr, &outSize);
    return (kr == KERN_SUCCESS);
}

// Helper: Scans for the engine "Signature"
uintptr_t scan_for_sig(const char* target, size_t len) {
    uintptr_t base = (uintptr_t)_dyld_get_image_vmaddr_slide(0) + 0x100000000;
    // Scan up to 100MB of memory for the signature
    for (uintptr_t i = base; i < base + 0x6400000; i++) {
        if (is_memory_readable((void*)i, len)) {
            if (memcmp((void*)i, target, len) == 0) return i;
        }
    }
    return 0;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
        self.layer.cornerRadius = 20;
        self.layer.borderWidth = 2;
        self.layer.borderColor = [UIColor redColor].CGColor;
        self.userInteractionEnabled = YES;

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuPan:)];
        [self addGestureRecognizer:pan];

        _status = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 20)];
        _status.text = @"𝔅 | SYSTEM WAITING";
        _status.textColor = [UIColor redColor]; // Short-hand color!
        _status.textAlignment = NSTextAlignmentCenter;
        _status.font = [UIFont fontWithName:@"Courier-Bold" size:12];
        [self addSubview:_status];

        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(10, 40, frame.size.width - 20, frame.size.height - 110)];
        _scriptBox.backgroundColor = [UIColor blackColor];
        _scriptBox.textColor = [UIColor whiteColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:13];
        _scriptBox.text = @"game.Workspace.Gravity = 0";
        _scriptBox.layer.cornerRadius = 8;
        [self addSubview:_scriptBox];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(10, frame.size.height - 55, frame.size.width - 20, 45);
        btn.backgroundColor = [UIColor redColor];
        btn.layer.cornerRadius = 10;
        [btn setTitle:@"E X E C U T E" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
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
    _status.text = @"STATUS: BYPASSING...";
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        uintptr_t job_addr = scan_for_sig("WaitingHybridScriptsJob", 23);
        uintptr_t loadstring = scan_for_sig("\x55\x48\x89\xE5\x41\x57\x41\x56", 8);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (job_addr && loadstring) {
                uintptr_t state_ptr_addr = job_addr + 0x1F8; // Common offset
                if (is_memory_readable((void*)state_ptr_addr, 8)) {
                    uintptr_t rL = *(uintptr_t*)state_ptr_addr;
                    
                    typedef int(*r_ls)(uintptr_t L, const char* s, const char* n, int e);
                    ((r_ls)loadstring)(rL, [self.scriptBox.text UTF8String], "@Strap", 0);
                    
                    _status.text = @"STATUS: SUCCESS";
                    _status.textColor = [UIColor cyanColor];
                    AudioServicesPlaySystemSound(1520);
                }
            } else {
                _status.text = @"STATUS: LINK ERROR";
            }
        });
    });
}
@end

// --- THE BUTTON IMPLEMENTATION ---
@interface BlockssButton : UIButton
@end

@implementation BlockssButton
static iOSStrapMenu *sharedMenu;
- (void)tapped { sharedMenu.hidden = !sharedMenu.hidden; }
- (void)handlePan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.superview];
}
@end

// --- CONSTRUCTOR ---
__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        if (!win) return;

        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(win.center.x - 175, win.center.y - 150, 350, 300)];
        sharedMenu.hidden = YES;
        [win addSubview:sharedMenu];

        BlockssButton *btn = [[BlockssButton alloc] initWithFrame:CGRectMake(100, 100, 60, 60)];
        btn.backgroundColor = [UIColor blackColor];
        btn.layer.cornerRadius = 30;
        btn.layer.borderWidth = 2;
        btn.layer.borderColor = [UIColor redColor].CGColor;
        [btn setTitle:@"𝔅" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:30];
        [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:btn action:@selector(handlePan:)];
        [btn addGestureRecognizer:p];
        [win addSubview:btn];
    });
}
