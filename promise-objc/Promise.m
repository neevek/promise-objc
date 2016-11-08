//
//  Promise.m
//  promise-objc
//
//  Created by 陈小黑 on 05/11/2016.
//  Copyright © 2016 neevek. All rights reserved.
//

#import "Promise.h"

typedef void(^ThenBlock)();

@interface ThenBlockWrapper : NSObject
@property (strong, nonatomic) ThenBlock thenBlock;
@property (strong, nonatomic) ThenBlockWrapper *next;
@end

@implementation ThenBlockWrapper
@end


@interface Promise()

@property (strong, nonatomic) id result;
@property (nonatomic) BOOL settled;
@property (nonatomic) BOOL callingThenables;
@property (strong, nonatomic) ThenBlockWrapper *thenBlockWrapper;
@property (weak, nonatomic) ThenBlockWrapper *lastThenBlockWrapper;
@end

@implementation Promise

+(instancetype)promiseWithBlock:(PromiseBlock)promiseBlock {
    return [[Promise alloc] initWithBlock:promiseBlock];
}

+(instancetype)resolveWithObject:(id)obj {
    Promise *promise = [[Promise alloc] initWithBlock:nil];
    dispatch_async([Promise q], ^{
        [promise resolveWithResult:obj];
    });
    return promise;
}

-(instancetype)initWithBlock:(PromiseBlock)promiseBlock {
    self = [super init];
    if (self) {
        if (promiseBlock) {
//             __weak typeof (self) weakSelf = self;
            // use *strong* self inside the block on purpose, so that
            // current Promise object is retained before all callbacks
            // (resolveBlock/rejectBlock/promiseBlock) finish.
            dispatch_async([Promise q], ^{
                ResolveBlock resolveBlock = ^void(id result) {
                    [self resolveWithResult:result];
                };
                RejectBlock rejectBlock = ^void(NSException *exception) {
                    [self resolveWithResult:exception];
                };
                
                @try {
                    promiseBlock(resolveBlock, rejectBlock);
                } @catch (NSException *exception) {
                    [self resolveWithResult:exception];
                }
            });
        }
    }
    return self;
}

-(void)resolveWithResult:(id)result {
    if (self.settled) {
        NSLog(@"settled");
        return;
    }
    self.settled = YES;
    self.result = result;
    if (self.thenBlockWrapper) {
        self.callingThenables = YES;
        self.thenBlockWrapper.thenBlock();
    }
}

-(instancetype)then:(OnFulfilledBlock)onFulfilled {
    return [self then:onFulfilled onRejected:nil];
}

-(instancetype)catch:(OnRejectedBlock)onRejected {
    return [self then:nil onRejected:onRejected];
}

-(void)feedThenableWithSettledResult:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected {
    if ([self.result isKindOfClass:[self class]]) {
        [self.result then:^id(id result) {
            self.result = result;
            if (self.thenBlockWrapper) {
                self.thenBlockWrapper.thenBlock();
            }
            return result;
        } onRejected:^id(NSException *error) {
            self.result = error;
            if (self.thenBlockWrapper) {
                self.thenBlockWrapper.thenBlock();
            }
            return error;
        }];
        return;
    }
    
    @try {
        if ([self.result isKindOfClass:[NSException class]]) {
            if (onRejected) {
                self.result = onRejected(self.result);
            }
        } else if (onFulfilled) {
            self.result = onFulfilled(self.result);
        }
    } @catch (NSException *exception) {
        self.result = exception;
    }
    
    
    if (self.thenBlockWrapper.next) {
        self.thenBlockWrapper = self.thenBlockWrapper.next;
        self.thenBlockWrapper.thenBlock();
    } else {
        self.thenBlockWrapper = nil;
        self.lastThenBlockWrapper = nil;
        self.callingThenables = NO;
    }
}

-(instancetype)then:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected {
    ThenBlockWrapper *thenBlockWrapper = [[ThenBlockWrapper alloc] init];
    if (!self.thenBlockWrapper) {
        self.thenBlockWrapper = thenBlockWrapper;
        self.lastThenBlockWrapper = thenBlockWrapper;
    } else {
        self.lastThenBlockWrapper.next = thenBlockWrapper;
        self.lastThenBlockWrapper = thenBlockWrapper;
    }
    
    __weak typeof (self) weakSelf = self;
    thenBlockWrapper.thenBlock = ^{
        [weakSelf feedThenableWithSettledResult:onFulfilled onRejected:onRejected];
    };
    
    if (self.settled && !self.callingThenables) {
        self.callingThenables = YES;
        dispatch_async([Promise q], ^{
            self.thenBlockWrapper.thenBlock();
        });
    }
    return self;
}

-(void)dealloc {
    NSLog(@"dealloc: %@", self);
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
