AHGCollection
=============

AHGCollection provides methods for working with collections of objects inspired by functional programming libraries such as [Scala Collections](http://docs.scala-lang.org/overviews/collections/overview.html) and [Underscore.js](http://underscorejs.org/).

AHGCollection works with classes that implement the `NSFastEnumeration` protocol. This includes the following Foundation classes:

- NSArray
- NSDictionary
- NSSet
- NSOrderedSet

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

### Combing Operations

License
-------

AHGCollection is licensed under the [MIT License](LICENSE).
