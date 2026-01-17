#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <stdint.h>

@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@property (nonatomic, strong) UITextView *console; // New: Real-time feedback
@property (nonatomic, strong) UILabel *status;
@end

@implementation iOSStrapMenu

// Helper to log to your on-screen console
- (void)log:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.console.text = [NSString stringWithFormat:@"%@\n> %@", self.console.text, text];
        [self.console scrollRangeToVisible:NSMakeRange(self.console.text.length, 0)];
    });
}

- (void)runScript {
    [self log:@"INITIALIZING SCAN..."];
    self.status.text = @"STATUS: ACTIVE";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        uintptr_t base = (uintptr_t)_dyld_get_image_vmaddr_slide(0) + 0x100000000;
        uintptr_t foundJob = 0;
        
        // WIDER SEARCH: Scanning from 10MB to 80MB into the binary
        for (uintptr_t i = base + 0x1000000; i < base + 0x5000000; i += 8) {
            // Log every 1MB scanned to show it's not frozen
            if (i % 0x100000 == 0) {
                [self log:[NSString stringWithFormat:@"SCANNING AT: 0x%lx", i]];
            }
            
            if (memcmp((void*)i, "WaitingHybridScriptsJob", 23) == 0) {
                foundJob = i;
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (foundJob) {
                [self log:[NSString stringWithFormat:@"FOUND JOB AT: 0x%lx", foundJob]];
                self.status.text = @"STATUS: LINKED";
                self.status.textColor = [UIColor cyanColor];
            } else {
                [self log:@"ERROR: ENGINE NOT FOUND IN THIS RANGE"];
                self.status.text = @"STATUS: FAILED";
            }
        });
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
        self.layer.cornerRadius = 15;
        self.layer.borderColor = [UIColor redColor].CGColor;
        self.layer.borderWidth = 2;

        _status = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 20)];
        _status.text = @"𝔅 | SYSTEM STANDBY";
        _status.textColor = [UIColor redColor];
        _status.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_status];

        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(10, 40, frame.size.width - 20, 100)];
        _scriptBox.backgroundColor = [UIColor blackColor];
        _scriptBox.textColor = [UIColor whiteColor];
        _scriptBox.text = @"game.Workspace.Gravity = 0";
        [self addSubview:_scriptBox];

        // THE CONSOLE: This shows you the "Heartbeat" of the scanner
        _console = [[UITextView alloc] initWithFrame:CGRectMake(10, 150, frame.size.width - 20, 80)];
        _console.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
        _console.textColor = [UIColor redColor];
        _console.font = [UIFont fontWithName:@"Courier" size:10];
        _console.editable = NO;
        _console.text = @"> Console Initialized...";
        [self addSubview:_console];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(10, frame.size.height - 50, frame.size.width - 20, 40);
        btn.backgroundColor = [UIColor redColor];
        [btn setTitle:@"EXECUTE" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(runScript) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
    return self;
}
@end
