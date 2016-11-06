//
//  Promise.h
//  promise-objc
//
//  Created by 陈小黑 on 05/11/2016.
//  Copyright © 2016 neevek. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Promise : NSObject

typedef id(^ResolveBlock)(id result);
typedef id(^RejectBlock)(NSException *error);
typedef id(^PromiseBlock)();
typedef ResolveBlock OnFulfilledBlock;
typedef RejectBlock OnRejectedBlock;

+(instancetype)resolveWithObject:(id)obj;
+(instancetype)promiseWithBlock:(PromiseBlock)promiseBlock;
-(instancetype)then:(OnFulfilledBlock)onFulfilled;
-(instancetype)then:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected;
-(instancetype)catch:(OnRejectedBlock)onRejected;

@end
