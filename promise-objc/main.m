//
//  main.m
//  promise-objc
//
//  Created by 陈小黑 on 05/11/2016.
//  Copyright © 2016 neevek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Promise.h"

void test0() {
    Promise *p0 = [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject){
        NSLog(@"p0");
        [[Promise resolveWithObject:@"inner1"] then:^id(id result) {
            NSLog(@"inner: %@", result);
            return nil;
        }];
        [[Promise resolveWithObject:@"inner2"] then:^id(id result) {
            NSLog(@"inner: %@", result);
            return nil;
        }];
        [[Promise resolveWithObject:@"inner3"] then:^id(id result) {
            NSLog(@"inner: %@", result);
            return nil;
        }];
        resolve(@"p0");
    }];
    
    Promise *p1 = [[Promise resolveWithObject:p0] then:^id(id result) {
        NSLog(@">>>> %@-p1-1", result);
        return [NSString stringWithFormat:@"%@-p1-1", result];
    }];
    
    sleep(1);
    
    [[p1 then:^id(id result) {
        NSLog(@">>>> %@-2", result);
        return [NSString stringWithFormat:@"%@-2", result];
    }] then:^id(id result) {
        NSLog(@">>>> %@-3", result);
        return [NSString stringWithFormat:@"%@-3", result];
    }];
}

