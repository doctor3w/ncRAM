//

#import <Foundation/Foundation.h>

@interface JAProcessInfo : NSObject {
@private
    
    int numberOfProcesses;
    NSMutableArray *processList;
    
}
- (id) init;
- (int)numberOfProcesses;
- (void)obtainFreshProcessList;
- (BOOL)findProcessWithName:(NSString *)procNameToSearch;

@end
