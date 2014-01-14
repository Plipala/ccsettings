static void sshNotificationOn(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)   
{
    system("launchctl load -w /Library/LaunchDaemons/com.openssh.sshd.plist");
    system("echo \"1\" > /tmp/sshstatus");
}

static void sshNotificationOff(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)   
{
    system("launchctl unload /Library/LaunchDaemons/com.openssh.sshd.plist");
    system("echo \"0\" > /tmp/sshstatus");
}

static void sshNotificationStatus(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)   
{
    if (system("launchctl list | grep com.openssh.sshd > /dev/null"))
    {
    	system("echo \"0\" > /tmp/sshstatus");
    }
    else {
    	system("echo \"1\" > /tmp/sshstatus");
    }
}

static void wpNotificationOn(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)   
{
    system("launchctl load -w /System/Library/LaunchDaemons/agae.wallproxy.plist");
}

static void wpNotificationOff(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)   
{
    system("launchctl unload -w /System/Library/LaunchDaemons/agae.wallproxy.plist");
    system("rm -rf /var/log/wallproxy.log");
}


int main(int argc, char **argv, char **envp) {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &sshNotificationOn, CFSTR("com.ccsettings.ssh.on"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &sshNotificationOff, CFSTR("com.ccsettings.ssh.off"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &sshNotificationStatus, CFSTR("com.ccsettings.ssh.status"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &wpNotificationOn, CFSTR("com.ccsettings.wp.on"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &wpNotificationOff, CFSTR("com.ccsettings.wp.off"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFRunLoopRun();
	return 0;
}

// vim:ft=objc
