//
//  main.m
//  promise-objc
//
//  Created by 陈小黑 on 05/11/2016.
//  Copyright © 2016 neevek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Promise.h"

NSError *makeError(NSString *domain) {
    return [NSError errorWithDomain:domain code:0 userInfo:nil];
}

void test0() {
    [[[[[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        NSLog(@"P1: %@", dispatch_get_main_queue());
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            reject(@"P1");
        });
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return [NSString stringWithFormat:@"%@-2", result];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return [NSString stringWithFormat:@"%@-3", result];
    }] catch:^id(id result) {
        NSLog(@"result: %@", result);
        return [NSString stringWithFormat:@"%@-4", result];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return [NSString stringWithFormat:@"%@-5", result];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return result;
    }];
}

void test1() {
    [[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P1");
        });
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-2", result];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return result;
    }];
}

void test2() {
    [[[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            reject(makeError(@"P1-ERROR"));
        });
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-2", result];
    }] catch:^id(NSError *error) {
        return [NSString stringWithFormat:@"%@-AFTER_ERROR", error];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return result;
    }];
}

void test3() {
    Promise *p1 = [[[[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P1");
        });
        
//        @throw [NSError exceptionWithName:@"P1-ERROR" reason:nil userInfo:nil];
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-2", result];
    }] then:^id(id result) {
        return [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-Inner1", result]);
            });
        }];
    }] then:^id(id result) {
        return [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-Inner2", result]);
            });
        }];
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-3", result];
    }];
    
    Promise *p2 = [Promise resolveWithObject:p1];
    [p2 then:^id(id result) {
        NSLog(@"%@-P2", result);
        return nil;
    }];
    
//    NSLog(@"%@, %@", p1, p2);
}

void test4() {
    Promise *p1 = [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P1");
        });
    }];
    
    [[[[Promise resolveWithObject:p1] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-P2", result];
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-1", result];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return nil;
    }];
}

void test5() {
    Promise *p1 = [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P1");
        });
    }];
    
    Promise *p2 = [[Promise resolveWithObject:p1] then:^id(id result) {
        return [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-Inner1", result]);
            });
        }];
    }];
    
    [[p2 then:^id(id result) {
        return [NSString stringWithFormat:@"%@-HAHA", result];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return nil;
    }];
}

void test6() {
    Promise *p1 = [[Promise resolveWithObject:@"P1"] then:^id(id result) {
        return [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-Inner1", result]);
            });
        }];
    }];
    
    [[p1 then:^id(id result) {
        return [NSString stringWithFormat:@"%@-HAHA", result];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return nil;
    }];
}

void test7() {
    Promise *p0 = [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P0");
        });
    }];
    
    Promise *p1 = [[Promise resolveWithObject:@"P1"] then:^id(id result) {
        return [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                resolve([NSString stringWithFormat:@"%@-Inner1", result]);
                reject(makeError([NSString stringWithFormat:@"%@-ERROR", result]));
            });
        }];
    }];
    
    Promise *p2 = [[Promise resolveWithObject:@"P2"] then:^id(id result) {
        return [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-Inner2", result]);
            });
        }];
    }];
    
    Promise *p3 = [Promise all:@[ p0, p1, @"LITERAL_STRING", p2]];
    
    [[p3 then:^id(id result) {
        NSArray *arr = (NSArray *)result;
        return [NSString stringWithFormat:@"%@, %@", arr, arr[0]];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return nil;
    }];
}

void test8() {
    Promise *p0 = [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P0");
        });
    }];
    
    Promise *p1 = [[Promise resolveWithObject:@"P1"] then:^id(id result) {
        return [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                resolve([NSString stringWithFormat:@"%@-Inner1", result]);
                Promise *p = [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                        resolve([NSString stringWithFormat:@"%@-Q1", result]);
//                          reject(makeError([NSString stringWithFormat:@"%@-ERR", result]));
                               reject([NSString stringWithFormat:@"new error: %@-ERR", result]);
                    });
                }];
                [p then:^id(id result) {
                    Promise *p2 = [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                               dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            resolve([NSString stringWithFormat:@"%@-Q2", result]);
                        });
                    }];
                    resolve(p2);
                    return result;
                } onRejected:^id(NSError *error) {
                    resolve([NSString stringWithFormat:@"%@-RECOVER", error]);
                    return @"RECOVER";
                }];
            });
        }];
    }];
    
    [p1 then:^id(id result) {
        Promise *p11 = [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-Q3", result]);
            });
        }];
        return p11;
    }];
    
    Promise *p2 = [[Promise resolveWithObject:@"P2"] then:^id(id result) {
        return [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-Inner2", result]);
            });
        }];
    }];
    
    Promise *p3 = [Promise all:@[ p0, p1, @"LITERAL_STRING", p2]];
    
    [[p3 then:^id(id result) {
        NSArray *arr = (NSArray *)result;
        return [NSString stringWithFormat:@"%@, %@", arr, arr[0]];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return result;
    }];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        test0();
//        for (int i = 0; i < 1000; ++i) {
//            test8();
//        }
    }
    sleep(4);
    return 0;
}
