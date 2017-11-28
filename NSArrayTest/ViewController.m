//
//  ViewController.m
//  NSArrayTest
//
//  Created by 蓝布鲁 on 2017/11/28.
//  Copyright © 2017年 蓝布鲁. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) NSArray *arrayI;
@property (nonatomic, strong) NSMutableArray *arrayM;
@property (nonatomic, strong) NSArray *array0;
@property (nonatomic, strong) NSArray *singleObjectArrayI;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*
     * init array
     */
    self.arrayI = @[@"a", @"b", @"c", @"d"];
    
    self.arrayM = [self.arrayI mutableCopy];
    
    self.array0 = @[];
    
    self.singleObjectArrayI = @[@"a"];
    
    
    /*
     * overflow !
     */
    NSLog(@"self.array[5]: %@",self.arrayI[4]);
    NSLog(@"[self.array objectAtIndex:4]: %@",[self.arrayI objectAtIndex:4]);
    
    NSLog(@"[self.mArray objectAtIndex:5]: %@",self.arrayM[5]);
    NSLog(@"[self.mArray objectAtIndex:5]: %@",[self.arrayM objectAtIndex:5]);
    
    NSLog(@"self.emptyArray[5]: %@",self.array0[4]);
    NSLog(@"[self.emptyArray objectAtIndex:4]: %@",[self.array0 objectAtIndex:4]);
    
    NSLog(@"self.signalArray[5]: %@",self.singleObjectArrayI[4]);
    NSLog(@"[self.signalArray objectAtIndex:4]: %@",[self.singleObjectArrayI objectAtIndex:4]);
}



@end
