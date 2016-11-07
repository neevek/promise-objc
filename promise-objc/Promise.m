//
//  Promise.m
//  promise-objc
//
//  Created by 陈小黑 on 05/11/2016.
//  Copyright © 2016 neevek. All rights reserved.
//

#import "Promise.h"

@interface Promise()

typedef void(^InternalResolveBlock)();

@property (strong, nonatomic) id result;
@property (nonatomic) BOOL settled;
@property (strong, nonatomic) InternalResolveBlock onResolvedBlock;
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
    
    if ([result isKindOfClass:[self class]]) {
        [result then:^id(id result) {
            NSLog(@"resolved: %@", result);
            dispatch_async([Promise q], ^{
                [self resolveWithResult:result];
            });
            return nil;
        } onRejected:^id(NSException *error) {
            dispatch_async([Promise q], ^{
                [self resolveWithResult:error];
            });
            return nil;
        }];
        return;
    }
    
    self.settled = YES;
    self.result = result;
    if (self.onResolvedBlock) {
        self.onResolvedBlock();
        self.onResolvedBlock = nil;
    }
}

-(instancetype)then:(OnFulfilledBlock)onFulfilled {
    return [self then:onFulfilled onRejected:nil];
}

-(instancetype)catch:(OnRejectedBlock)onRejected {
    return [self then:nil onRejected:onRejected];
}

-(void)feedThenableWithSettledResult:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected {
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
}

-(instancetype)then:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected {
    if (self.settled) {
        dispatch_async([Promise q], ^{
            [self feedThenableWithSettledResult:onFulfilled onRejected:onRejected];
        });
        return self;
    }
    
    __weak typeof (self) weakSelf = self;
    InternalResolveBlock prevResolveBlock = self.onResolvedBlock;
    self.onResolvedBlock = ^{
        if (prevResolveBlock) {
            prevResolveBlock();
        }
        
        [weakSelf feedThenableWithSettledResult:onFulfilled onRejected:onRejected];
    };
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
