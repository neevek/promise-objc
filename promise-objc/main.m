//
//  main.m
//  promise-objc
//
//  Created by 陈小黑 on 05/11/2016.
//  Copyright © 2016 neevek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Promise.h"

void test1() {
    Promise *p = [Promise promiseWithBlock:^id(){
        return [[[[[[Promise promiseWithBlock:^id(){
            return @"A0";
        }] then:^id(id result) {
            return [NSString stringWithFormat:@"%@-A1", result];
        }] then:^id(id result) {
            return [[[Promise promiseWithBlock:^id(){
                return [NSString stringWithFormat:@"%@-B1", result];
            }] then:^id(id result) {
                return [[[Promise promiseWithBlock:^id(){
                    return [NSString stringWithFormat:@"%@-C1", result];
                }] then:^id(id result) {
                    return [NSString stringWithFormat:@"%@-C2", result];
                }] then:^id(id result) {
                    return [NSString stringWithFormat:@"%@-C3", result];
                }];
            }] then:^id(id result) {
                return [NSString stringWithFormat:@"%@-B2", result];
            }];
            
        }] then:^id(id result) {
            return [NSString stringWithFormat:@"%@-A2", result];
        }] then:^id(id result) {
            return [NSString stringWithFormat:@"%@-A3", result];
        }] then:^id(id result) {
            return [NSString stringWithFormat:@"%@-A4", result];
        }];
    }];
    
    
    [[p then:^id(id result) {
        return [NSString stringWithFormat:@"%@-A1", result];
    }] then:^id(id result) {
        NSLog(@"%@-DONE", result);
        NSLog(@"-------------------------------------------%s", __FUNCTION__);
        return nil;
    }];
}

void test2() {
    Promise *p = [[Promise resolveWithObject:@"A0"] then:^id(id result) {
        return [[[[[[Promise promiseWithBlock:^id(){
            return [NSString stringWithFormat:@"%@-B0", result];
        }] then:^id(id result) {
            return [NSString stringWithFormat:@"%@-B1", result];
        }] then:^id(id result) {
            return [[[Promise promiseWithBlock:^id(){
                return [NSString stringWithFormat:@"%@-C1", result];
            }] then:^id(id result) {
                return [[[Promise promiseWithBlock:^id(){
                    return [NSString stringWithFormat:@"%@-D1", result];
                }] then:^id(id result) {
                    return [NSString stringWithFormat:@"%@-D2", result];
                }] then:^id(id result) {
                    return [NSString stringWithFormat:@"%@-D3", result];
                }];
            }] then:^id(id result) {
                return [NSString stringWithFormat:@"%@-C2", result];
            }];
            
        }] then:^id(id result) {
            return [NSString stringWithFormat:@"%@-B2", result];
        }] then:^id(id result) {
            return [NSString stringWithFormat:@"%@-B3", result];
        }] then:^id(id result) {
            return [NSString stringWithFormat:@"%@-B4", result];
        }];
        
    }];
    
    [[p then:^id(id result) {
        return [NSString stringWithFormat:@"%@-A1", result];
    }] then:^id(id result) {
        NSLog(@"%@-DONE", result);
        NSLog(@"-------------------------------------------%s", __FUNCTION__);
        return nil;
    }];
}

