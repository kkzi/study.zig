
[原文链接](https://gist.github.com/ityonemo/769532c2017ed9143f3571e5ac104e50)

# 30分钟入门Zig

本文受到[30分钟入门Rust](https://fasterthanli.me/blog/2020/a-half-hour-to-learn-rust/)启发

## 基础(Basics)

使用命令`zig run my_code.zig`编译和立刻运行Zig程序。本文中每一个示例都是Zig程序，您可以尝试使用这个命令运行它们（有一些示例包含演示用的编译时错误，在运行时可以注释掉这些有错误的代码行）

在开始之前，需要定义一个`main()`函数。
看起来像这样：
```zig
// comments look like this and go to the end of the line
pub fn main() void {}
```

使用`@import`导入标准库，并把标准库`namespace`赋值给一个`const`值。在Zig中，几乎所有的东西都必须分配标识符(identifier)。也可以使用`@import`导入其它Zig文件。使用`@cImport`导入C文件。
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("hello world!\n", .{});
}
```

说明：
- `std.debug.print`的第二个参数很有趣，我会在 [结构体(Structs)](#结构体structs) 章节详细解释

`var` 声明一个变量，大多数时候需要指明变量的类型
```zig
const std = @import("std");

pub fn main() void {
    var x: i32 = 47; // declares "x" of type i32 to be 47.
    std.debug.print("x: {}\n", .{x});
}
```

`const` 声明一个常量（变量的值不可被修改）
```zig
pub fn main() void {
    const x: i32 = 47;
    x = 42; // error: cannot assign to constant
}
```

Zig严格限制隐藏标识符，以免混淆：
```zig
const x: i32 = 47;

pub fn main() void {
    var x: i32 = 42;  // error: redefinition of 'x'
}
```

全局常量`const`默认是编译时`comptime`值，如果省写类型，则类型为编译时类型`comptime type`，其值可被赋值给运行时变量`runtime value`
```zig
const x: i32 = 47;
const y = -47;  // comptime integer.

pub fn main() void {
    var a: i32 = y; // comptime constant coerced into correct type
    var b: i64 = y; // comptime constant coerced into correct type
    var c: u32 = y; // error: cannot cast negative value -47 to unsigned integer
}
```

可以先给变量赋值为`undefined`，随后再修改它。Zig使用0xAA填充`undefined`值，用于调试时检测错误。
```zig
const std = @import("std");

pub fn main() void {
    var x: u32 = undefined;
    std.debug.print("undefined: {x}\n", .{x});
}
```

当可以推导出类型时，可以省略类型信息
```zig
const std = @import("std");

pub fn main() void {
    var x: i32 = 47;
    var y: i32 = 47;
    var z = x + y; // declares z and sets it to 94.
    std.debug.print("z: {}\n", .{z});
}
```

注意，整形字面量(`integer literals`)是编译时类型(`comptime-typed`)。以下代码会报错：
```zig
pub fn main() void {
    var x = 47; // error: variable of type 'comptime_int' must be const or comptime
}
```

## 函数(Functions)

下面是一个名称为`foo`，返回为空(`void`)的函数。关键字`pub`表示可被外部作用域访问，所有`main`函数必须是`pub`的。函数的调用方式和大多数其它编程语言类似：
```zig
const std = @import("std");

fn foo() void {
    std.debug.print("foo!\n", .{});

    //optional:
    return;
}

pub fn main() void {
    foo();
}
```

下面的`foo`函数返回`integer`值：
```zig
const std = @import("std");

fn foo() i32 {
    return 47;
}

pub fn main() void {
    var result = foo();
    std.debug.print("foo: {}\n", .{result});
}
```

如果函数有返回值，调用方不能忽略它：
```zig
fn foo() i32 {
    return 47;
}

pub fn main() void {
    foo(); // error: expression value is ignored
}
```

如果确实需要忽略函数的返回值，可以使用一次性的(throw-away)`_`:
```zig
fn foo() i32 {
    return 47;
}

pub fn main() void {
  _ = foo();
}
```

函数的参数需要指明类型：
```
const std = @import("std");

fn foo(x: i32) void {
    std.debug.print("foo param: {}\n", .{x});
}

pub fn main() void {
    foo(47);
}
```

## 结构体(Structs)

使用 `struct` 声明一个结构体，使用 `const` 命名。使用`.`对结构体的成员进行赋值，赋值时成员顺序可和声明时顺序不同：
```zig
const std = @import("std");

const Vec2 = struct{
    x: f64,
    y: f64
};

pub fn main() void {
    var v = Vec2{.y = 1.0, .x = 2.0};
    std.debug.print("v: {}\n", .{v});
}
```

结构体在声明时可指定默认值；结构体也可以是匿名的；当所有成员变量的值都能被计算出来时，结构体可被强制转换为另外一个结构体：
```zig
const std = @import("std");

const Vec3 = struct{
    x: f64 = 0.0,
    y: f64,
    z: f64
};

pub fn main() void {
    var v: Vec3 = .{.y = 0.1, .z = 0.2};  // ok
    var w: Vec3 = .{.y = 0.1}; // error: missing field: 'z'
    std.debug.print("v: {}\n", .{v});
}
```

可以在结构体中放入函数，以实现类似面向对象风格（```OOP-style```）。把函数的第一个参数设计为指向结构体的指针，这是一种实现对象（```Object-style```）的语法糖，其类似于Python class中成员函数的`self`参数。在Zig中也使用`self`来命名成员函数的第一个参数：
```zig
const std = @import("std");

const LikeAnObject = struct{
    value: i32,

    fn print(self: *LikeAnObject) void {
        std.debug.print("value: {}\n", .{self.value});
    }
};

pub fn main() void {
    var obj = LikeAnObject{.value = 47};
    obj.print();
}
```

顺便提一下，`std.debug.print`的第二个参数实际上是一个`tuple`，这是一种带有数字字段(`number fields`)的匿名结构体，可使用 `tuple.@"n"` 访问其第n个成员（从0开始）。
在 *编译时*，`std.debug.print`函数计算该`tuple`中的成员参数类型，并生成一个基于要打印的字符串的特定版本，因此Zig能打印出不同类型的值。
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("{}\n", .{1, 2}); #  error: Unused arguments
}
```


## 枚举(Enums)
枚举使用`const`定义一组类型相同有关联的常量值

说明：
- 在某些情况下，可以缩短枚举的名称
- 可以设置枚举为整形值`integer`，但需要使用`@enumToInt`和`@intToEnum`来转换

```zig
const std = @import("std");

const EnumType = enum(u8) {
    EnumOne,
    EnumTwo,
    EnumThree = 3,
};

pub fn main() void {
    std.debug.print("One: {}\n", .{EnumType.EnumOne});
    std.debug.print("Two?: {}\n", .{EnumType.EnumTwo == .EnumTwo});
    std.debug.print("Three?: {}\n", .{@enumToInt(EnumType.EnumThree) == 3});
}
```

## 数组和切片(Arrays and Slices)
在Zig中，数组是一段编译时确定长度的连续内存。数组初始化时需指明值类型，并提供值列表。使用`len`成员获取数组长度

说明：
- Zig数组索引以0开始

```zig
const std = @import("std");

pub fn main() void {
    var array: [3]u32 = [3]u32{47, 47, 47};

    // also valid:
    // var array = [_]u32{47, 47, 47};

    var invalid = array[4]; // error: index 4 outside array of size 3.
    std.debug.print("array[0]: {}\n", .{array[0]});
    std.debug.print("length: {}\n", .{array.len});
}
```

Zig中也有切片(slices), 在运行时确定长度。可从数组和其它切换构造新的切片。切片也有`len`成员。

说明：
- 切片操作的范围是左闭右开

访问切片索引越界会触发运行时错误（`panic`），程序会崩溃（`crash`）
```zig
const std = @import("std");

pub fn main() void {
    var array: [3]u32 = [_]u32{47, 47, 47};
    var slice: []u32 = array[0..2];

    // also valid:
    // var slice = array[0..2];

    var invalid = slice[2]; // panic: index out of bounds

    std.debug.print("slice[0]: {}\n", .{slice[0]});
    std.debug.print("length: {}\n", .{slice.len});
}
```

字符串字面量(`string literals`)是以utf-8编码的`const u8`数组，并以null结束`null-terminated`。
`unicode` 字符只能用在字符串字面量和注释中。

说明：
- 长度不包括结束符（官方称为`sentinel termination`）
- 结束符可访问
- 元素为字节，而不是`unicode glyph`

```zig
const std = @import("std");
const string = "hello 世界";
const world = "world";

pub fn main() void {
    var slice: []const u8 = string[0..5];

    std.debug.print("string {}\n", .{string});
    std.debug.print("length {}\n", .{world.len});
    std.debug.print("null {}\n", .{world[5]});
    std.debug.print("slice {}\n", .{slice});
    std.debug.print("huh? {}\n", .{string[0..7]});
}
```

常量数组可被转型为常量切片。
```zig
const std = @import("std");

fn foo() []const u8 {  // note function returns a slice
    return "foo";      // but this is a const array.
}

pub fn main() void {
    std.debug.print("foo: {}\n", .{foo()});
}
```


## 控制结构(Control structures)

`if` 和其它语言没有区别:
```zig
const std = @import("std");

fn foo(v: i32) []const u8 {
    if (v < 0) {
        return "negative";
    }
    else {
        return "non-negative";
    }
}

pub fn main() void {
    std.debug.print("positive {}\n", .{foo(47)});
    std.debug.print("negative {}\n", .{foo(-47)});
}
```

`switch` 稍有区别，用法如下：
```zig
const std = @import("std");

fn foo(v: i32) []const u8 {
    switch (v) {
        0 => return "zero",
        else => return "nonzero",
    }
}

pub fn main() void {
    std.debug.print("47 {s}\n", .{foo(47)});
    std.debug.print("0 {s}\n", .{foo(0)});
}
```

`for` 则只能用于数组和切片：
```zig
const std = @import("std");

pub fn main() void {
    var array = [_]i32{ 47, 48, 49 };

    for (array) |value| {
        std.debug.print("array {}\n", .{value});
    }
    for (array, 0..) |value, index| {
        std.debug.print("array {}:{}\n", .{ index, value });
    }

    var slice = array[0..2];

    for (slice) |value| {
        std.debug.print("slice {}\n", .{value});
    }
    for (slice, 0..) |value, index| {
        std.debug.print("slice {}:{}\n", .{ index, value });
    }
}
```

`for..else` 当 for 循环体内提前结束 `break` 时，else 不执行
```zig
const std = @import("std");

pub fn main() void {
    var array = [_]i32{ 47, 48, 49 };

    for (array) |value| {
        std.debug.print("array {}\n", .{value});
        break;
    } else {
        std.debug.print("else\n", .{});
    }
}
```

`while` 很正常：
```zig
const std = @import("std");

pub fn main() void {
    var array = [_]i32{ 47, 48, 49 };
    var index: u32 = 0;

    while (index < 2) {
        std.debug.print("value: {}\n", .{array[index]});
        index += 1;
    }
}
```

可以在 `while` 后面跟一个 `()` 表达示，一般用于计数器自增：
```zig
const std = @import("std");

pub fn main() void {
    var array = [_]i32{ 47, 48, 49 };
    var index: u32 = 0;

    while (index < 2) : (index += 1) {
        std.debug.print("value: {}\n", .{array[index]});
    }
}
```


## 错误处理(Error Handling)
错误是一种特殊的`union`类型，这意味着可以在前面加上`!`. 使用`return`抛出错误，和返回正常值一样。
```zig
const MyError = error{
    GenericError,  // just a list of identifiers, like an enum.
    OtherError
};

pub fn main() !void {
    return MyError.GenericError;
}
```

有两种常用的方式处理错误：`try` 转发错误到本函数；`catch` 显示处理错误。
- `try` 是语法糖，等同于 `catch | err | {return err}`
```zig
const std = @import("std");
const MyError = error{
    GenericError
};

fn foo(v: i32) !i32 {
    if (v == 42) return MyError.GenericError;
    return v;
}

pub fn main() !void {
    // catch traps and handles errors bubbling up
    _ = foo(42) catch |err| {
        std.debug.print("error: {}\n", .{err});
    };

    // try won't get activated here.
    std.debug.print("foo: {}\n", .{try foo(47)});

    // this will ultimately cause main to print an error trace and return nonzero
    _ = try foo(42);
}
```

也可以使用`if`判断和处理错误：
```zig
const std = @import("std");
const MyError = error{
    GenericError
};

fn foo(v: i32) !i32 {
    if (v == 42) return MyError.GenericError;
    return v;
}

// note that it is safe for wrap_foo to not have an error ! because
// we handle ALL cases and don't return errors.
fn wrap_foo(v: i32) void {    
    if (foo(v)) | value | {
        std.debug.print("value: {}\n", .{value});
    } else | err | {
        std.debug.print("error: {}\n", .{err});
    }
}

pub fn main() void {
    wrap_foo(42);
    wrap_foo(47);
}
```

## 指针(Pointers)
在类型前面加上`*`声明指针。不支持C式的[顺时针/螺旋式法则](https://c-faq.com/decl/spiral.anderson.html).
使用`.*`成员解引用
```zig
const std = @import("std");

pub fn printer(value: *i32) void {
    std.debug.print("pointer: {}\n", .{value});
    std.debug.print("value: {}\n", .{value.*});
}

pub fn main() void {
    var value: i32 = 47;
    printer(&value);
}
```

说明：
- 指针需要和其指向值的对齐方式正确对齐

对于结构体(Structs)指针来说，使用`.`操作符访问直接成员变量。如果是指向指针的指针类型（多级指针），则需要先对外部指针解引用。
```zig
const std = @import("std");

const MyStruct = struct {
    value: i32
};

pub fn printer(s: *MyStruct) void {
    std.debug.print("value: {}\n", .{s.value});
}

pub fn main() void {
    var value = MyStruct{.value = 47};
    printer(&value);
}
```

所有类型都可和`null`联合(`uniion`)为包装类型。使用`.?`成员访问实际类型（拆箱）：
```zig
const std = @import("std");

pub fn main() void {
    var value: i32 = 47;
    var vptr: ?*i32 = &value;
    var throwaway1: ?*i32 = null;
    var throwaway2: *i32 = null; // error: expected type '*i32', found '(null)'

    std.debug.print("value: {}\n", .{vptr.*}); // error: attempt to dereference non-pointer type
    std.debug.print("value: {}\n", .{vptr.?.*});
}
```

说明：
- 来自 `C ABI` 的指针会自动转型为 nullable pointers

也可以使用 `if` 检查和使用装箱类型：
```zig
const std = @import("std");

fn nullChoice(value: ?*i32) void {
    if (value) | v | {
        std.debug.print("value: {}\n", .{v.*});
    } else {
        std.debug.print("null!\n", .{});
    }
}

pub fn main() void {
    var value: i32 = 47;
    var vptr1: ?*i32 = &value;
    var vptr2: ?*i32 = null;

    nullChoice(vptr1);
    nullChoice(vptr2);
}
```

## 元编程(A taste of metaprogramming)
元编程有几个核心概念：
- 类型在编译时(`compile-time`)是有效值
- 大部分运行时代码(`runtime code`)在编译时(`compile-time`)也能工作
- 结构体的成员在编译时按[鸭子类型](https://en.wikipedia.org/wiki/Duck_typing)推导
- 标准库提供了编译期反射工具

以下示例实现多重派发(`multiple dispatch`)，类似 `std.debug.print` 的实现方式：
```zig
const std = @import("std");

fn foo(x : anytype) @TypeOf(x) {
    // note that this if statement happens at compile-time, not runtime.
    if (@TypeOf(x) == i64) {
        return x + 2;
    } else {
        return 2 * x;
    }
}

pub fn main() void {
    var x: i64 = 47;
    var y: i32 = 47;

    std.debug.print("i64-foo: {}\n", .{foo(x)});
    std.debug.print("i32-foo: {}\n", .{foo(y)});
}
```

以下示例说明泛型(`generic types`)的使用方式：
```zig
const std = @import("std");

fn Vec2Of(comptime T: type) type {
    return struct{
        x: T,
        y: T
    };
}

const V2i64 = Vec2Of(i64);
const V2f64 = Vec2Of(f64);

pub fn main() void {
    var vi = V2i64{.x = 47, .y = 47};
    var vf = V2f64{.x = 47.0, .y = 47.0};
    
    std.debug.print("i64 vector: {}\n", .{vi});
    std.debug.print("f64 vector: {}\n", .{vf});
}
```

通过以上概念可以构建非常强大的泛型系统。

## 堆(The HEAP)
有许多和堆交互的方法，通常情况下都需要明确选择。它们都遵循以下模式：
- 创建分配器工厂(`Allocator factory`)结构体
- 检索由分配器工厂创建的`std.mem.Allocator`结构
- 使用`allloc/free`和`create/destroy`函数操作堆
- (optional) `deinit`分配器工厂

看上去很麻烦，但是：
- 这是为了增加使用堆的难度
- 这让任何调用堆(基本上是不必要的)的过程显而易见
- 仔细权衡并使用标准数据结构，而不是重写它们
- 可以在测试中使用一个非常安全的分配器，在发布阶段换成另外其它的

如果这阻止不了你，还是可以偷懒：
选择一个全局分配器，并且在任何地方复用它（注意：有些分配器不是线程安全的）。如果您正在编写通用库，请不要这么做。

在下面的示例中，我们使用 `std.heap.GeneralPurposeAllocator` 工厂创建一个有一堆功能（包括内存泄漏检测）的分配器，并看看它们是怎么被组合到一起的。
在这个例子中还使用到了 `defer` 关键字。还有一个 `errdefer` 关键字，详细信息请查看Zig文档。

```zig
const std = @import("std");

// factory type
const Gpa = std.heap.GeneralPurposeAllocator(.{});

pub fn main() !void {
    // instantiates the factory
    var gpa = Gpa{};

    // retrieves the created allocator.
    var galloc = gpa.allocator();

    // scopes the lifetime of the allocator to this function and
    // performs cleanup;
    defer _ = gpa.deinit();

    var slice = try galloc.alloc(i32, 2);
    // uncomment to remove memory leak warning
    // defer galloc.free(slice);

    var single = try galloc.create(i32);
    // defer galloc.destroy(single);

    slice[0] = 47;
    slice[1] = 48;
    single.* = 49;

    std.debug.print("slice: [{}, {}]\n", .{ slice[0], slice[1] });
    std.debug.print("single: {}\n", .{single.*});
}
```


## 结尾(Coda)
就是这些了，现在我们已经了解了相当有用的Zig知识。还有一些重要的知识点：
- 测试(`test`) Zig内置测试系统让测试变得轻松
- 标准库(`the standard library`)
- 内存模型(`memory model`)
- 异步(`async`)
- 交叉编译(`cross-compilation`)
- 构建文件(`build.zig`)

更多详情，请查看[文档](https://ziglang.org/documentation/master/)  
或者继续[学习](https://ziglearn.org/)
