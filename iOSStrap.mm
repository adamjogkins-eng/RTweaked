#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <stdint.h>

@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@end

@implementation iOSStrapMenu
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75]; // Dark overlay
        
        // Full-Screen Script Box
        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(20, 100, frame.size.width - 40, frame.size.height - 250)];
        _scriptBox.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _scriptBox.textColor = [UIColor greenColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:14];
        _scriptBox.layer.cornerRadius = 15;
        _scriptBox.text = @"-- Loadstring Example\nloadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()";
        [self addSubview:_scriptBox];

        // Execute Button (Centered at bottom)
        UIButton *execBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        execBtn.frame = CGRectMake(frame.size.width/2 - 100, frame.size.height - 120, 200, 50);
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
    // This is where your loadstring logic goes
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
    NSLog(@"Loading script...");
}
@end

@interface BlockssButton : UIButton
@end

@implementation BlockssButton
static iOSStrapMenu *sharedMenu;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Long Press to VANISH
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(vanish)];
        [self addGestureRecognizer:longPress];
        
        // Pan to DRAG
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
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
    [self removeFromSuperview]; // COMPLETELY VANISHES
    AudioServicesPlaySystemSound(1521); // Heavy vibration feedback
}

- (void)tapped {
    sharedMenu.hidden = !sharedMenu.hidden;
}
@end

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:win.bounds]; // FILL FULL SCREEN
        sharedMenu.hidden = YES;
        [win addSubview:sharedMenu];

        BlockssButton *btn = [[BlockssButton alloc] initWithFrame:CGRectMake(20, 100, 60, 60)];
        btn.backgroundColor = [UIColor systemBlueColor];
        btn.layer.cornerRadius = 30;
        [btn setTitle:@"B" forState:UIControlStateNormal];
        [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        [win addSubview:btn];
    });
}
