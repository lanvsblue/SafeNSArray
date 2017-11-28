# Safe NSArray: 防止NSArray数组越界导致Crash

## 前言
防止数组越界，通常的做法有两种：
* 创建一个NSArray的分类，在分类中增加一个safeObjectAtIndex:方法，在这个方法中对index进行判断，是否越界。访问NSArray数据时，调用safeObjectAtIndex:。
* 创建一个NSArray的分类，在分类中增加一个swizzling_ObjectAtIndex:方法，并且进行Method Swizzling。访问NSArray数据时，调用objectAtIndex:。

在这里我来讲讲第二种方法，用Runtime实现防止数组越界。

## Runtime实现防止数组越界
如果对Method Swizzling不熟悉的同学可以先看看这篇文章:[http://nshipster.cn/method-swizzling/](http://nshipster.cn/method-swizzling/)

首先实现Method Swizzling方法:
`Swizzling.h`

```objective-c
#include <objc/runtime.h>
static inline void swizzling_exchangeMethod(Class clazz, SEL originalSelector, SEL exchangeSelector) {

    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);

    Method exchangeMethod = class_getInstanceMethod(clazz, exchangeSelector);
    
    if (class_addMethod(clazz, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(clazz, exchangeSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }else{
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}
```



然后对NSArray进行Method Swizzling，

一共需要Swizzling2*4个方法，简单来说就是每四个Array类中的两个方法。因为我们知道NSArray是使用类簇实现的，NSArray只相当与是一个工厂方法。

首先是objectAtIndex:方法，objectAtIndex:方法是通过- [array objectAtIndex:]的形式调用的，分别需要Swizzling以下四个方法：
```objective-c
  - [__NSArray0 objectAtIndex:];

  - [__NSArrayI objectAtIndex:];

  - [__NSArrayM objectAtIndex:];

  - [__NSSingleObjectArrayI objectAtIndex:];
```
接下来是objectAtIndexedSubscript:方法，objectAtIndexedSubscript:方法是通过array[index]下标的形式调用的，分别需要Swizzling以下四个方法：
```objective-c
  - [__NSArray0 objectAtIndexedSubscript:];

  - [__NSArrayI objectAtIndexedSubscript:];

  - [__NSArrayM objectAtIndexedSubscript:];

  - [__NSSingleObjectArrayI objectAtIndexedSubscript:];
```
你可能比较疑惑的是__NSArray0、__NSArrayI等等分别代表什么呢？这里列一张表格来表示上述几个Array类簇 的关系：

|           类簇           |                   解释                    |
| :--------------------: | :-------------------------------------: |
|       __NSArray0       | 空数组，例如：array0 = [[NSArray alloc] init]; |
|       __NSArrayI       |     不可变数组，例如：arrayI = @[@"a",@"b"];     |
|       __NSArrayM       | 可变数组，例如：arrayM = [arrayI mutableCopy];  |
| __NSSingleObjectArrayI |      单元素数组，例如：soArrayI = @[@"a"];       |



我们最后在NSArray分类中实现的代码：

  `NSArray+Safe.m`

```objective-c
@implementation NSArray (Safe)
+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzling_exchangeMethod(objc_getClass("__NSArray0"), @selector(objectAtIndex:), @selector(emptyArray_objectAtIndex:));
        swizzling_exchangeMethod(objc_getClass("__NSArrayI"), @selector(objectAtIndex:), @selector(arrayI_objectAtIndex:));
        swizzling_exchangeMethod(objc_getClass("__NSArrayM"), @selector(objectAtIndex:), @selector(arrayM_objectAtIndex:));
        swizzling_exchangeMethod(objc_getClass("__NSSingleObjectArrayI"), @selector(objectAtIndex:), @selector(singleObjectArrayI_objectAtIndex:));
        
        swizzling_exchangeMethod(objc_getClass("__NSArray0"), @selector(objectAtIndexedSubscript:), @selector(emptyArray_objectAtIndexedSubscript:));
        swizzling_exchangeMethod(objc_getClass("__NSArrayI"), @selector(objectAtIndexedSubscript:), @selector(arrayI_objectAtIndexedSubscript:));
        swizzling_exchangeMethod(objc_getClass("__NSArrayM"), @selector(objectAtIndexedSubscript:), @selector(arrayM_objectAtIndexedSubscript:));
        swizzling_exchangeMethod(objc_getClass("__NSSingleObjectArrayI"), @selector(objectAtIndex:), @selector(singleObjectArrayI_objectAtIndexedSubscript:));
        
        
    });
}

#pragma MARK -  - (id)objectAtIndex:
- (id)emptyArray_objectAtIndex:(NSUInteger)index{
    return nil;
}

- (id)arrayI_objectAtIndex:(NSUInteger)index{
    if(index < self.count){
        return [self arrayI_objectAtIndex:index];
    }
    return nil;
}

- (id)arrayM_objectAtIndex:(NSUInteger)index{
    if(index < self.count){
        return [self arrayM_objectAtIndex:index];
    }
    return nil;
}

- (id)singleObjectArrayI_objectAtIndex:(NSUInteger)index{
    if(index < self.count){
        return [self singleObjectArrayI_objectAtIndex:index];
    }
    return nil;
}

#pragma MARK -  - (id)objectAtIndexedSubscript:
- (id)emptyArray_objectAtIndexedSubscript:(NSUInteger)index{
    return nil;
}

- (id)arrayI_objectAtIndexedSubscript:(NSUInteger)index{
    if(index < self.count){
        return [self arrayI_objectAtIndex:index];
    }
    return nil;
}

- (id)arrayM_objectAtIndexedSubscript:(NSUInteger)index{
    if(index < self.count){
        return [self arrayM_objectAtIndex:index];
    }
    return nil;
}

- (id)singleObjectArrayI_objectAtIndexedSubscript:(NSUInteger)index{
    if(index < self.count){
        return [self singleObjectArrayI_objectAtIndexedSubscript:index];
    }
    return nil;
}

@end

```



## 使用NSArray+Safe

直接正常使用，无需变动任何代码，也不需要导入任何头文件。

```objective-c
    /*
     * init array
     */
    self.arrayI = @[@"a", @"b", @"c", @"d"];
    
    self.arrayM = [self.arrayI mutableCopy];
    
    self.array0 = @[];
    
    self.singleObjectArrayI = @[@"a"];
    
    
    /*
     * overflow !
     */
    NSLog(@"self.array[5]: %@",self.arrayI[4]);
    NSLog(@"[self.array objectAtIndex:4]: %@",[self.arrayI objectAtIndex:4]);
    
    NSLog(@"[self.mArray objectAtIndex:5]: %@",self.arrayM[5]);
    NSLog(@"[self.mArray objectAtIndex:5]: %@",[self.arrayM objectAtIndex:5]);
    
    NSLog(@"self.emptyArray[5]: %@",self.array0[4]);
    NSLog(@"[self.emptyArray objectAtIndex:4]: %@",[self.array0 objectAtIndex:4]);
    
    NSLog(@"self.signalArray[5]: %@",self.singleObjectArrayI[4]);
    NSLog(@"[self.signalArray objectAtIndex:4]: %@",[self.singleObjectArrayI objectAtIndex:4]);
```