//
//  ncRAMController.m
//  ncRAM
//
//  Created by Drew Dunne on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ncRAMController.h"
/*#import <SpringBoard/SpringBoard-Class.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SBAppSwitcherController.h>
#import <SpringBoard/SBAppSwitcherModel.h>
#import <SpringBoard/SBAppSwitcherBarView.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBNowPlayingBar.h>
#import <SpringBoard/SBIconView.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBApplicationIcon.h>*/
#include <stdio.h>
#include <string.h>

#include <mach/mach_host.h>
#include <malloc/malloc.h>

#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <sys/sysctl.h>

typedef struct kinfo_proc kinfo_proc;

@implementation ncRAMController

-(id)init
{
	if ((self = [super init]))
	{
        prefPath = [@"/var/mobile/Library/Preferences/com.alldunneinc.ncram.plist" retain];
        NSString *prefOrig = @"/System/Library/WeeAppPlugins/ncRAM.bundle/com.alldunneinc.ncram.plist";
        if ([[NSFileManager defaultManager] fileExistsAtPath:prefPath]) {
            
        } else {
            [[NSFileManager defaultManager] copyItemAtPath:prefOrig toPath:prefPath error:nil];
        }
        numberOfProcesses = -1; // means "not initialized"
        processList = NULL;
	}

	return self;
}

-(void)dealloc
{
    [prefPath release];
    [refreshTimer invalidate];
    [bgView release];
    [lbl release];
	[_view release];
	[super dealloc];
}

- (UIView *)view
{
	if (_view == nil)
	{
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefPath];
        float height  = [[prefs valueForKey:@"widgetHeight"] floatValue];
		_view = [[UIView alloc] initWithFrame:CGRectMake(2, 0, 316, height)];
	}

	return _view;
}

- (void)loadFullView {
    BOOL doesContain = [_view.subviews containsObject:lbl];
    if (doesContain==YES) {
        [lbl removeFromSuperview];
    } else {
        
    }
    BOOL doesHaveBG = [_view.subviews containsObject:bgView];
    if (doesHaveBG==YES) {
        [bgView removeFromSuperview];
    } else {
        
    }
    
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefPath];
    
    size_t length;
	int mib[6];	
	int result;
    
	printf("Memory Info\n");
	printf("-----------\n");
    
	int pagesize;
	mib[0] = CTL_HW;
	mib[1] = HW_PAGESIZE;
	length = sizeof(pagesize);
	if (sysctl(mib, 2, &pagesize, &length, NULL, 0) < 0)
	{
		perror("getting page size");
	}
	printf("Page size = %d bytes\n", pagesize);
	printf("\n");
    
	mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
	
	vm_statistics_data_t vmstat;
	if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmstat, &count) != KERN_SUCCESS)
	{
		printf("Failed to get VM statistics.");
	}
	
	//double total = vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count;
	//double wired = vmstat.wire_count / total;
	//double active = vmstat.active_count / total;
	//double inactive = vmstat.inactive_count / total;
	//double free = vmstat.free_count / total;
    
	/*printf("Total =    %8d pages\n", vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count);
	printf("\n");
	printf("Wired =    %8d bytes\n", vmstat.wire_count * pagesize);
	printf("Active =   %8d bytes\n", vmstat.active_count * pagesize);
	printf("Inactive = %8d bytes\n", vmstat.inactive_count * pagesize);
	printf("Free =     %8d bytes\n", vmstat.free_count * pagesize);
	printf("\n");
	printf("Total =    %8d bytes\n", (vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count) * pagesize);
	printf("\n");
	printf("Wired =    %0.2f %%\n", wired * 100.0);
	printf("Active =   %0.2f %%\n", active * 100.0);
	printf("Inactive = %0.2f %%\n", inactive * 100.0);
	printf("Free =     %0.2f %%\n", free * 100.0);
	printf("\n");*/
    
	mib[0] = CTL_HW;
	mib[1] = HW_PHYSMEM;
	length = sizeof(result);
	if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
	{
		perror("getting physical memory");
	}
	printf("Physical memory = %8d bytes\n", result);
	mib[0] = CTL_HW;
	mib[1] = HW_USERMEM;
	length = sizeof(result);
	if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
	{
		perror("getting user memory");
	}
	printf("User memory =     %8d bytes\n", result);
	printf("\n");
    float bytesFree = (vmstat.inactive_count * pagesize)+(vmstat.free_count * pagesize);
    float availableMem = ((((bytesFree*8)/1024)/1024)/8);
    //float percentFree = ((bytesFree/total)*100);
    NSString *availableMemString;
    //NSString *percent = [NSString stringWithFormat:@"%.01f",percentFree];
    if ([[prefs valueForKey:@"displayText"] isEqualToString:@""]) {
        availableMemString = [NSString stringWithFormat:@"%.03f MB",availableMem];
    } else {
        NSString *displayText = [prefs valueForKey:@"displayText"];
        availableMemString = [NSString stringWithFormat:@"%@ %.03f MB",displayText,availableMem];
    }
    
    float height = [[prefs valueForKey:@"widgetHeight"] floatValue];
    
    float size = [[prefs valueForKey:@"size"] floatValue];
    
    float red = [[prefs valueForKey:@"red"] floatValue];
    float green = [[prefs valueForKey:@"green"] floatValue];
    float blue = [[prefs valueForKey:@"blue"] floatValue];
    
    UIImage *bg = [[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/ncRAM.bundle/WeeAppBackground.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:71];
    bgView = [[UIImageView alloc] initWithImage:bg];
    bgView.frame = CGRectMake(0, 0, 316, height);
    [_view addSubview:bgView];
    
    lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 316, height)];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor colorWithRed:red/255 green:green/255 blue:blue/255 alpha:1];
    lbl.font = [UIFont systemFontOfSize:size];
    lbl.text = availableMemString;
    lbl.textAlignment = UITextAlignmentCenter;
    [_view addSubview:lbl];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 316, height)];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(freeMem:) forControlEvents:UIControlEventTouchDown];
    
    if ([[prefs valueForKey:@"refresh"] boolValue]==YES) {
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    } else {
        
    }
}

