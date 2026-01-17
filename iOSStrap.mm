- (void)runScript {
    _status.text = @"BYPASSING SANDBOX...";
    _status.textColor = [UIColor orangeColor];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 1. Get the base address of the game
        uintptr_t base = (uintptr_t)_dyld_get_image_vmaddr_slide(0) + 0x100000000;
        
        // 2. Instead of scanning ALL memory, we only scan the DATA segment
        // This is much safer and faster
        uintptr_t rL = 0;
        const char* target = "WaitingHybridScriptsJob";
        
        // We look for the job pointer specifically in the task scheduler
        // using a safer memory-read check
        for (uintptr_t i = 0; i < 0x2000000; i += 8) {
            uintptr_t current = base + i;
            // Check if address is valid before reading to prevent CRASH
            vm_size_t outSize;
            vm_address_t outAddr;
            if (mach_vm_read(mach_task_self(), current, 8, &outAddr, &outSize) == KERN_SUCCESS) {
                if (memcmp((void*)current, target, 23) == 0) {
                    rL = *(uintptr_t*)(current + 0x1F8);
                    break;
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (rL > 0x100000000) { // Check if it's a valid 64-bit pointer
                _status.text = @"SYSTEM LINKED";
                _status.textColor = [UIColor greenColor];
                AudioServicesPlaySystemSound(1520);
                
                // For now, let's just LOG it to see if it stays stable
                NSLog(@"[Blockss] Found State: %p", (void*)rL);
            } else {
                _status.text = @"LINK FAILED - REJOIN";
                _status.textColor = [UIColor redColor];
            }
        });
    });
}
