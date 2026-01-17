#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <stdint.h>
#import <AudioToolbox/AudioToolbox.h>

// --- INTERFACE ---
@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@property (nonatomic, strong) UITextView *console;
@property (nonatomic, strong) UILabel *status;
- (void)log:(NSString *)text;
@end

@interface BlockssButton : UIButton
- (void)tapped;
@end

// --- GLOBAL VARIABLES ---
static iOSStrapMenu *sharedMenu;

// --- IMPLEMENTATION ---
@implementation iOSStrapMenu

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Main Menu Styling
        self.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
        self.layer.cornerRadius = 15;
        self.layer.borderColor = [UIColor redColor].CGColor;
        self.layer.borderWidth = 2;
        self.userInteractionEnabled = YES;

        // Pan Gesture for Menu
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuPan:)];
        [self addGestureRecognizer:pan];

        // Status Label
        _status = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 20)];
        _status.text = @"𝔅 | SYSTEM STANDBY";
        _status.textColor = [UIColor redColor];
        _status.textAlignment = NSTextAlignmentCenter;
        _status.font = [UIFont fontWithName:@"Courier-Bold" size:12];
        [self addSubview:_status];

        // Script Editor
        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(10, 40, frame.size.width - 20, 80)];
        _scriptBox.backgroundColor = [UIColor blackColor];
        _scriptBox.textColor = [UIColor whiteColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:12];
        _scriptBox.text = @"game.Workspace.Gravity = 0";
        _scriptBox.layer.cornerRadius = 5;
        [self addSubview:_scriptBox];

        // Live Console
        _console = [[UITextView alloc] initWithFrame:CGRectMake(10, 130, frame.size.width - 20, 100)];
        _console.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
        _console.textColor = [UIColor redColor];
        _console.font = [UIFont fontWithName:@"Courier" size:10];
        _console.editable = NO;
        _console.text = @"> Console Initialized...\n> Waiting for injection...";
        _console.layer.cornerRadius = 5;
        [self addSubview:_console];

        // Execute Button
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(10, frame.size.height - 50, frame.size.width - 20, 40);
        btn.backgroundColor = [UIColor redColor];
        btn.layer.cornerRadius = 8;
        [btn setTitle:@"E X E C U T E" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [btn addTarget:self action:@selector(runScript) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
    return self;
}

- (void)log:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.console.text = [NSString stringWithFormat:@"%@\n> %@", self.console.text, text];
        [self.console scrollRangeToVisible:NSMakeRange(self.console.text.length, 0)];
    });
}

- (void)handleMenuPan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.superview];
}

- (void)runScript {
    [self log:@"STARTING SCAN..."];
    self.status.text = @"STATUS: SCANNING";
    self.status.textColor = [UIColor orangeColor];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        uintptr_t base = (uintptr_t)_dyld_get_image_vmaddr_slide(0) + 0x100000000;
        uintptr_t foundJob = 0;
        
        // SCANNING RANGE: 0x1000000 to 0x5000000
        for (uintptr_t i = base + 0x1000000; i < base + 0x5000000; i += 8) {
            // Heartbeat update every 1MB
            if (i % 0x100000 == 0) {
                [self log:[NSString stringWithFormat:@"AT: 0x%lx", i]];
            }
            
            if (memcmp((void*)i, "WaitingHybridScriptsJob", 23) == 0) {
                foundJob = i;
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (foundJob) {
                [self log:[NSString stringWithFormat:@"SUCCESS: 0x%lx", foundJob]];
                self.status.text = @"STATUS: LINKED";
                self.status.textColor = [UIColor cyanColor];
                AudioServicesPlaySystemSound(1520);
                
                // --- LUA EXECUTION LOGIC ---
                // Here we would use the pointer foundJob + offset to get rL
                // and call the loadstring function.
            } else {
                [self log:@"FAIL: ENGINE NOT FOUND"];
                self.status.text = @"STATUS: NOT FOUND";
                self.status.textColor = [UIColor redColor];
            }
        });
    });
}
@end

@implementation BlockssButton
- (void)tapped {
    sharedMenu.hidden = !sharedMenu.hidden;
    AudioServicesPlaySystemSound(1519); // Haptic feedback
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.superview];
}
@end

// --- CONSTRUCTOR ---
__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *mainWindow = nil;
        
        // NEW Scene-based window search for iOS 15+
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                mainWindow = ((UIWindowScene *)scene).windows.firstObject;
                break;
            }
        }
        
        if (!mainWindow) mainWindow = [UIApplication sharedApplication].keyWindow;

        if (mainWindow) {
            // Setup Menu
            sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(mainWindow.center.x - 175, 50, 350, 280)];
            sharedMenu.hidden = YES;
            [mainWindow addSubview:sharedMenu];

            // Setup Floating Button
            BlockssButton *btn = [[BlockssButton alloc] initWithFrame:CGRectMake(20, 100, 60, 60)];
            btn.backgroundColor = [UIColor blackColor];
            btn.layer.cornerRadius = 30;
            btn.layer.borderColor = [UIColor redColor].CGColor;
            btn.layer.borderWidth = 2;
            [btn setTitle:@"𝔅" forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont boldSystemFontOfSize:28];
            
            [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
            
            UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:btn action:@selector(handlePan:)];
            [btn addGestureRecognizer:p];
            
            [mainWindow addSubview:btn];
            [mainWindow bringSubviewToFront:btn];
        }
    });
}