//void test1() {
//    Promise *p = [Promise promiseWithBlock:^id(){
//        return [[[[[[Promise promiseWithBlock:^id(){
//            return @"A0";
//        }] then:^id(id result) {
//            return [NSString stringWithFormat:@"%@-A1", result];
//        }] then:^id(id result) {
//            return [[[Promise promiseWithBlock:^id(){
//                return [NSString stringWithFormat:@"%@-B1", result];
//            }] then:^id(id result) {
//                return [[[Promise promiseWithBlock:^id(){
//                    return [NSString stringWithFormat:@"%@-C1", result];
//                }] then:^id(id result) {
//                    return [NSString stringWithFormat:@"%@-C2", result];
//                }] then:^id(id result) {
//                    return [NSString stringWithFormat:@"%@-C3", result];
//                }];
//            }] then:^id(id result) {
//                return [NSString stringWithFormat:@"%@-B2", result];
//            }];
//            
//        }] then:^id(id result) {
//            return [NSString stringWithFormat:@"%@-A2", result];
//        }] then:^id(id result) {
//            return [NSString stringWithFormat:@"%@-A3", result];
//        }] then:^id(id result) {
//            return [NSString stringWithFormat:@"%@-A4", result];
//        }];
//    }];
//    
//    
//    [[p then:^id(id result) {
//        return [NSString stringWithFormat:@"%@-A1", result];
//    }] then:^id(id result) {
//        NSLog(@"%@-DONE", result);
//        NSLog(@"-------------------------------------------%s", __FUNCTION__);
//        return nil;
//    }];
//}
//
//void test2() {
//    Promise *p = [[Promise resolveWithObject:@"A0"] then:^id(id result) {
//        return [[[[[[Promise promiseWithBlock:^id(){
//            return [NSString stringWithFormat:@"%@-B0", result];
//        }] then:^id(id result) {
//            return [NSString stringWithFormat:@"%@-B1", result];
//        }] then:^id(id result) {
//            return [[[Promise promiseWithBlock:^id(){
//                return [NSString stringWithFormat:@"%@-C1", result];
//            }] then:^id(id result) {
//                return [[[Promise promiseWithBlock:^id(){
//                    return [NSString stringWithFormat:@"%@-D1", result];
//                }] then:^id(id result) {
//                    return [NSString stringWithFormat:@"%@-D2", result];
//                }] then:^id(id result) {
//                    return [NSString stringWithFormat:@"%@-D3", result];
//                }];
//            }] then:^id(id result) {
//                return [NSString stringWithFormat:@"%@-C2", result];
//            }];
//            
//        }] then:^id(id result) {
//            return [NSString stringWithFormat:@"%@-B2", result];
//        }] then:^id(id result) {
//            return [NSString stringWithFormat:@"%@-B3", result];
//        }] then:^id(id result) {
//            return [NSString stringWithFormat:@"%@-B4", result];
//        }];
//        
//    }];
//    
//    [[p then:^id(id result) {
//        return [NSString stringWithFormat:@"%@-A1", result];
//    }] then:^id(id result) {
//        NSLog(@"%@-DONE", result);
//        NSLog(@"-------------------------------------------%s", __FUNCTION__);
//        return nil;
//    }];
//}
//
//void test3() {
//    Promise *p = [[Promise resolveWithObject:@"A0"] then:^id(id result) {
//        NSLog(@"A0 run");
//        return [[[[[[[Promise promiseWithBlock:^id(){
//            NSLog(@"B0 run");
//            return [NSString stringWithFormat:@"%@-B0", result];
//        }] then:^id(id result) {
//            NSLog(@"B1 run");
//            return [NSString stringWithFormat:@"%@-B1", result];
//        }] then:^id(id result) {
//            return [[[Promise promiseWithBlock:^id(){
//                NSLog(@"C1 run");
//                return [NSString stringWithFormat:@"%@-C1", result];
//            }] then:^id(id result) {
//                return [[[Promise promiseWithBlock:^id(){
//                    NSLog(@"D1 run");
//                    return [NSString stringWithFormat:@"%@-D1", result];
//                }] then:^id(id result) {
//                    NSLog(@"Except run");
////                    return [NSException exceptionWithName:@"D_ERROR1" reason:nil userInfo:nil];
//                    @throw [NSException exceptionWithName:@"D_ERROR1" reason:nil userInfo:nil];
//                }] then:^id(id result) {
//                    NSLog(@"D3 run");
//                    return [NSString stringWithFormat:@"%@-D3", result];
//                }];
//            }] then:^id(id result) {
//                NSLog(@"C2 run");
//                return [NSString stringWithFormat:@"%@-C2", result];
//            }];
//            
//        }] then:^id(id result) {
//            NSLog(@"B2 run");
//            return [NSString stringWithFormat:@"%@-B2", result];
//        }] then:^id(id result) {
//            NSLog(@"B3 run");
//            return [NSString stringWithFormat:@"%@-B3", result];
//        }] catch:^id(NSException *error) {
//            NSLog(@"caught exception: %@", error);
//            @throw error;
//            return nil;
//        }] then:^id(id result) {
//            NSLog(@"B4 run");
//            return [NSString stringWithFormat:@"%@-B4", result];
//        }];
//        
//    }];
//    
//    [[[p then:^id(id result) {
//        NSLog(@"A1 run");
//        return [NSString stringWithFormat:@"%@-A1", result];
//    }] then:^id(id result) {
//        NSLog(@"%@-DONE ------ %s", result, __FUNCTION__);
//        return nil;
//    }] catch:^id(NSException *error) {
//        NSLog(@"FAIL-%@ ------ %s", error, __FUNCTION__);
//        return nil;
//    }];
//}
//
//void test4() {
//    Promise *p = [[Promise promiseWithBlock:^id{
//        @throw [NSException exceptionWithName:@"A_ERROR" reason:nil userInfo:nil];
//    }] then:^id(id result) {
//        NSLog(@"A0 run");
//        return [[[[[[[Promise promiseWithBlock:^id(){
//            NSLog(@"B0 run");
//            return [NSString stringWithFormat:@"%@-B0", result];
//        }] then:^id(id result) {
//            NSLog(@"B1 run");
//            return [NSString stringWithFormat:@"%@-B1", result];
//        }] then:^id(id result) {
//            return [[[Promise promiseWithBlock:^id(){
//                NSLog(@"C1 run");
//                return [NSString stringWithFormat:@"%@-C1", result];
//            }] then:^id(id result) {
//                return [[[Promise promiseWithBlock:^id(){
//                    NSLog(@"D1 run");
//                    return [NSString stringWithFormat:@"%@-D1", result];
//                }] then:^id(id result) {
//                    NSLog(@"Except run");
////                    return [NSException exceptionWithName:@"D_ERROR" reason:nil userInfo:nil];
//                    @throw [NSException exceptionWithName:@"D_ERROR" reason:nil userInfo:nil];
//                }] then:^id(id result) {
//                    NSLog(@"D3 run");
//                    return [NSString stringWithFormat:@"%@-D3", result];
//                }];
//            }] then:^id(id result) {
//                NSLog(@"C2 run");
//                return [NSString stringWithFormat:@"%@-C2", result];
//            }];
//            
//        }] then:^id(id result) {
//            NSLog(@"B2 run");
//            return [NSString stringWithFormat:@"%@-B2", result];
//        }] then:^id(id result) {
//            NSLog(@"B3 run");
//            return [NSString stringWithFormat:@"%@-B3", result];
//        }] catch:^id(NSException *error) {
//            NSLog(@"caught exception: %@", error);
//            return nil;
//        }] then:^id(id result) {
//            NSLog(@"B4 run");
//            return [NSString stringWithFormat:@"%@-B4", result];
//        }];
//        
//    }];
//    
//    [[p then:^id(id result) {
//        NSLog(@"A1 run");
//        return [NSString stringWithFormat:@"%@-A1", result];
//    }] then:^id(id result) {
//        NSLog(@"%@-DONE", result);
//        return nil;
//    } onRejected:^id(NSException *error){
//        NSLog(@"LAST_CAUGHT: %@", error);
//        NSLog(@"-------------------------------------------%s", __FUNCTION__);
//        return nil;
//    }];
//}


