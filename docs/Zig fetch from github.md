

## [来源](https://course.ziglang.cc/advanced/package_management)

```
小技巧：如何直接使用指定分支的源码？

如果代码托管平台提供分支源码打包直接返回功能，就支持，例如 github 的源码分支打包返回的 url 格式为：

https://github.com/username/repo-name/archive/branch.tar.gz

其中的 username 就是组织名或者用户名，repo-name 就是对应的仓库名，branch 就是分支名。

例如 https://github.com/limine-bootloader/limine-zig/archive/trunk.tar.gz 就是获取 limine-zig 这个包的主分支源码打包。

```


使用
```
zit fetch https://$github.url$/archive/branch.tar.gz --save
```