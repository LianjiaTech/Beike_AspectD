Language:  中文简体 | [English](README.md)

# Beike_AspectD
This is a fork of [AspectD](https://github.com/XianyuTech/aspectd).

Beike_AspectD是一个dart面向切面库。闲鱼的AspectD为开发者提供了call/execute/inject三种方式对代码进行操作。除此之外，Beike_AspectD还提供了：

- ✅  Add语法支持为class添加方法；
- ✅  FieldGet语法支持更换变量获取；
- ✅  支持空安全。（null-safety下的分支）
- ✅  支持Flutter for Web；
- ✅  其他的一些问题修复.

# Beike_AspectD有哪些应用场景?
贝壳已经在一些库中使用Beike_AspectD.
- 埋点库
- Json模型转换
- 性能监控
- Flutter框架问题修复等

# 安装

## 1. Apply flutter_tools.patch.
```shell
cd ...path/to/flutter
git apply --3way path-for-beike_aspectd-package/inner/flutter_tools.patch
rm bin/cache/flutter_tools.stamp
```
当下次编译你的Flutter工程时，flutter tools就会重新build。

## 2. 添加Beike_AspectD依赖.
```dart
dependencies:
  beike_aspectd:
    git:
        url: https://github.com/LianjiaTech/Beike_AspectD.git
        ref: 2.5.3
```

## 3. 将aop_config.yaml添加到你的工程.
在你的工程根目录下添加一个aop_config.yaml文件(和pubspec.yaml同一级).

你也可以复制Beike_AspectD工程中example目录下的这个文件.
aop_config.yaml的内容如下
```dart
flutter_tools_hook:
  - project_name: 'beike_aspectd'
    exec_path: 'bin/starter.snapshot'
```
我们修改过的Flutter_tools将会检查这个文件来判断Beike_AspectD是否生效。

## 4. 添加hook代码.
hook_example.dart(aop implementation)

```dart
import 'package:beike_aspectd/aspectd.dart';

@Aspect()
@pragma("vm:entry-point")
class CallDemo {
  @pragma("vm:entry-point")
  CallDemo();

 //实例方法
 @Call("package:example/main.dart", "_MyHomePageState",
     "-_incrementCounter")
 @pragma("vm:entry-point")
 void _incrementCounter4(PointCut pointcut) {
   print('call instance method2!');
   pointcut.proceed();
 }
}
```
由于hook_example.dart没有在项目中使用，我们应该在工程中引用这个文件，以免被编译器tree shake优化掉。

比如，我们可以在 main.dart引用.
```dart
// ignore: unused_import
import 'package:example/hook_example.dart';
```

# 使用

除了支持AspectD支持的call/execute/inject三种方式外，Beike_AspectD还提供了add/field get两种操作。

## add
为一个类添加方法，支持正则匹配，支持对父类进行筛选.
```dart
  @Add("package:.+\\.dart", ".*", isRegex: true)
  @pragma("vm:entry-point")
  dynamic getBasicInfo(PointCut pointCut) {
    return pointCut?.sourceInfos ?? {};
  }
```

上面的代码为所有的类添加了getBasicInfo()这个方法，你也可以增加正则表达式或者父类参数来过滤需要添加方法的类。

可以通过以下代码调用添加的方法。
```dart
    dynamic instance = someinstance;
    Map info = instance.getBasicInfo(PointCut.pointCut());
```

## field get
Field get可以被用来替换对于某个属性的调用.

```dart
 @pragma("vm:entry-point")
 @FieldGet('package:example/main.dart', 'MyApp', 'field', false)
 static String exchange(PointCut pointCut) {
    return 'Beike_Aspect';
}
```
比如，MyApp有个属性field，通过上面代码，调用MyApp中field属性的地方都会返回字符串'Beike_AspectD'。

## 版本支持
目前Beike_AspectD已经支持Flutter 1.22.4，2.2.2和2.5.3.

## 如何调试
见[调试](doc/如何调试.md)

## 常见问题
- 如何知道我的hook代码是否生效?
  1. 首先需要下载Flutter对于的dart sdk。Dart sdk的revision可以在path_to_flutter/bin/cache/dart-sdk/revision文件中找到。
  2. 执行下面脚本：
    ```dart
    path_to_flutter/bin/cache/dart-sdk/bin/dart  path_to_dart/pkg/vm/bin/dump_kernel.dart path_to_your_project/.dart_tool/flutter_build/***/app.dill output_path/out.dill.txt
    ```
  3. 打开 output_path/out.dill.txt文件, 找到你hook的方法，确认是否被替换.

# 联系

如果你有任何问题，可以提一个issue。或者联系xiaopeng015@ke.com。
