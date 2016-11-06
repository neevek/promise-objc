//
//  Promise.m
//  promise-objc
//
//  Created by 陈小黑 on 05/11/2016.
//  Copyright © 2016 neevek. All rights reserved.
//

#import "Promise.h"

@interface Promise()
@property (strong, nonatomic) id result;
@end

@implementation Promise

+(instancetype)promiseWithBlock:(PromiseBlock)promiseBlock {
    return [[Promise alloc] initWithBlock:promiseBlock];
}

+(instancetype)resolveWithObject:(id)obj {
    Promise *promise = [[Promise alloc] initWithBlock:nil];
    promise.result = obj;
    return promise;
}

-(instancetype)initWithBlock:(PromiseBlock)promiseBlock {
    self = [super init];
    if (self) {
        if (promiseBlock) {
            // __weak typeof (self) weakSelf = self;
            // use *strong* self inside the block on purpose, so that
            // current Promise object is retained before all callbacks
            // (resolveBlock/rejectBlock/promiseBlock) finish.
            dispatch_async([Promise q], ^{
                @try {
                    self.result = promiseBlock();
                } @catch (NSException *exception) {
                    self.result = exception;
                }
            });
        }
    }
    return self;
}

-(void)resolveOnFulfilledBlock:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected {
    id result = self.result;
    if ([result isKindOfClass:[self class]]) {
        dispatch_async([Promise q], ^{
            [result resolveOnFulfilledBlock:onFulfilled onRejected:onRejected];
        });
    } else {
        @try {
            if ([self.result isKindOfClass:[NSException class]]) {
                if (onRejected) {
                    self.result = onRejected(result);
                }
            } else if (onFulfilled) {
                self.result = onFulfilled(result);
            }
        } @catch (NSException *exception) {
            self.result = exception;
        }
    }
}

-(instancetype)then:(OnFulfilledBlock)onFulfilled {
    return [self then:onFulfilled onRejected:nil];
}

-(instancetype)then:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected {
    //  __weak typeof (self) weakSelf = self;
    // use *strong* self inside the block on purpose, so that
    // current Promise object is retained before all callbacks
    // (resolveBlock/rejectBlock/promiseBlock) finish.
    dispatch_async([Promise q], ^{
        [self resolveOnFulfilledBlock:onFulfilled onRejected:onRejected];
    });
    return self;
}

-(instancetype)catch:(OnRejectedBlock)onRejected {
    return [self then:nil onRejected:onRejected];
}

+(dispatch_queue_t)q {
    static dispatch_queue_t q;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        q = dispatch_queue_create("net.neevek.promise-objc", DISPATCH_QUEUE_SERIAL);
    });
    
    return q;
}

@end