- (void)unloadView {
    BOOL doesContain = [_view.subviews containsObject:lbl];
    if (doesContain==YES) {
        [lbl removeFromSuperview];
    } else {
        
    }
    BOOL doesHaveBG = [_view.subviews containsObject:bgView];
    if (doesHaveBG==YES) {
        [bgView removeFromSuperview];
    } else {
        
    }
}

- (IBAction)freeMem:(id)sender {
    [self obtainFreshProcessList];
    for (int i = 0; i < [processList count]; i++) {
        NSString *processToKill = [processList objectAtIndex:i];
        processList = malloc(sizeof(processToKill));
        free(processToKill);
    }
    
    //malloc();
    //free();
}

/*- (IBAction)killAll:(id)sender {
    SBAppSwitcherModel *switcher = [[SBAppSwitcherModel alloc] init];
    NSString *appToRemove = [NSString stringWithFormat:@"%d",[switcher count]-1];
    [switcher remove:appToRemove];
}

- (IBAction)respring:(id)sender {
    [self killBackgroundAppsFromSwitcher:(SBAppSwitcherController *)self];
}*/

- (void)refresh {
    [self unloadView];
    [self loadFullView];
}

- (float)viewHeight
{
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefPath];
    float height = [[prefs valueForKey:@"widgetHeight"] floatValue];
	return height;
}

- (int)numberOfProcesses
{
    return numberOfProcesses;
}

- (void)setNumberOfProcesses:(int)num
{
    numberOfProcesses = num;
}

- (int)getBSDProcessList:(kinfo_proc **)procList
   withNumberOfProcesses:(size_t *)procCount
{
    int             err;
    kinfo_proc *    result;
    bool            done;
    static const int    name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    size_t          length;
    
    // a valid pointer procList holder should be passed
    assert( procList != NULL );
    // But it should not be pre-allocated
    assert( *procList == NULL );
    // a valid pointer to procCount should be passed
    assert( procCount != NULL );
    
    *procCount = 0;
    
    result = NULL;
    done = false;
    
    do
    {
        assert( result == NULL );
        
        // Call sysctl with a NULL buffer to get proper length
        length = 0;
        err = sysctl((int *)name,(sizeof(name)/sizeof(*name))-1,NULL,&length,NULL,0);
        if( err == -1 )
            err = errno;
        
        // Now, proper length is optained
        if( err == 0 )
        {
            result = malloc(length);
            if( result == NULL )
                err = ENOMEM;   // not allocated
        }
        
        if( err == 0 )
        {
            err = sysctl( (int *)name, (sizeof(name)/sizeof(*name))-1, result, &length, NULL, 0);
            if( err == -1 )
                err = errno;
            
            if( err == 0 )
                done = true;
            else if( err == ENOMEM )
            {
                assert( result != NULL );
                free( result );
                result = NULL;
                err = 0;
            }
        }
    }while ( err == 0 && !done );
    
    // Clean up and establish post condition
    if( err != 0 && result != NULL )
    {
        free(result);
        result = NULL;
    }
    
    *procList = result; // will return the result as procList
    if( err == 0 )
        *procCount = length / sizeof( kinfo_proc );
    
    assert( (err == 0) == (*procList != NULL ) );
    
    return err;
}

- (void)obtainFreshProcessList
{
    int i;
    kinfo_proc *allProcs = 0;
    size_t numProcs;
    NSString *procName;
    
    int err =  [self getBSDProcessList:&allProcs withNumberOfProcesses:&numProcs];
    if( err )
    {
        numberOfProcesses = -1;
        processList = NULL;
        
        return;
    }
    
    // Construct an array for ( process name )
    processList = [NSMutableArray arrayWithCapacity:numProcs];
    for( i = 0; i < numProcs; i++ )
    {
        procName = [NSString stringWithFormat:@"%s", allProcs[i].kp_proc.p_comm];
        [processList addObject:procName];
    }
    
    [self setNumberOfProcesses:numProcs];
    
    //[processListView setText:[processList componentsJoinedByString:@", "]];
    
    // NSLog(@"# of elements = %d total # of process = %d\n",
    //         [processArray count], numProcs );
    
    free( allProcs );
    
}

- (BOOL)findProcessWithName:(NSString *)procNameToSearch
{
    int index;
    
    index = [processList indexOfObject:procNameToSearch];
    
    if( index == NSNotFound )
        return NO;
    else
        return YES;
}

@end