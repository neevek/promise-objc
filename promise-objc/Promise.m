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
                    [self resolveWithResult:exception];
                }
            });
        }
    }
    return self;
}

-(void)resolveWithResult:(id)result {
    if (self.settled) {
        return;
    }
    self.settled = YES;
    
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
    
//    NSLog(@">>>>>>>>>>>>>>>>> resolve: %@, %@, %@", self, result, self.onResolvedBlock);
    self.result = result;
    if (self.onResolvedBlock) {
        self.onResolvedBlock();
        self.onResolvedBlock = nil;
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
        //  __weak typeof (self) weakSelf = self;
        // use *strong* self inside the block on purpose, so that
        // current Promise object is retained before all callbacks
        // (resolveBlock/rejectBlock/promiseBlock) finish.
        
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
