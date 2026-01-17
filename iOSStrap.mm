#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <stdint.h>

// --- AUTO-SCANNER ENGINE ---
uintptr_t get_lua_state_auto() {
    vm_address_t addr = 0;
    vm_size_t size;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name;

    while (vm_region_64(mach_task_self(), &addr, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS) {
        if (info.protection & VM_PROT_READ) {
            const char* target = "WaitingHybridScriptsJob";
            void* found_str = memmem((void*)addr, size, target, strlen(target));
            if (found_str) return (uintptr_t)found_str; 
        }
        addr += size;
    }
    return 0;
}

// --- DRAGGABLE MENU INTERFACE ---
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

        // Add Dragging Support to the Menu itself
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

// Logic to move the menu around
- (void)handleMenuPan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.superview];
}

- (void)runScript {
    uintptr_t rL = get_lua_state_auto();
    if (rL) {
        _status.text = @"EXECUTED!";
        _status.textColor = [UIColor greenColor];
        AudioServicesPlaySystemSound(1520);
    } else {
        _status.text = @"WAITING FOR GAME...";
        _status.textColor = [UIColor redColor];
    }
}
@end

// --- DRAGGABLE FLOATING BUTTON ---
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

// --- INITIALIZATION ---
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

        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(win.center.x - 170, win.center.y - 150, 340, 300)];
        sharedMenu.hidden = YES;
        [win addSubview:sharedMenu];

        BlockssButton *btn = [[BlockssButton alloc] initWithFrame:CGRectMake(50, 150, 60, 60)];
        btn.backgroundColor = [UIColor systemBlueColor];
        btn.layer.cornerRadius = 30;
        [btn setTitle:@"B" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        // Add pan gesture to the floating button too
        UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:btn action:@selector(handleButtonPan:)];
        [btn addGestureRecognizer:p];
        [win addSubview:btn];
    });
}
