// Helper to check if memory is safe to touch
bool is_memory_readable(void *ptr, size_t size) {
    vm_size_t outSize;
    vm_address_t outAddr;
    kern_return_t kr = mach_vm_read(mach_task_self(), (vm_address_t)ptr, size, &outAddr, &outSize);
    return (kr == KERN_SUCCESS);
}

- (void)runScript {
    _status.text = @"STATUS: STABILIZING...";
    _status.textColor = [UIColor orangeColor];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        uintptr_t job_addr = scan_for_sig("WaitingHybridScriptsJob", 23);
        uintptr_t loadstring = scan_for_sig("\x55\x48\x89\xE5\x41\x57\x41\x56", 8);
        
        if (job_addr && loadstring) {
            // THE FIX: Check if the offset address is actually readable
            uintptr_t state_ptr_addr = job_addr + 0x1F8; 
            
            if (is_memory_readable((void*)state_ptr_addr, 8)) {
                uintptr_t rL = *(uintptr_t*)state_ptr_addr;
                
                // One more check to ensure the Lua State itself is readable
                if (rL > 0x100000000 && is_memory_readable((void*)rL, 16)) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        typedef int(*r_ls)(uintptr_t L, const char* s, const char* n, int e);
                        ((r_ls)loadstring)(rL, [self.scriptBox.text UTF8String], "@Strap", 0);
                        
                        _status.text = @"STATUS: SUCCESS";
                        _status.textColor = [UIColor greenColor];
                        AudioServicesPlaySystemSound(1520);
                    });
                    return;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _status.text = @"STATUS: SECURITY BLOCK";
            _status.textColor = [UIColor redColor];
        });
    });
}
