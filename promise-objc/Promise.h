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
typedef void(^Resolver)(ResolveBlock resolve, RejectBlock reject);
typedef id(^OnResolvedBlock)(id result);
typedef id(^OnRejectedBlock)(id error);

+(instancetype)resolveWithObject:(id)obj;
+(instancetype)promiseWithBlock:(Resolver)resolver;
+(instancetype)all:(NSArray *)items;
-(instancetype)then:(OnResolvedBlock)onResolved;
-(instancetype)then:(OnResolvedBlock)onResolved onRejected:(OnRejectedBlock)onRejected;
-(instancetype)catch:(OnRejectedBlock)onRejected;

@end
