# Zig 交叉编译 windows to arm

## 编译zig程序到arm

```shell
zig build-exe -target aarch64-linux -O ReleaseSmall test.zig 
```

## 编译cpp单文件到arm
```shell
zig c++ -std=c++20 test.cpp -target aarch64-linux -o a
```

有些modern c++特性不支持，比如format https://clang.llvm.org/cxx\_status.html

## 使用build.zig编译到arm

使用 `zig init-exe` 生成 build.zig, 修改内容如下：

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "zig-cmake-cpp",
        .root_source_file = .{ .path = "main.cpp" },
        .target = target,
        .optimize = optimize,
    });
    // exe.addCSourceFile("main.cpp", &[_][]const u8{"-std=c++20"});
    exe.linkSystemLibrary("c++");
    b.installArtifact(exe);
}
```

编译
```shell
zig build
or
zig build -Dtarget=aarch64-linux -Doptimize=ReleaseFast
```

Release 有链接错误

## 使用 cmake 编译到 arm
```shell
    cmake -B build-aarch64 -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/zig-toolchain-aarch64.cmake
    cmake --build build--arch64
```

zig-toolchain-aarch64.cmake
```cmake
    if(CMAKE_GENERATOR MATCHES "Visual Studio")
        message(FATAL_ERROR "Visual Studio generator not supported, use: cmake -G Ninja")
    endif()
    set(CMAKE_SYSTEM_NAME "Linux")
    set(CMAKE_SYSTEM_VERSION 1)
    set(CMAKE_SYSTEM_PROCESSOR "aarch64")
    set(CMAKE_C_COMPILER "zig" cc -target aarch64-linux-gnu)
    set(CMAKE_CXX_COMPILER "zig" c++ -target aarch64-linux-gnu)
    
    if(WIN32)
        set(SCRIPT_SUFFIX ".cmd")
    else()
        set(SCRIPT_SUFFIX ".sh")
    endif()
    
    # This is working (thanks to Simon for finding this trick)
    set(CMAKE_AR "${CMAKE_CURRENT_LIST_DIR}/zig-ar${SCRIPT_SUFFIX}")
    set(CMAKE_RANLIB "${CMAKE_CURRENT_LIST_DIR}/zig-ranlib${SCRIPT_SUFFIX}")
```

## 在 windows 上使用 cmake 编译

```shell
    cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/zig-toolchain.cmake
    cmake --build build
```

zig-toolchain.cmake
```cmake
    if(CMAKE_GENERATOR MATCHES "Visual Studio")
        message(FATAL_ERROR "Visual Studio generator not supported, use: cmake -G Ninja")
    endif()
    set(CMAKE_C_COMPILER "zig" cc)
    set(CMAKE_CXX_COMPILER "zig" c++)
    
    if(WIN32)
        set(SCRIPT_SUFFIX ".cmd")
    else()
        set(SCRIPT_SUFFIX ".sh")
    endif()
    
    # This is working (thanks to Simon for finding this trick)
    set(CMAKE_AR "${CMAKE_CURRENT_LIST_DIR}/zig-ar${SCRIPT_SUFFIX}")
    set(CMAKE_RANLIB "${CMAKE_CURRENT_LIST_DIR}/zig-ranlib${SCRIPT_SUFFIX}")
```

## 参考

*   https://gitlab.kitware.com/mrexodia/cmake-zig 
*   https://github.com/mrexodia/zig-cross
*   https://zig.news/xq/zig-build-explained-part-1-59lf
*   https://zig.news/xq/zig-build-explained-part-2-1850
*   https://zig.news/xq/zig-build-explained-part-3-1ima
*   https://zig.news/kristoff/compile-a-c-c-project-with-zig-368j
*   https://zig.news/kristoff/cross-compile-a-c-c-project-with-zig-3599
*   https://zig.news/kristoff/make-zig-your-c-c-build-system-28g5
*   https://zig.news/kristoff/extend-a-c-c-project-with-zig-55di