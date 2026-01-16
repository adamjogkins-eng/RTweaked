#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

// 1. THE MAIN MENU CLASS
@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UIVisualEffectView *blurView;
@end

@implementation iOSStrapMenu
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 25;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];

        // Glass Effect
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        _blurView.frame = self.bounds;
        [self addSubview:_blurView];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 30)];
        title.text = @"Blockss Optimizer";
        title.textColor = [UIColor systemBlueColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:18];
        [_blurView.contentView addSubview:title];

        // 6 Universal Admin Toggles
        NSArray *cmds = @[@"Speed Hack", @"Infinite Jump", @"Fly Mode", @"No Clip", @"Auto Click", @"Anti-AFK"];
        for (int i = 0; i < cmds.count; i++) {
            [self addToggle:cmds[i] y:50 + (i * 40)];
        }
    }
    return self;
}

- (void)addToggle:(NSString *)name y:(CGFloat)y {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 140, 30)];
    lbl.text = name;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:14];
    [_blurView.contentView addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(self.frame.size.width - 70, y, 50, 30)];
    [sw addTarget:self action:@selector(hapticFeedback) forControlEvents:UIControlEventValueChanged];
    [_blurView.contentView addSubview:sw];
}

- (void)hapticFeedback {
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [gen impactOccurred];
}

// Make the menu draggable
- (void)touchesMoved:(NSSet*)t withEvent:(UIEvent*)e {
    self.center = [[t anyObject] locationInView:self.superview];
}
@end

// 2. THE FLOATING BUTTON CLASS
@interface BlockssButton : UIButton
@end

@implementation BlockssButton
static iOSStrapMenu *sharedMenu;

- (void)tapped {
    sharedMenu.hidden = !sharedMenu.hidden;
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [gen impactOccurred];
}

- (void)touchesMoved:(NSSet*)t withEvent:(UIEvent*)e {
    self.center = [[t anyObject] locationInView:self.superview];
}
@end

// 3. THE INITIALIZER (THE BRAIN)
__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (!win) return;

        // Create Menu
        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(50, 150, 260, 300)];
        sharedMenu.hidden = YES;
        [win addSubview:sharedMenu];

        // Create Button
        BlockssButton *btn = [BlockssButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(20, 200, 60, 60);
        btn.backgroundColor = [UIColor colorWithRed:0.0 green:0.4 blue:1.0 alpha:0.9];
        btn.layer.cornerRadius = 30;
        [btn setTitle:@"B" forState:UIControlStateNormal];
        [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        [win addSubview:btn];
    });
}
