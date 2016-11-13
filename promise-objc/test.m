//
//  test.m
//  promise-objc
//
//  Created by 陈小黑 on 12/11/2016.
//  Copyright © 2016 neevek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdatomic.h>
#import "Promise.h"


#define Assert(case, equality, format, expect, actual) \
do {\
    if (equality) {\
        fprintf(stderr, case ": OK\n");\
    } else {\
        fprintf(stderr, case "%s:%d: expect: " format " actual: " format "\n", __FILE__, __LINE__, expect, actual);\
    }\
} while(0)

#define AssertNSStringEqual(case, expect, actual)\
    Assert(case, [actual isEqualToString:expect], "%s", [expect UTF8String], [actual UTF8String])

#define AssertIntegerEqual(case, expect, actual)\
    Assert(case, expect == actual, "%zd", expect, actual)


atomic_int gTestCount;

void testcase0() {
    [[[[[[Promise promiseWithResolver:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P1");
        });
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-2", result];
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-3", result];
    }] catch:^id(id result) {
        // this will not run
        return [NSString stringWithFormat:@"%@-ERROR", result];
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-5", result];
    }] then:^id(id result) {
        AssertNSStringEqual("case0", @"P1-2-3-5", result);
        ++gTestCount;
        return result;
    }];
}

void testcase1() {
    [[[[[[Promise promiseWithResolver:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            reject(@"P1");
        });
    }] then:^id(id result) {
        // this will not run
        return [NSString stringWithFormat:@"%@-2", result];
    }] then:^id(id result) {
        // this will not run
        return [NSString stringWithFormat:@"%@-3", result];
    }] catch:^id(id result) {
        return [NSString stringWithFormat:@"%@-ERROR", result];
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-5", result];
    }] then:^id(id result) {
        AssertNSStringEqual("case1", @"P1-ERROR-5", result);
        ++gTestCount;
        return result;
    }];
}

void testcase2() {
    [[[[[[Promise promiseWithResolver:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P1");
        });
    }] then:^id(id result) {
        return [NSError errorWithDomain:[NSString stringWithFormat:@"%@-ERR", result] code:0 userInfo:nil];
    }] then:^id(id result) {
        // this will not run
        return [NSString stringWithFormat:@"%@-3", result];
    }] catch:^id(id result) {
        // result could be any object, but here we know it is an NSError*
        NSError *error = (NSError *)result;
        return [NSString stringWithFormat:@"%@-CAUGHT", error.domain];
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-5", result];
    }] then:^id(id result) {
        AssertNSStringEqual("case2", @"P1-ERR-CAUGHT-5", result);
        ++gTestCount;
        return result;
    }];
}

void testcase3() {
    Promise *p0 = [Promise promiseWithResolver:^(ResolveBlock resolve, RejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            resolve(@"P0");
        });
    }];
    
    Promise *p1 = [[[[[Promise resolveWithObject:@"P1"] then:^id(id result) {
        return [Promise promiseWithResolver:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-P2", result]);
            });
        }];
    }] then:^id(id result) {
        return [Promise promiseWithResolver:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-P3", result]);
            });
        }];
    }] then:^id(id result) {
        return [NSString stringWithFormat:@"%@-DirectReturn", result];
    }] then:^id(id result) {
        return [Promise promiseWithResolver:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-P4", result]);
            });
        }];
    }];
    
    Promise *p4 = [[Promise resolveWithObject:p1] then:^id(id result) {
        return [Promise promiseWithResolver:^(ResolveBlock resolve, RejectBlock reject) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolve([NSString stringWithFormat:@"%@-P5", result]);
            });
        }];
    }];
    
    [[Promise all:@[ p0, p4, @"literal_str" ]] then:^id(id result) {
        NSArray *resultArr = (NSArray *)result;
        AssertNSStringEqual("case3-0", @"P0", resultArr[0]);
        AssertNSStringEqual("case3-1", @"P1-P2-P3-DirectReturn-P4-P5", resultArr[1]);
        AssertNSStringEqual("case3-2", @"literal_str", resultArr[2]);
        ++gTestCount;
        return result;
    }];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"Start running tests...");
        testcase0();
        testcase1();
        testcase2();
        testcase3();
        
        const int waitTime = 10;
        NSLog(@"wait for %d seconds before running the last testcase...", waitTime);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            AssertIntegerEqual("last testcase", 4, gTestCount);
        });
    }
    
    sleep(11);
    return 0;
}
