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
    [[[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        resolve(@"P1");
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-2", result];
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-3", result];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return nil;
    }];
}

void test1() {
    [[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        NSLog(@"P1 run");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P1");
        });
    }] then:^id(id result) {
        NSLog(@"%@-2", result);
        return [NSString stringWithFormat:@"%@-2", result];
    }] then:^id(id result) {
        NSLog(@"%@-3", result);
        return [NSString stringWithFormat:@"%@-3", result];
    }];
}

void test2() {
    [[[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        NSLog(@"P1 run");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            reject([NSException exceptionWithName:@"P1-ERROR" reason:nil userInfo:nil]);
        });
    }] then:^id(id result) {
        NSLog(@"%@-2", result);
        return [NSString stringWithFormat:@"%@-2", result];
    }] catch:^id(NSException *error) {
        NSLog(@"CAUGHT: %@", error);
        return @"AFTER_ERROR";
    }] then:^id(id result) {
        NSLog(@"%@-3", result);
        return [NSString stringWithFormat:@"%@-3", result];
    }];
}

void test3() {
    Promise *p1 = [[[[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        NSLog(@"P1 run");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P1");
        });
        
//        @throw [NSException exceptionWithName:@"P1-ERROR" reason:nil userInfo:nil];
    }] then:^id(id result) {
        NSLog(@"%@-2", result);
        return [NSString stringWithFormat:@"%@-2", result];
    }] then:^id(id result) {
        return [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            NSLog(@"Inner run");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-Inner1", result]);
            });
        }];
    }] then:^id(id result) {
        return [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
            NSLog(@"Inner2 run");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-Inner2", result]);
            });
        }];
    }] then:^id(id result) {
        NSLog(@"%@-3", result);
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
    
    sleep(2);
    
    [[p2 then:^id(id result) {
        return [NSString stringWithFormat:@"%@-HAHA", result];
    }] then:^id(id result) {
        NSLog(@"result: %@", result);
        return nil;
    }];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        test0();
    }
    sleep(10);
    return 0;
}
