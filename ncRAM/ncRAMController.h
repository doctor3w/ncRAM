//
//  ncRAMController.h
//  ncRAM
//
//  Created by Drew Dunne on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SpringBoard/BBWeeAppController.h"

@interface ncRAMController : NSObject <BBWeeAppController>
{
    UIView *_view;
    UIImageView *bgView;
    UILabel *lbl;
    NSTimer *refreshTimer;
    NSString *prefPath;
    
    int numberOfProcesses;
    NSMutableArray *processList;
}

- (UIView *)view;
- (void)refresh;
- (IBAction)freeMem:(id)sender;

- (int)numberOfProcesses;
- (void)obtainFreshProcessList;
- (BOOL)findProcessWithName:(NSString *)procNameToSearch;

@end