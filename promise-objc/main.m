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
    [[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        NSLog(@"P1 run");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);
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


Promise *p() {
    return [[Promise alloc] init];
}

void test3() {
    Promise *p1 = [Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
        NSLog(@"P1 run");
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            sleep(1);
//            resolve(@"P1");
//        });
        
        @throw [NSException exceptionWithName:@"P1-ERROR" reason:nil userInfo:nil];
    }];
    
//    [p1 then:^id(id result) {
//        NSLog(@"then called: %@", result);
//        return nil;
//    }];
    
//    Promise *p1 = [[[Promise promiseWithBlock:^(ResolveBlock resolve, RejectBlock reject) {
//        NSLog(@"P1 run");
////        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
////            sleep(1);
////            resolve(@"P1");
////        });
//        
//                    @throw [NSException exceptionWithName:@"P1-ERROR" reason:nil userInfo:nil];
//    }] then:^id(id result) {
//        NSLog(@"%@-2", result);
//        return [NSString stringWithFormat:@"%@-2", result];
//    }] then:^id(id result) {
//        NSLog(@"%@-3", result);
//        return [NSString stringWithFormat:@"%@-3", result];
//    }];
    
//    Promise *p2 = [Promise resolveWithObject:p1];
//    [p2 then:^id(id result) {
//        NSLog(@"%@-P2", result);
//        return [NSString stringWithFormat:@"%@-1", result];
//    }];
//    
//    NSLog(@"%@, %@", p1, p2);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
//        test1();
//        test2();
        test3();
    }
    sleep(3);
    return 0;
}
