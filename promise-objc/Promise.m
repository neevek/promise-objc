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
@property (copy, nonatomic) void(^onResolvedBlock)();
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
            // __weak typeof (self) weakSelf = self;
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
                    self.result = exception;
                }
            });
        }
    }
    return self;
}

-(void)resolveWithResult:(id)result {
    if ([result isKindOfClass:[self class]]) {
        [result then:^id(id result) {
            [self resolveWithResult:result];
            return nil;
        } onRejected:^id(NSException *error) {
            [self resolveWithResult:error];
            return nil;
        }];
        return;
    }
    
    self.result = result;
//    NSLog(@">>>>>>>>>>>>>>>>> resolve: %@, %@, %@", self, result, self.onResolvedBlock);
    if (self.onResolvedBlock) {
        self.onResolvedBlock();
    }
}

-(instancetype)then:(OnFulfilledBlock)onFulfilled {
    return [self then:onFulfilled onRejected:nil];
}
//
//-(instancetype)then:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected {
//    //  __weak typeof (self) weakSelf = self;
//    // use *strong* self inside the block on purpose, so that
//    // current Promise object is retained before all callbacks
//    // (resolveBlock/rejectBlock/promiseBlock) finish.
//    dispatch_async([Promise q], ^{
//        id result = self.result;
//        if ([result isKindOfClass:[self class]]) {
//            dispatch_async([Promise q], ^{
//                [result then:onFulfilled onRejected:onRejected];
//            });
//        } else {
//            @try {
//                if ([self.result isKindOfClass:[NSException class]]) {
//                    if (onRejected) {
//                        self.result = onRejected(result);
//                    }
//                } else if (onFulfilled) {
//                    self.result = onFulfilled(result);
//                }
//            } @catch (NSException *exception) {
//                self.result = exception;
//            }
//        }
//    });
//    return self;
//}
//

-(instancetype)catch:(OnRejectedBlock)onRejected {
    return [self then:nil onRejected:onRejected];
}








-(instancetype)then:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected {
    __weak typeof (self) weakSelf = self;
    InternalResolveBlock prevResolveBlock = self.onResolvedBlock;
    self.onResolvedBlock = ^{
        //  __weak typeof (self) weakSelf = self;
        // use *strong* self inside the block on purpose, so that
        // current Promise object is retained before all callbacks
        // (resolveBlock/rejectBlock/promiseBlock) finish.
//        dispatch_async([Promise q], ^{
        
            NSLog(@"prevResolveBlock: %@", weakSelf.result);
        
            if ([weakSelf.result isKindOfClass:[weakSelf class]]) {
//                dispatch_async([Promise q], ^{
//                    [result then:onFulfilled onRejected:onRejected];
//                });
            } else {
                if (prevResolveBlock) {
                    prevResolveBlock();
                }
                
//        NSLog(@"resolveBlock: %@, %@, %@", weakSelf, weakSelf.result, prevResolveBlock);
                
                @try {
                    if ([weakSelf.result isKindOfClass:[NSException class]]) {
                        if (onRejected) {
                            weakSelf.result = onRejected(weakSelf.result);
                        }
                    } else if (onFulfilled) {
                        weakSelf.result = onFulfilled(weakSelf.result);
                    }
                } @catch (NSException *exception) {
                    weakSelf.result = exception;
                }
            }
//        });
        weakSelf.onResolvedBlock = nil;
    };
    if (self.result) {
        dispatch_async([Promise q], ^{
            weakSelf.onResolvedBlock();
        });
    }
    return self;
}

//-(void)dealloc {
//    NSLog(@"dealloc: %@", self);
//}

+(dispatch_queue_t)q {
    static dispatch_queue_t q;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        q = dispatch_queue_create("net.neevek.promise-objc", DISPATCH_QUEUE_SERIAL);
    });
    
    return q;
}

//+(dispatch_queue_t)q {
//    const static int qCount = 5;
//    static dispatch_queue_t q[qCount];
//    static dispatch_once_t oncePredicate[qCount];
//    static int index = 0;
//    @synchronized (self) {
//        index = (index + 1) % qCount;
//        dispatch_once(&oncePredicate[index], ^{
//            const int nameLen = 24+1+1;
//            char name[nameLen] = {0};
//            sprintf(name, "net.neevek.promise-objc_%d", index);
//            q[index] = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL);
//        });
//    }
//    return q[index];
//}

@end
