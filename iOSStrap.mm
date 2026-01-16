#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/mach_vm.h> // <--- THIS FIXES THE ERROR
#import <stdint.h>

// --- ADVANCED MEMORY SCANNER ---
uintptr_t scan_for_sig(const char* target, size_t len) {
    mach_vm_address_t addr = 0;
    mach_vm_size_t size;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name;

    // Corrected to use mach_vm_region properly
    while (mach_vm_region(mach_task_self(), &addr, &size, VM_REGION_BASIC_INFO_64, (mach_msg_type_number_t*)&info, &count, &object_name) == KERN_SUCCESS) {
        if ((info.protection & VM_PROT_READ) && (info.protection & VM_PROT_EXECUTE)) {
            for (uintptr_t i = (uintptr_t)addr; i < (uintptr_t)(addr + size - len); i++) {
                if (memcmp((void*)i, target, len) == 0) return i;
            }
        }
        addr += size;
    }
    return 0;
}

// --- UI AND ENGINE LOGIC ---
@interface iOSStrapMenu : UIView
@property (nonatomic, strong) UITextView *scriptBox;
@property (nonatomic, strong) UILabel *status;
@end

@implementation iOSStrapMenu
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
        self.layer.cornerRadius = 20;
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [UIColor systemBlueColor].CGColor;

        _status = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 20)];
        _status.text = @"STATUS: READY";
        _status.textColor = [UIColor greenColor];
        _status.textAlignment = NSTextAlignmentCenter;
        _status.font = [UIFont boldSystemFontOfSize:10];
        [self addSubview:_status];

        _scriptBox = [[UITextView alloc] initWithFrame:CGRectMake(10, 40, frame.size.width - 20, frame.size.height - 100)];
        _scriptBox.backgroundColor = [UIColor blackColor];
        _scriptBox.textColor = [UIColor cyanColor];
        _scriptBox.font = [UIFont fontWithName:@"Courier" size:12];
        _scriptBox.text = @"print('Blockss Loaded')\ngame.Workspace.Gravity = 0";
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

- (void)runScript {
    _status.text = @"SCANNING MEMORY...";
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        // Example Sig: Searching for Luau Print function
        uintptr_t found = scan_for_sig("\x55\x48\x89\xE5\x41\x57\x41\x56", 8);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (found) {
                _status.text = @"ENGINE FOUND! EXECUTING...";
                _status.textColor = [UIColor cyanColor];
                AudioServicesPlaySystemSound(1520);
            } else {
                _status.text = @"SCAN FAILED: SIG OUTDATED";
                _status.textColor = [UIColor redColor];
            }
        });
    });
}
@end

// --- FLOATING BUTTON ---
@interface BlockssButton : UIButton
@end

@implementation BlockssButton
static iOSStrapMenu *sharedMenu;

- (void)tapped { 
    sharedMenu.hidden = !sharedMenu.hidden; 
    [self.superview bringSubviewToFront:sharedMenu];
}

- (void)vanish { 
    [sharedMenu removeFromSuperview]; 
    [self removeFromSuperview]; 
    AudioServicesPlaySystemSound(1521);
}
@end

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        // Modern Way to get the Window (Fixes Deprecation)
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        win = window;
                        break;
                    }
                }
            }
        }
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;
        
        if (win) {
            sharedMenu = [[iOSStrapMenu alloc] initWithFrame:CGRectMake(win.center.x - 170, win.center.y - 150, 340, 300)];
            sharedMenu.hidden = YES;
            [win addSubview:sharedMenu];

            BlockssButton *btn = [[BlockssButton alloc] initWithFrame:CGRectMake(50, 100, 60, 60)];
            btn.backgroundColor = [UIColor systemBlueColor];
            btn.layer.cornerRadius = 30;
            [btn setTitle:@"B" forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btn addTarget:btn action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
            
            UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:btn action:@selector(vanish)];
            lp.minimumPressDuration = 2.0;
            [btn addGestureRecognizer:lp];
            [win addSubview:btn];
        }
    });
}
