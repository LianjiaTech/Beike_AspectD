# Flutter版本适配流程
## 依赖下载
首先，我们需要下载Flutter和Dart的代码。

以3.7.2版本为例，下载完Flutter版本以后可以找到Flutter版本对应的Dart，对应的版本号可以在``flutter/bin/cache/dart-sdk/version``文件中找到，或者也可以参考[Flutter Releases官方网站](https://docs.flutter.dev/development/tools/sdk/releases?tab=macos)。这里需要注意的是，如果Dart版本一致的话，Beike_AspectD是通用的，比如Flutter 3.7.5/3.7.4/3.7.3/3.7.2用的都是Dart 2.19.2版本，那么这些版本只需要适配一次。

## 更换Dart SDK依赖文件
下载完成Dart SDK之后，我们需要将``beike_aspectd/inner/pkg``下所有文件替换为``dart-sdk/pkg``目录下对应的文件。

## 修改Dart源码
由于Beike_AspectD流程涉及到前端编译，我们需要对Dart源码进行少量修改，修改的文件位置在``beike_aspectd/inner/pkg/vm/lib/target/flutter.dart ``，修改的内容可参考老版本。

## 更新flutter_tools
由于Beike_AspectD的注入依赖flutter_tools，所以我们要适配flutter_tools。flutter_tools在``flutter/packages/flutter_tools``目录下，具体修改内容可参考老版本的修改。修改完代码后，我们需要通过删除``flutter/bin/cache/flutter_tools.stamp``这个文件来重新生成flutter_tools的快照。

为了让其他开发者更快地适配flutter_tools，我们可以将flutter_tools的修改生成patch文件。首先，我们需要提交对flutter_tools的修改，然后通过`` git format-patch xxxxx``命令生成patch文件，其中xxxxx为Flutter官方最后一个commit id。生成的patch文件将``beike_aspectd/inner/flutter_tools.patch ``替换即可。

## 生成快照
进入到``beike_aspectd/inner``目录下执行``flutter pub get``。然后进入到``beike_aspectd/inner/flutter_frontend_server``目录下执行``sh gen_frontend_server_snapshot.sh``命令。

## 检查是否适配完成
通过以上步骤即完成了Beike_AspectD新版本的适配，可以通过运行起example工程查看log输出来确认是否完成适配。
