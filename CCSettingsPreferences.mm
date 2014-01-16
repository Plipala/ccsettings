#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <notify.h>

struct CopyDataInfo
{
    int dummy1;
    int dummy2;
};

static void _callback(){
    //Do nothing;
};

@interface PSViewController : UIViewController {
}
- (id)initForContentSize:(CGSize)size;

@end

@interface PSListController : PSViewController {
    NSArray* _specifiers;
}
@property(retain) NSArray* specifiers;
-(NSArray*)loadSpecifiersFromPlistName:(NSString*)plistName target:(id)target;
@end

@interface CCSettingsAdvSettingViewController : PSListController
@end

@implementation CCSettingsAdvSettingViewController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"CCSettingsAdvPreferences" target:self] retain];
        NSLog(@"_specifiers %@",_specifiers);
    }
    return _specifiers;
}

@end

@interface CCSettingsPreferencesListController: PSViewController <UITableViewDelegate,UITableViewDataSource>{
    UITableView *_tableView;
    NSMutableDictionary *_settingDataDictionary;
}
- (id)initForContentSize:(CGSize)size;
@end

@implementation CCSettingsPreferencesListController

- (void)save
{
    NSMutableDictionary *_settingResult = [NSMutableDictionary dictionary];
    NSArray *_enabledArray = [_settingDataDictionary objectForKey:@"Enabled"];
    for (int i = 0; i < [_enabledArray count]; ++i)
    {
        [_settingResult setObject:[NSNumber numberWithInt:i] forKey:[_enabledArray objectAtIndex:i]];
    }
    NSArray *_disabledArray = [_settingDataDictionary objectForKey:@"Disabled"];
    for (NSString *identifier in _disabledArray)
    {
        [_settingResult setObject:[NSNumber numberWithInt:-1] forKey:identifier];
    }
    [_settingResult writeToFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.plist" atomically:YES];

    notify_post("com.plipala.ccsettings.orderchanged");
}

-(void)infoButtonAction:(id)sender{
    CCSettingsAdvSettingViewController *vc = [[CCSettingsAdvSettingViewController alloc] initForContentSize:_tableView.frame.size];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (id)initForContentSize:(CGSize)size{
    if ( [[PSViewController class] instancesRespondToSelector:@selector( initForContentSize: )] )
        self = [super initForContentSize:size];
    else
        self = [super init];
    if (self) {
        [[self navigationItem] setTitle:@"CCSettings"];
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,size.width,size.height) style:UITableViewStyleGrouped];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.editing = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.allowsSelectionDuringEditing = YES;

        UIImage *settingImage = [UIImage imageWithContentsOfFile:[[NSBundle bundleWithIdentifier:@"com.plipala.ccsettingspreferences"] pathForResource:@"settings@2x" ofType:@"png"]];
        UIBarButtonItem* infoButton = [[UIBarButtonItem alloc] initWithImage:settingImage style:UIBarButtonItemStyleBordered target:self action:@selector(infoButtonAction:)];
        UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        negativeSpacer.width = -10;
        [[self navigationItem] setRightBarButtonItems:[NSArray arrayWithObjects:negativeSpacer,infoButton,nil]];
        [infoButton release];
        
        NSMutableArray *enabledArray = [NSMutableArray array];
        NSMutableArray *disableArray = [NSMutableArray array];
        
        NSDictionary *_customlizeOrderDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.plist"];
        NSDictionary *_oringinalOrderDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/CCSettings/CCSettingsOrder.plist"];
        
        NSArray *keys = [_oringinalOrderDictionary allKeys];
        for (NSString *identifier in keys) {
            if ([identifier isEqualToString:@"flux"])
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/libexec/flux"]){
                    continue;
                }
            }
            if ([identifier isEqualToString:@"ssh"])
            {
                if (!([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/ccsettingssupport"] && [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/LaunchDaemons/com.openssh.sshd.plist"]))
                {
                    continue;
                }
            }
            if ([identifier isEqualToString:@"wallproxy"])
            {
                if (!([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/ccsettingssupport"] && [[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/LaunchDaemons/agae.wallproxy.plist"]))
                {
                    continue;
                }
            }
            if ([_customlizeOrderDictionary objectForKey:identifier] != nil)
            {
                if ([[_customlizeOrderDictionary objectForKey:identifier] intValue] >= 0)
                {
                    [enabledArray addObject:identifier];
                }
                else {
                    [disableArray addObject:identifier];
                }
            }
            else if ([[_oringinalOrderDictionary objectForKey:identifier] intValue]>= 0)
            {
                [enabledArray addObject:identifier];
            }
            else {
                [disableArray addObject:identifier];
            }
        }
        
        [enabledArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([_customlizeOrderDictionary objectForKey:obj1] != nil)
            {
                if ([_customlizeOrderDictionary objectForKey:obj2] != nil)
                {
                    return [[_customlizeOrderDictionary objectForKey:obj1] compare:[_customlizeOrderDictionary objectForKey:obj2]];
                }
                else {
                    return NSOrderedAscending;
                }
            }
            else {
                if ([_customlizeOrderDictionary objectForKey:obj2] != nil)
                {
                    return NSOrderedDescending;
                }
                else {
                    return [[_oringinalOrderDictionary objectForKey:obj1] compare:[_oringinalOrderDictionary objectForKey:obj2]];
                }
            }
        }];
        _settingDataDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:enabledArray,@"Enabled",disableArray,@"Disabled",nil];
    }
    return self;
}

