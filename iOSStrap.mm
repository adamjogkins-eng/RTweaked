#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <stdint.h> // <--- THIS FIXES THE 'uintptr_t' ERROR

// Function Signatures for the Lua Bridge
typedef int (*Roblox_loadstring)(uintptr_t L, const char* script);
typedef int (*Roblox_pcall)(uintptr_t L, int nargs, int nresults, int errfunc);

@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UITextView *scriptBox; // Added property
@end

@implementation iOSStrapMenu

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 25;
        self.clipsToBounds = YES;

        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        _blurView.frame = self.bounds;
        [self addSubview:_blurView];

        // 1. Title
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 30)];
        title.text = @"Blockss Executor";
        title.textColor = [UIColor systemBlueColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:18];
        [_blurView.contentView addSubview:title];

        // 2. The Script Box (The Input)
        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(15, 50, 230, 150)];
        _scriptBox.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _scriptBox.textColor = [UIColor greenColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:12];
        _scriptBox.layer.cornerRadius = 10;
        _scriptBox.text = @"game.Workspace.Gravity = 0";
        [_blurView.contentView addSubview:_scriptBox];

        // 3. The Execute Button
        UIButton *execBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        execBtn.frame = CGRectMake(15, 210, 230, 40);
        execBtn.backgroundColor = [UIColor systemBlueColor];
        execBtn.layer.cornerRadius = 10;
        [execBtn setTitle:@"EXECUTE SCRIPT" forState:UIControlStateNormal];
        [execBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [execBtn addTarget:self action:@selector(runScript:) forControlEvents:UIControlEventTouchUpInside];
        [_blurView.contentView addSubview:execBtn];
    }
    return self;
}

// THIS METHOD IS NOW INSIDE THE CLASS - FIXES THE 'missing context' ERROR
- (void)runScript:(UIButton *)sender {
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [gen impactOccurred];

    // Status logic
    [self showStatus:@"SENDING TO VM..."];
    
    // Placeholder for Scanner
    NSLog(@"Executing: %@", _scriptBox.text);
}

- (void)showStatus:(NSString *)msg {
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(0, 260, 260, 20)];
    status.text = msg;
    status.textColor = [UIColor cyanColor];
    status.textAlignment = NSTextAlignmentCenter;
    status.font = [UIFont boldSystemFontOfSize:12];
    [_blurView.contentView addSubview:status];
    [UIView animateWithDuration:2.0 animations:^{ status.alpha = 0; }];
}

@end

// --- FLOATING BUTTON & INITIALIZER ---
@interface BlockssButton : UIButton
@end
@implementation BlockssButton
static iOSStrapMenu *sharedMenu;
- (void)tapped {
    sharedMenu.hidden = !sharedMenu.hidden;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
}
@end

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(50, 150, 260, 300)];
        sharedMenu.hidden = YES;
        [win addSubview:sharedMenu];

        BlockssButton *btn = [BlockssButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(20, 200, 60, 60);
        btn.backgroundColor = [UIColor systemBlueColor];
        btn.layer.cornerRadius = 30;
        [btn setTitle:@"B" forState:UIControlStateNormal];
        [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        [win addSubview:btn];
    });
}
