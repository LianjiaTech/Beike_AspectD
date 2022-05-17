Language: English | [中文简体](README-CN.md)

# Beike_AspectD
This is a fork of [AspectD](https://github.com/XianyuTech/aspectd).

Beike_AspectD is an aop framework for dart. AspectD has provide developers call/execute/inject grammer to manipulate the dart code. Besides that,  Beike_AspectD also provides

- ✅  Support add grammer to add function to classes.
- ✅  Support field get grammer to exchange the field get call.
- ✅  Support null-safety(null-safety/2.5.3 branch).
- ✅  Support flutter web.

# What can we use Beike_AspectD for?
Beike has used Beike_AspectD in many packages.
- Event tracking.
- Json to model.
- Performance monitoring.
- Flutter framework bug fixing.

# Installation

## 1. Apply flutter_tools.patch.
```shell
cd ...path/to/flutter/packages/flutter_tools/
git apply --3way path-for-beike_aspectd-package/inner/flutter_tools.patch
rm ../../bin/cache/flutter_tools.stamp
```
Next time when you build your project, flutter tools will build automatically.

## 2. Add Beike_AspectD to your yaml.
```dart
dependencies:
   beike_aspectd:
     git:
         url: https://github.com/LianjiaTech/Beike_AspectD.git
         ref: 3.0.0
```

## 3. Add aop_config.yaml to your flutter project.
Add a file named aop_config.yaml to your flutter project's root directory(the same directory as pubspec.yaml).

You can copy the file from the example of Beike_AspectD.
The content of the file are as follow
```dart
flutter_tools_hook:
  - project_name: 'beike_aspectd'
    exec_path: 'bin/starter.snapshot'
```
Flutter_tools will check the file to find if Beike_AspectD is enabled. And it will get the starter.snapshot to process the dill file.

## 4. Write your hook file and import the file.
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
As hook_example.dart is not used in your project, we should import it in the project, or it will be tree shaked while compiling.

For example, we can import the file in main.dart.
```dart
// ignore: unused_import
import 'package:example/hook_example.dart';
```

# Tutorial

In addition to the 3 ways(call/execute/inject) to do AOP programming AspectD provide us, Beike_AspectD also provide add/field get manipulation.

## add
Add a method to a class, support class name regex, support super class filter.
```dart
  @Add("package:.+\\.dart", ".*", isRegex: true)
  @pragma("vm:entry-point")
  dynamic getBasicInfo(PointCut pointCut) {
    return pointCut?.sourceInfos ?? {};
  }
```
Code above add getBasicInfo() method to all the classes, you can use your own regex and  superCls parameter to filter classes.
We can call the function using the following code.
```dart
    dynamic self = someinstance;
    Map info = self.getBasicInfo(PointCut.pointCut());
```

## field get
Every callsites of the a field will be manipulated.

```dart
 @pragma("vm:entry-point")
 @FieldGet('package:example/main.dart', 'MyApp', 'field', false)
 static String exchange2(PointCut pointCut) {
    return 'Beike_Aspectd';
}
```
Suppose MyApp class has a property called field, by using the the above code, when calling the property field, it will always return string 'Beike_Aspectd'.

# Compatibility
Currently Beike_Aspectd support flutter 1.22.4 ，2.2.2, 2.5.3, 2.10.4 and 3.0.0.

## Q&A
- How to know if my code is hooked successfully?
  1. First you need to download the dart-sdk and checkout to the corresponding revision of flutter. The revision of dart can be found at path_to_flutter/bin/cache/dart-sdk/revision.
  2. Run the following command.
    ```dart
    path_to_flutter/bin/cache/dart-sdk/bin/dart  path_to_dart/pkg/vm/bin/dump_kernel.dart path_to_your_project/.dart_tool/flutter_build/***/app.dill output_path/out.dill.txt
    ```
  3. Open output_path/out.dill.txt file, check if your code is hook.

# Contact

If you have any question, please feel free to file a issue.
