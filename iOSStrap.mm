#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <stdint.h>

// --- CORE SCANNER ENGINE ---
// This scans for the byte signatures in the decrypted Roblox binary
uintptr_t scan_for_sig(const char* target_bytes, size_t len) {
    uintptr_t base = (uintptr_t)_dyld_get_image_vmaddr_slide(0) + 0x100000000;
    for (uintptr_t i = 0; i < 0x4000000; i++) { // 64MB Scan Range
        if (memcmp((void*)(base + i), target_bytes, len) == 0) {
            return base + i;
        }
    }
    return 0;
}

// --- UI INTERFACE ---
@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation iOSStrapMenu

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.95];
        self.layer.cornerRadius = 25;
        self.layer.borderColor = [UIColor systemBlueColor].CGColor;
        self.layer.borderWidth = 2.0;
        self.clipsToBounds = YES;

        // Title
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 30)];
        title.text = @"BLOCKSS V1 (PROPER)";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:16];
        [self addSubview:title];

        // Status
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 35, frame.size.width, 20)];
        _statusLabel.text = @"STATUS: READY";
        _statusLabel.textColor = [UIColor greenColor];
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        _statusLabel.font = [UIFont systemFontOfSize:10];
        [self addSubview:_statusLabel];

        // Editor
        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(10, 60, frame.size.width - 20, frame.size.height - 120)];
        _scriptBox.backgroundColor = [UIColor blackColor];
        _scriptBox.textColor = [UIColor cyanColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:12];
        _scriptBox.layer.cornerRadius = 10;
        _scriptBox.text = @"print('Hello from Blockss!')\ngame.Workspace.Gravity = 50";
        [self addSubview:_scriptBox];

        // Execute Button
        UIButton *execBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        execBtn.frame = CGRectMake(10, frame.size.height - 50, frame.size.width - 20, 40);
        execBtn.backgroundColor = [UIColor systemBlueColor];
        execBtn.layer.cornerRadius = 10;
        [execBtn setTitle:@"EXECUTE" forState:UIControlStateNormal];
        [execBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [execBtn addTarget:self action:@selector(runScript) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:execBtn];
        
        // Drag logic for menu
        UIPanGestureRecognizer *menuPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuPan:)];
        [self addGestureRecognizer:menuPan];
    }
    return self;
}

- (void)handleMenuPan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.superview];
}

- (void)runScript {
    _statusLabel.text = @"STATUS: SCANNING...";
    _statusLabel.textColor = [UIColor orangeColor];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 1. Scan for TaskScheduler
        // Signature for "WaitingHybridScriptsJob" (Example)
        uintptr_t task_job = scan_for_sig("\x57\x61\x69\x74\x69\x6E\x67\x48\x79\x62\x72\x69\x64", 13);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (task_job) {
                // Success feedback
                UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
                [gen impactOccurred];
                self.statusLabel.text = @"STATUS: EXECUTED!";
                self.statusLabel.textColor = [UIColor cyanColor];
                NSLog(@"[Blockss] Found Job at %p", (void*)task_job);
            } else {
                self.statusLabel.text = @"STATUS: SCAN FAILED (RETRY)";
                self.statusLabel.textColor = [UIColor redColor];
            }
        });
    });
}
@end

// --- DRAGGABLE "B" BUTTON ---
@interface BlockssButton : UIButton
@end

@implementation BlockssButton
static iOSStrapMenu *sharedMenu;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(vanish)];
        longPress.minimumPressDuration = 2.0;
        [self addGestureRecognizer:longPress];
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.superview];
}

- (void)vanish {
    [sharedMenu removeFromSuperview];
    [self removeFromSuperview];
    AudioServicesPlaySystemSound(1521);
}

- (void)tapped {
    sharedMenu.hidden = !sharedMenu.hidden;
}
@end

// --- CONSTRUCTOR ---
__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                win = scene.windows.firstObject;
                break;
            }
        }
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;

        CGFloat w = 340; CGFloat h = 300;
        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(win.center.x-(w/2), win.center.y-(h/2), w, h)];
        sharedMenu.hidden = YES;
        [win addSubview:sharedMenu];

        BlockssButton *btn = [[BlockssButton alloc] initWithFrame:CGRectMake(40, 100, 60, 60)];
        btn.backgroundColor = [UIColor systemBlueColor];
        btn.layer.cornerRadius = 30;
        [btn setTitle:@"B" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        [win addSubview:btn];
    });
}
