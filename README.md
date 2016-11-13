promise-objc
============

**promise-objc** is a `Promise` implementation for Objective-C, it **flattens asynchronous code**, yet, it fully supports **concurrency**.

Usage
=====

See the following demos(slightly commented), and you are ready to take it away and put it in your toolbox.

(Simply copy **Promise.h** and **Promise.m** to your project, start using it.)

```objective-c
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
  // result is "P1-2-3-5"
  return result;
}];
```

```objective-c
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
  // result is "P1-ERROR-5"
  return result;
}];
```

```objective-c
[[[[[[Promise promiseWithResolver:^(ResolveBlock resolve, RejectBlock reject) {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        resolve(@"P1");
  });
}] then:^id(id result) {
  // intentionally trigger an NSError*
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
  // result is "P1-ERR-CAUGHT-5"
  return result;
}];
```

`promise-objc` supports `[Promise all:@[...]]` to `resolve` **concurrently** multiple objects(can be whatever object, Promise included). When all the objects are resolved, the results will be collected and passed to the `then` handler that follows.

```objective-c
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
  // result is an NSArray*, which contains [ "P0", "P1-P2-P3-DirectReturn-P4-P5", "literal_str" ]
  return result;
}];
```

Under MIT License
=================
```
Copyright (c) 2016 neevek <i@neevek.net>
See the file license.txt for copying permission.
```