- (void)dealloc
{
    [_settingDataDictionary release];
    [_tableView release];
    [super dealloc];
}

-(void)viewDidLoad{
    self.navigationController.navigationBar.translucent = NO;
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (UIView*)view
{
    return _tableView;
}

- (id)table{
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return UITableViewCellEditingStyleNone;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0)
    {
        return [[NSBundle bundleWithIdentifier:@"com.plipala.ccsettingspreferences"] localizedStringForKey:@"Enabled" value:@"" table:nil];
    }
    else if (section == 1){
        return [[NSBundle bundleWithIdentifier:@"com.plipala.ccsettingspreferences"] localizedStringForKey:@"Disabled" value:@"" table:nil];
    }
    return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [[_settingDataDictionary objectForKey:@"Enabled"] count];
    }
    else if (section == 1){
        return [[_settingDataDictionary objectForKey:@"Disabled"] count];
    }
    return 0;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"CCSettingsPreferencesViewControllerCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( !cell )
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    NSString *identifier = nil;
    if (indexPath.section == 0) {
        if ([[[_settingDataDictionary objectForKey:@"Enabled"] objectAtIndex:indexPath.row] isEqualToString:@"3G4GLTE"])
        {
            identifier = [self _RATModeString];
            cell.textLabel.text = [self _RATModeString];
        }
        else {
            identifier = [[_settingDataDictionary objectForKey:@"Enabled"] objectAtIndex:indexPath.row];
            cell.textLabel.text = [[NSBundle bundleWithIdentifier:@"com.plipala.ccsettingspreferences"] localizedStringForKey:identifier value:@"" table:nil];
        }
    }
    else if (indexPath.section == 1) {
        if ([[[_settingDataDictionary objectForKey:@"Disabled"] objectAtIndex:indexPath.row] isEqualToString:@"3G4GLTE"])
        {
            identifier = [self _RATModeString];
            cell.textLabel.text = [self _RATModeString];
        }
        else {
            identifier = [[_settingDataDictionary objectForKey:@"Disabled"] objectAtIndex:indexPath.row];
            cell.textLabel.text = [[NSBundle bundleWithIdentifier:@"com.plipala.ccsettingspreferences"] localizedStringForKey:identifier value:@"" table:nil];
        }
    }
    else {
        cell.textLabel.text = @"";
        identifier = nil;
    }


    if (identifier != nil)
    {
        UIImage *cellImage = [UIImage imageWithContentsOfFile:[[NSBundle bundleWithIdentifier:@"com.plipala.ccsettingspreferences"] pathForResource:[NSString stringWithFormat:@"%@@2x",identifier] ofType:@"png"]];
        cell.imageView.image = cellImage;
    }
    else {
        cell.imageView.image = nil;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    return YES;
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath
{
    if (![fromIndexPath compare:toIndexPath])
    {
        return;
    }
    
    NSString *orig = nil;
    if ([fromIndexPath section] == 0) {
        orig = [[[_settingDataDictionary objectForKey:@"Enabled"] objectAtIndex:[fromIndexPath row]] retain];
        [[_settingDataDictionary objectForKey:@"Enabled"] removeObjectAtIndex:[fromIndexPath row]];
    }
    else if ([fromIndexPath section] == 1){
        orig = [[[_settingDataDictionary objectForKey:@"Disabled"] objectAtIndex:[fromIndexPath row]] retain];
        [[_settingDataDictionary objectForKey:@"Disabled"] removeObjectAtIndex:[fromIndexPath row]];
    }
    if (orig != nil) {
        if ([toIndexPath section] == 0) {
            [[_settingDataDictionary objectForKey:@"Enabled"] insertObject:orig atIndex:[toIndexPath row]];
        }
        else if ([toIndexPath section] == 1){
            [[_settingDataDictionary objectForKey:@"Disabled"] insertObject:orig atIndex:[toIndexPath row]];
        }
        [orig release];
    }
    [self save];
}

-(NSDictionary *)_getRATState:(NSDictionary *)stateDictionary{
    static NSDictionary *ratState= nil;
    static NSLock *ratStateLock = nil;
    if (ratStateLock == nil) {
        ratStateLock = [[NSLock alloc] init];
    }
    if (ratState == nil || stateDictionary != nil) {
        NSDictionary *status = nil;
        void *conn;
        NSMutableArray *DataRates; 
        int RATSwitchKind = 0; 
        struct CopyDataInfo info;
        
        int _4GOverride = 0;
        int _RATSwitchKind = 0;
        int _CellularDataPlanGetIsEnabled = 0;
        
        const char* CTSdkPath = "/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony";
        
        void * handle = (int*)dlopen(CTSdkPath, RTLD_LAZY);
        if(handle) {
            if (stateDictionary == nil) {
                void* (*_CTServerConnectionCreate)(CFAllocatorRef allocator,void * callback, int* err);
                *(void **)(&_CTServerConnectionCreate) = (void *)dlsym(handle,"_CTServerConnectionCreate");
                conn = _CTServerConnectionCreate(kCFAllocatorDefault, (void (*))_callback, nil);
                if ( conn )
                {
                    void (*_CTServerConnectionCopyDataStatus)(void *info, void *conn, int value, NSDictionary **status);
                    *(void **)(&_CTServerConnectionCopyDataStatus) = (void *)dlsym(handle,"_CTServerConnectionCopyDataStatus");
                    _CTServerConnectionCopyDataStatus(&info, conn, 0, &status);
                    if (!info.dummy2)
                    {
                        [status autorelease];
                    }
                    CFRelease(conn);
                }
            }
            else {
                status = stateDictionary;
            }
            
            NSMutableArray* (*CTRegistrationCopySupportedDataRates)();
            *(void **)(&CTRegistrationCopySupportedDataRates) = (void *)dlsym(handle,"CTRegistrationCopySupportedDataRates");
            DataRates = CTRegistrationCopySupportedDataRates();
            if(DataRates != nil)
            {
                if( ( [DataRates containsObject: @"kCTRegistrationDataRate3G" ]  & 0xFF )   &&  
                   ( [DataRates containsObject: @"kCTRegistrationDataRate4G" ]  & 0xFF ) ) 
                {
                    RATSwitchKind = 2;
                }
                else if( ([DataRates containsObject: @"kCTRegistrationDataRate2G" ]  & 0xFF )   &&  
                        ([DataRates containsObject: @"kCTRegistrationDataRate3G" ]  & 0xFF ) )
                {
                    RATSwitchKind = 1;
                }
                
                _RATSwitchKind = RATSwitchKind;
                [DataRates release];
            }
            
            if(status)
            {
                if ( [status objectForKey:@"kCTRegistrationDataIndicatorOverride"] )
                {
                    _4GOverride = 1;
                }
                else {
                    _4GOverride = 0;
                }
                
            }
            int (*CTCellularDataPlanGetIsEnabled)();
            *(void **)(&CTCellularDataPlanGetIsEnabled) = (void *)dlsym(handle,"CTCellularDataPlanGetIsEnabled");
            _CellularDataPlanGetIsEnabled = CTCellularDataPlanGetIsEnabled();
        }
        dlclose(handle);
        [ratStateLock lock];
        if (ratState != nil) {
            [ratState release];
        }
        ratState = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_RATSwitchKind],@"RATSwitchKind",[NSNumber numberWithInt:_4GOverride],@"4GOverride",[NSNumber numberWithInt:_CellularDataPlanGetIsEnabled],@"CellularDataPlanGetIsEnabled", nil] retain];
        [ratStateLock unlock];
    }
    return ratState;
}

-(NSString *)_RATModeString
{
    NSString* RATMode = @"LTE"; 
    NSDictionary *ratState = [self _getRATState:nil];
    int RATSwitchKind = [[ratState objectForKey:@"RATSwitchKind"] intValue]; 
    if ( RATSwitchKind != 2 )
    {
        RATMode = @"3G";
        
        if(RATSwitchKind == 1 )
        {
            RATMode = @"3G";
            if ( [[ratState objectForKey:@"4GOverride"] intValue] )
                RATMode = @"4G";
        }
    }
    return  RATMode;
}

-(void)viewWillDisappear:(BOOL)animated{
    [self save];
}

@end

// vim:ft=objc

