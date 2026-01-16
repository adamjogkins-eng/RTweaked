#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <stdint.h>

@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@end

@implementation iOSStrapMenu
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Half-screen look with rounded corners
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
        self.layer.cornerRadius = 30;
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [UIColor systemBlueColor].CGColor;
        self.clipsToBounds = YES;
        
        // Header
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, frame.size.width, 30)];
        title.text = @"BLOCKSS EXECUTOR";
        title.textColor = [UIColor systemBlueColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:18];
        [self addSubview:title];

        // Adjusted Script Box for half-screen
        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(15, 55, frame.size.width - 30, frame.size.height - 130)];
        _scriptBox.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1.0];
        _scriptBox.textColor = [UIColor cyanColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:13];
        _scriptBox.layer.cornerRadius = 12;
        _scriptBox.text = @"-- Half-Screen Executor Ready\ngame.Workspace.Gravity = 0";
        [self addSubview:_scriptBox];

        // Compact Execute Button
        UIButton *execBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        execBtn.frame = CGRectMake(15, frame.size.height - 65, frame.size.width - 30, 50);
        execBtn.backgroundColor = [UIColor systemBlueColor];
        execBtn.layer.cornerRadius = 15;
        [execBtn setTitle:@"EXECUTE" forState:UIControlStateNormal];
        [execBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [execBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
        [execBtn addTarget:self action:@selector(runScript) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:execBtn];
        
        // Allow the whole menu to be draggable
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
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [gen impactOccurred];
    NSLog(@"Executing script in half-screen mode...");
}
@end

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

        // Creating a half-screen menu (approx 350x400)
        CGFloat menuWidth = 350;
        CGFloat menuHeight = 400;
        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(win.center.x - (menuWidth/2), win.center.y - (menuHeight/2), menuWidth, menuHeight)];
        sharedMenu.hidden = YES;
        [win addSubview:sharedMenu];

        BlockssButton *btn = [[BlockssButton alloc] initWithFrame:CGRectMake(50, 150, 60, 60)];
        btn.backgroundColor = [UIColor systemBlueColor];
        btn.layer.cornerRadius = 30;
        [btn setTitle:@"B" forState:UIControlStateNormal];
        [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        [win addSubview:btn];
    });
}
