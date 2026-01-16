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
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.85];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, frame.size.width, 40)];
        title.text = @"BLOCKSS EXECUTOR";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:24];
        [self addSubview:title];

        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(20, 100, frame.size.width - 40, frame.size.height - 250)];
        _scriptBox.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
        _scriptBox.textColor = [UIColor cyanColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:14];
        _scriptBox.layer.cornerRadius = 10;
        _scriptBox.text = @"-- Loadstring / Instance Test\ngame.Workspace.Gravity = 0";
        [self addSubview:_scriptBox];

        UIButton *execBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        execBtn.frame = CGRectMake(frame.size.width/2 - 100, frame.size.height - 100, 200, 50);
        execBtn.backgroundColor = [UIColor systemBlueColor];
        execBtn.layer.cornerRadius = 25;
        [execBtn setTitle:@"EXECUTE" forState:UIControlStateNormal];
        [execBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [execBtn addTarget:self action:@selector(runScript) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:execBtn];
    }
    return self;
}

- (void)runScript {
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [gen impactOccurred];
    NSLog(@"Sending to Lua VM...");
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

        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:win.bounds];
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
