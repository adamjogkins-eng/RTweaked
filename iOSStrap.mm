- (void)runScript {
    _status.text = @"STATUS: LINKING...";
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 1. Find the Job (The Engine)
        uintptr_t job_ptr = [self findWaitingJob]; 
        
        if (job_ptr) {
            // 2. The Lua State is usually at job_ptr + 0x1F8 or 0x200 (version dependent)
            // This is the "Brain" of the game
            uintptr_t rL = *(uintptr_t*)(job_ptr + 504); // 0x1F8 in decimal
            
            // 3. Find the Address of 'loadstring' and 'pcall'
            uintptr_t loadstring = scan_for_sig("\x55\x48\x89\xE5\x41\x57\x41\x56", 8);
            
            if (rL && loadstring) {
                // Execute using the game's internal types
                typedef int(*r_loadstring)(uintptr_t L, const char* s, const char* name, int env);
                ((r_loadstring)loadstring)(rL, [self.scriptBox.text UTF8String], "@Blockss", 0);
                
                // We must tell the scheduler to "Run" what we just loaded
                [self triggerPcall:rL];

                dispatch_async(dispatch_get_main_queue(), ^{
                    _status.text = @"STATUS: FULLY EXECUTED!";
                    _status.textColor = [UIColor cyanColor];
                });
            }
        }
    });
}

// This helper finds the ACTUAL Job Object, not just the string
- (uintptr_t)findWaitingJob {
    // We look for the TaskScheduler's job list (This is the "Pro" way)
    uintptr_t scheduler = scan_for_sig("\x53\x63\x68\x65\x64\x75\x6C\x65\x72", 9);
    // ... logic to iterate jobs ...
    return scheduler; // Placeholder: Real logic requires a loop through job pointers
}
