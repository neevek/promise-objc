//
//  Promise.m
//  promise-objc
//
//  Created by neevek <i@neevek.net> on Nov. 05 2016.
//  Copyright © 2016 neevek. All rights reserved.
//

#import "Promise.h"
#include <stdatomic.h>

typedef void(^VoidBlock)();
typedef VoidBlock ThenBlock;
typedef NS_ENUM(NSUInteger, State) {
    kStatePending,
    kStateFulfilled,
    kStateRejected,
    kStateErrorCaught,
};

@interface ThenBlockWrapper : NSObject
@property (strong, nonatomic) ThenBlock thenBlock;
@property (strong, nonatomic) ThenBlockWrapper *next;
@end
@implementation ThenBlockWrapper
-(instancetype)initWithThenBlock:(ThenBlock)thenBlock {
    self = [super init];
    if (self) {
        self.thenBlock = thenBlock;
    }
    return self;
}
@end

@interface Promise()
@property (nonatomic) State state;
@property (strong, nonatomic) id result;
@property (strong, nonatomic) ThenBlockWrapper *thenBlockWrapper;
@property (weak, nonatomic) ThenBlockWrapper *lastThenBlockWrapper;
@end

@implementation Promise

+(instancetype)promiseWithResolver:(Resolver)resolver {
    return [[Promise alloc] initWithBlock:resolver];
}

+(instancetype)resolveWithObject:(id)obj {
    if ([obj isKindOfClass:[self class]]) {
        return obj;
    }
    
    Promise *promise = [[Promise alloc] initWithBlock:nil];
    dispatch_async([Promise q], ^{
        [promise settleResult:obj withState:kStateFulfilled];
    });
    return promise;
}

+(instancetype)all:(NSArray *)items {
    return [Promise promiseWithResolver:^(ResolveBlock resolve, RejectBlock reject) {
        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithCapacity:items.count];
        __block atomic_int count = 0;
        
        void(^fulfilItemBlock)(NSInteger index, id item) = ^void(NSInteger index, id item) {
            [resultArray replaceObjectAtIndex:index withObject:item];
            if (++count == items.count) {
                resolve(resultArray);
            }
        };
        
        for (NSInteger i = 0; i < items.count; ++i) {
            [resultArray addObject:[NSNull null]];
            
            id item = [items objectAtIndex:i];
            if ([item isKindOfClass:[self class]]) {
                OnFulfilledBlock onFulfilBlock;
                OnRejectedBlock onRejectBlock;
                onFulfilBlock = ^id(id result) {
                    fulfilItemBlock(i, result);
                    return result;
                };
                onRejectBlock = ^id(id error) {
                    fulfilItemBlock(i, error);
                    return error;
                };
                
                [item then:onFulfilBlock onRejected:onRejectBlock];
            } else {
                fulfilItemBlock(i, item);
            }
        }
    }];
}

-(instancetype)initWithBlock:(Resolver)resolver {
    self = [super init];
    if (self && resolver) {
        // __weak typeof (self) weakSelf = self;
        // use *strong* self inside the block on purpose, so that
        // current Promise object is retained before 'resolver'
        // resolve or reject.
        dispatch_async([Promise q], ^{
            ResolveBlock resolveBlock = ^void(id result) {
                [self settleResult:result withState:kStateFulfilled];
            };
            RejectBlock rejectBlock = ^void(id error) {
                [self settleResult:error withState:kStateRejected];
            };
            
            @try {
                resolver(resolveBlock, rejectBlock);
            } @catch (NSException *error) {
                [self settleResult:error withState:kStateRejected];
            }
        });
    }
    return self;
}

-(void)settleResult:(id)result withState:(State)state {
    if (self.state == kStatePending) {
        self.state = state;
        self.result = result;
        if (self.thenBlockWrapper) {
            self.thenBlockWrapper.thenBlock();
        }
    }
}

-(instancetype)then:(OnFulfilledBlock)onFulfilled {
    return [self then:onFulfilled onRejected:nil];
}

-(instancetype)catch:(OnRejectedBlock)onRejected {
    return [self then:nil onRejected:onRejected];
}

-(void)feedCallbacksWithSettledResult:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected {
    if ([self.result isKindOfClass:[self class]]) {
        [self.result then:^id(id result) {
            self.result = result;
            if (self.thenBlockWrapper) {
                self.thenBlockWrapper.thenBlock();
            }
            return result;
        } onRejected:^id(id error) {
            self.result = error;
            if (self.thenBlockWrapper) {
                self.thenBlockWrapper.thenBlock();
            }
            return error;
        }];
        
    } else {
        @try {
            if (self.state == kStateRejected || [self.result isKindOfClass:[NSError class]]) {
                if (onRejected) {
                    self.result = onRejected(self.result);
                    self.state = kStateErrorCaught;
                }
            } else {
                // if state is not Rejected, it is either Fulfilled or ErrorCaught
                // we take them as Fulfilled.
                if (onFulfilled) {
                    self.result = onFulfilled(self.result);
                }
            }
        } @catch (NSException *error) {
            self.result = error;
        }
        
        if (self.thenBlockWrapper.next) {
            self.thenBlockWrapper = self.thenBlockWrapper.next;
            self.thenBlockWrapper.thenBlock();
        } else {
            self.thenBlockWrapper = nil;
            self.lastThenBlockWrapper = nil;
        }
    }
}

-(instancetype)then:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected {
    dispatch_async([Promise q], ^{
        ThenBlockWrapper *thenBlockWrapper = [[ThenBlockWrapper alloc] initWithThenBlock:^{
            [self feedCallbacksWithSettledResult:onFulfilled onRejected:onRejected];
        }];
        
        if (!self.thenBlockWrapper) {
            self.thenBlockWrapper = thenBlockWrapper;
            self.lastThenBlockWrapper = thenBlockWrapper;
            
            // if it is the last 'then' and state is 'settled', feed it with  directly
            if (self.state != kStatePending) {
                [self feedCallbacksWithSettledResult:onFulfilled onRejected:onRejected];
            }
        } else {
            self.lastThenBlockWrapper.next = thenBlockWrapper;
            self.lastThenBlockWrapper = thenBlockWrapper;
        }
        
    });
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
