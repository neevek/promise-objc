//
//  Promise.h
//  promise-objc
//
//  Created by neevek <i@neevek.net> on Nov. 05 2016.
//  Copyright © 2016 neevek. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Promise : NSObject

typedef void(^ResolveBlock)(id result);
typedef void(^RejectBlock)(id error);
typedef void(^PromiseBlock)(ResolveBlock resolve, RejectBlock reject);
typedef id(^OnFulfilledBlock)(id result);
typedef id(^OnRejectedBlock)(id error);

+(instancetype)resolveWithObject:(id)obj;
+(instancetype)promiseWithBlock:(PromiseBlock)promiseBlock;
+(instancetype)all:(NSArray *)items;
-(instancetype)then:(OnFulfilledBlock)onFulfilled;
-(instancetype)then:(OnFulfilledBlock)onFulfilled onRejected:(OnRejectedBlock)onRejected;
-(instancetype)catch:(OnRejectedBlock)onRejected;

@end