void test11() {
    Promise *p = [[[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        NSLog(@">>>>>>>>>>>>>>>>>>>>> A0 run");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);
            resolve(@"A0");
        });
    }] then:^id(id result) {
        NSLog(@">>>>>>>>>>>>>>>>>>>>> A1 run");
        return [NSString stringWithFormat:@"%@-A1", result];
    }] then:^id(id result) {
//        NSLog(@">>>>>>>>>>>>>>>>>>>>> A2 run");
//        return [NSString stringWithFormat:@"%@-A2", result];
        return [[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            NSLog(@">>>>>>>>>>>>>>>>>>>>> B0 run");
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                sleep(1);
                resolve([NSString stringWithFormat:@"%@-B0", result]);
            });
        }] then:^id(id result) {
            NSLog(@">>>>>>>>>>>>>>>>>>>>> B1 run");
            return [NSString stringWithFormat:@"%@-B1", result];
        }] then:^id(id result) {
            NSLog(@">>>>>>>>>>>>>>>>>>>>> B2 run");
            return [NSString stringWithFormat:@"%@-B2", result];
        }];
    }] then:^id(id result) {
        NSLog(@">>>>>>>>>>>>>>>>>>>>> A3 run");
        NSLog(@"%@-A3", result);
        return nil;
    }];
}

void test12() {
    [[[[[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        NSLog(@">>>>>>>>>>>>>>>>>>>>> A0 run");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);
            resolve(@"A0");
        });
    }] then:^id(id result) {
        NSLog(@">>>>>>>>>>>>>>>>>>>>> A1 run");
//        return [NSString stringWithFormat:@"%@-A1", result];
        @throw [NSException exceptionWithName:@"A1_ERROR" reason:nil userInfo:nil];
    }] then:^id(id result) {
        NSLog(@">>>>>>>>>>>>>>>>>>>>> A2 run");
        return [NSString stringWithFormat:@"%@-A2", result];
    }] catch:^id(NSException *error) {
        NSLog(@">>>>>>>>>>>>>>>>>>>>> caught error: %@", error);
        return @"CAUGHT_ERROR";
    }] then:^id(id result) {
//        NSLog(@">>>>>>>>>>>>>>>>>>>>> A2 run");
//        return [NSString stringWithFormat:@"%@-A2", result];
        return [[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            NSLog(@">>>>>>>>>>>>>>>>>>>>> B0 run");
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                sleep(1);
                resolve([NSString stringWithFormat:@"%@-B0", result]);
            });
        }] then:^id(id result) {
            NSLog(@">>>>>>>>>>>>>>>>>>>>> B1 run");
            return [NSString stringWithFormat:@"%@-B1", result];
        }] then:^id(id result) {
            NSLog(@">>>>>>>>>>>>>>>>>>>>> B2 run");
            return [NSString stringWithFormat:@"%@-B2", result];
        }];
    }] then:^id(id result) {
        NSLog(@">>>>>>>>>>>>>>>>>>>>> A3 run");
        NSLog(@"%@-A3", result);
        return nil;
    }];
}

void test13() {
    Promise *p0 = [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject){
        NSLog(@"run p0");
        resolve(@"p0");
    }];
    
//    sleep(1);
    
    Promise *p1 = [Promise resolveWithObject:p0];
    
    [p1 then:^id(id result) {
        NSLog(@"run p1");
        NSLog(@"p1-%@, %s", result, __FUNCTION__);
        return nil;
    }];
    
//    [p1 then:^id(id result) {
//        NSLog(@"p1-DONE,%@, %s", result, __FUNCTION__);
//        return nil;
//    }];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        test0();
//        test1();
//        test2();
//        test3();
//        test4();
        
//        test11();
//        test12();
//        test13();
        sleep(5);
    }
    return 0;
}
