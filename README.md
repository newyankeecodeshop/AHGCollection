AHGCollection
=============

AHGCollection provides methods for working with collections of objects inspired by functional programming libraries such as [Scala Collections](http://docs.scala-lang.org/overviews/collections/overview.html) and [Underscore.js](http://underscorejs.org/).

AHGCollection works with classes that implement the `NSFastEnumeration` protocol. This includes the following Foundation classes:

- NSArray
- NSSet
- NSOrderedSet
- NSDictionary (enumerates keys)

It should also work with any custom implementation of `NSFastEnumeration`. If you need help adding the protocol to one of your own classes, you can look in [AHGEnumeration.m](AHGCollection/AHGEnumeration.m) for some different ways it can be implemented. Many thanks to Mark Dalrymple's for his deep-dive on [theNerdBlog](http://blog.bignerdranch.com/1003-fast-enumeration-part-1/).

Lazy Evaluation
---------------

Perhaps the main difference between `AHGCollection` and other libraries that add "map/filter/reduce" methods to Foundation collections is that `AHGCollection` is implemented using "lazy evaluation". This means that the result of operations such as "map" doesn't immediately produce a new collection. For example, given an NSArray of 10,000 objects, `[AHGCollection map:]` will not produce another NSArray of 10,000 objects. Instead, it will evaluate the mapping function each time the collection is iterated using `NSFastEnumeration`. This can be really beneficial if you don't intend to use all 10,000 results, maybe because you're showing only a subset of objects in a `UITableView`. It also removes the need for custom `NSFastEnumeration` implementations to have a mutable variant or some mechanism for describing what mutable collection to use when transforming the values.

You can use `[AHGCollection allObjects]` to get a complete NSArray containing all the objects in the collection, applying any operations. The "Map" example below shows this. 

Examples
--------

### Filter

```objc
BOOL (^myFilter)(NSString *) = ^(NSString *str) {
    return (BOOL) (str.length > 3);
};  

AHGCollection *strings = AHGNewColl(@[@"hello", @"to", @"you", @"again"]);
for (NSString *string in [strings filter:myFilter]) {
    // string's length is larger than 3
}
```

### Map

```objc
NSSet *stringSet = [NSSet setWithArray:@[@"What", @"is", @"going", @"on", @"here?"]];
NSArray *result2 = [[[AHGNewColl(stringSet) map:^id(NSString *str) {
    return [str uppercaseString];
}] map:^id(NSString *str) {
    return [str stringByAppendingString:@"!"];
}] allObjects];

// Produces @[@"WHAT!", @"IS!", @"GOING!", @"ON!", @"HERE?!"]
```

### Reduce

```objc
AHGCollection *strings = AHGNewColl(@[@"hello", @"to", @"you", @"again"]);
    
NSString *result = [strings reduce:@"" withOperator:^id(NSString *resultObject, NSString *anObject) {
    return [resultObject stringByAppendingString:anObject];
}];

// Produces @"hellotoyouagain"
```

### Combining Operations

Many operations on a collection can be chained together. The result is not evaluated until the collection is enumerated or converted into an `NSArray` using `[AHGCollection allobjects]`.

```objc
NSNumber *num = [[[AHGNewColl(@[@"hello", @"to", @"you", @"again"]) filterNot:^BOOL(NSString *str) {
	return [str isEqualToString:@"again"];
}] map:^id(NSString *str) {
	return [str stringByAppendingString:@"-mapped"];
}] reduce:@0 withOperator:^id(NSNumber *resultObject, NSString *str) {
	return [NSNumber numberWithInteger:[resultObject integerValue] + [str length]];
}];

// Number will be 31
```

License
-------

AHGCollection is licensed under the [MIT License](LICENSE).