void test3() {
    Promise *p = [[Promise resolveWithObject:@"A0"] then:^id(id result) {
        NSLog(@"A0 run");
        return [[[[[[[Promise promiseWithBlock:^id(){
            NSLog(@"B0 run");
            return [NSString stringWithFormat:@"%@-B0", result];
        }] then:^id(id result) {
            NSLog(@"B1 run");
            return [NSString stringWithFormat:@"%@-B1", result];
        }] then:^id(id result) {
            return [[[Promise promiseWithBlock:^id(){
                NSLog(@"C1 run");
                return [NSString stringWithFormat:@"%@-C1", result];
            }] then:^id(id result) {
                return [[[Promise promiseWithBlock:^id(){
                    NSLog(@"D1 run");
                    return [NSString stringWithFormat:@"%@-D1", result];
                }] then:^id(id result) {
                    NSLog(@"Except run");
//                    return [NSException exceptionWithName:@"D_ERROR1" reason:nil userInfo:nil];
                    @throw [NSException exceptionWithName:@"D_ERROR1" reason:nil userInfo:nil];
                }] then:^id(id result) {
                    NSLog(@"D3 run");
                    return [NSString stringWithFormat:@"%@-D3", result];
                }];
            }] then:^id(id result) {
                NSLog(@"C2 run");
                return [NSString stringWithFormat:@"%@-C2", result];
            }];
            
        }] then:^id(id result) {
            NSLog(@"B2 run");
            return [NSString stringWithFormat:@"%@-B2", result];
        }] then:^id(id result) {
            NSLog(@"B3 run");
            return [NSString stringWithFormat:@"%@-B3", result];
        }] catch:^id(NSException *error) {
            NSLog(@"caught exception: %@", error);
            @throw error;
            return nil;
        }] then:^id(id result) {
            NSLog(@"B4 run");
            return [NSString stringWithFormat:@"%@-B4", result];
        }];
        
    }];
    
    [[[p then:^id(id result) {
        NSLog(@"A1 run");
        return [NSString stringWithFormat:@"%@-A1", result];
    }] then:^id(id result) {
        NSLog(@"%@-DONE ------ %s", result, __FUNCTION__);
        return nil;
    }] catch:^id(NSException *error) {
        NSLog(@"FAIL-%@ ------ %s", error, __FUNCTION__);
        return nil;
    }];
}

void test4() {
    Promise *p = [[Promise promiseWithBlock:^id{
        @throw [NSException exceptionWithName:@"A_ERROR" reason:nil userInfo:nil];
    }] then:^id(id result) {
        NSLog(@"A0 run");
        return [[[[[[[Promise promiseWithBlock:^id(){
            NSLog(@"B0 run");
            return [NSString stringWithFormat:@"%@-B0", result];
        }] then:^id(id result) {
            NSLog(@"B1 run");
            return [NSString stringWithFormat:@"%@-B1", result];
        }] then:^id(id result) {
            return [[[Promise promiseWithBlock:^id(){
                NSLog(@"C1 run");
                return [NSString stringWithFormat:@"%@-C1", result];
            }] then:^id(id result) {
                return [[[Promise promiseWithBlock:^id(){
                    NSLog(@"D1 run");
                    return [NSString stringWithFormat:@"%@-D1", result];
                }] then:^id(id result) {
                    NSLog(@"Except run");
//                    return [NSException exceptionWithName:@"D_ERROR" reason:nil userInfo:nil];
                    @throw [NSException exceptionWithName:@"D_ERROR" reason:nil userInfo:nil];
                }] then:^id(id result) {
                    NSLog(@"D3 run");
                    return [NSString stringWithFormat:@"%@-D3", result];
                }];
            }] then:^id(id result) {
                NSLog(@"C2 run");
                return [NSString stringWithFormat:@"%@-C2", result];
            }];
            
        }] then:^id(id result) {
            NSLog(@"B2 run");
            return [NSString stringWithFormat:@"%@-B2", result];
        }] then:^id(id result) {
            NSLog(@"B3 run");
            return [NSString stringWithFormat:@"%@-B3", result];
        }] catch:^id(NSException *error) {
            NSLog(@"caught exception: %@", error);
            return nil;
        }] then:^id(id result) {
            NSLog(@"B4 run");
            return [NSString stringWithFormat:@"%@-B4", result];
        }];
        
    }];
    
    [[p then:^id(id result) {
        NSLog(@"A1 run");
        return [NSString stringWithFormat:@"%@-A1", result];
    }] then:^id(id result) {
        NSLog(@"%@-DONE", result);
        return nil;
    } onRejected:^id(NSException *error){
        NSLog(@"LAST_CAUGHT: %@", error);
        NSLog(@"-------------------------------------------%s", __FUNCTION__);
        return nil;
    }];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        test1();
        test2();
//        test3();
//        test4();
        sleep(1);
    }
    return 0;
}
