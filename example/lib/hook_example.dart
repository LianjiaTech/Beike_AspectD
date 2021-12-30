import 'package:beike_aspectd/aspectd.dart';

@Aspect()
@pragma("vm:entry-point")
class FieldGetDemo {
  // @pragma("vm:entry-point")
  // @FieldGet('dart:io', 'Platform', 'isAndroid', true)
  // static bool exchange(PointCut pointCut) {
  //   //origin call
  //   return true;
  // }

  @pragma("vm:entry-point")
  @FieldGet('package:example/main.dart', '_MyHomePageState', 's', false)
  static String exchange2(PointCut pointCut) {
    //origin call
    return '[beike_aspectd]:Exchanged field';
  }
}

@Aspect()
@pragma("vm:entry-point")
class CallDemo {
  @pragma("vm:entry-point")
  CallDemo();

//实例方法
  @Call("package:example/main.dart", "_MyHomePageState", "-_incrementCounter")
  @pragma("vm:entry-point")
  void _incrementCounter4(PointCut pointcut) {
    print('[beike_aspectd]: call instance method2!');
    pointcut.proceed();
  }

// //类静态方法
// @Call("package:example/main.dart", "_MyHomePageState", "+testFunction")
// @pragma("vm:entry-point")
// static void appInit(PointCut pointcut) {
//   print('[beike_aspectd]: call static method!');
//   pointcut.proceed();
// }

// //构造方法
// @Call("package:example/receiver_test.dart", "Receiver", "+Receiver")
// @pragma("vm:entry-point")
// dynamic receiveTapped(PointCut pointcut) {
//   dynamic obj = pointcut.proceed();
//   print('[beike_aspectd]: call constructor method!');
//   pointcut.proceed();
//   return obj;
// }

// //库静态方法
// @Call("package:example/main.dart", "", "+injectDemo")
// @pragma("vm:entry-point")
// static void injectDemo(PointCut pointcut) {
//   print('[beike_aspectd]: call library static method!');
//   pointcut.proceed();
// }
}

@Aspect()
@pragma("vm:entry-point")
class RegexCallDemo {
  @pragma("vm:entry-point")
  RegexCallDemo();

// //实例方法
// @Call("package:example/main.dart", "_MyHomePageState",
//     "-.*", isRegex: true)
// @pragma("vm:entry-point")
// dynamic _incrementCounter(PointCut pointcut) {
//   print('[beike_aspectd]: regex call hook instance method!');
//   return pointcut.proceed();
// }

// //类静态方法
// @Call("package:example/main.dart", "_MyHomePageState", "+.*", isRegex: true)
// @pragma("vm:entry-point")
// static dynamic appInit(PointCut pointcut) {
//   print('[beike_aspectd]: regex call static method!');
//   return pointcut.proceed();
// }

// //构造方法
// @Call("package:example/receiver_test.dart", "Receiver", "+.*", isRegex: true)
// @pragma("vm:entry-point")
// dynamic receiveTapped(PointCut pointcut) {
//   dynamic obj = pointcut.proceed();
//   print('[beike_aspectd]: regex call constructor method!');
//   pointcut.proceed();
//   return obj;
// }

// //库静态方法
// @Call("package:example/main.dart", "", "+.*", isRegex: true)
// @pragma("vm:entry-point")
// static dynamic injectDemo(PointCut pointcut) {
//   print('[beike_aspectd]: regex call library static method!');
//   return pointcut.proceed();
// }
}

@Aspect()
@pragma("vm:entry-point")
class ExecuteDemo {
  @pragma("vm:entry-point")
  ExecuteDemo();

//实例方法
//   @Execute(
//       "package:example/main.dart", "_MyHomePageState", "-_incrementCounter")
//   @pragma("vm:entry-point")
//   void _incrementCounter(PointCut pointcut) {
//     print('[beike_aspectd]: Execute instance method!');
//     pointcut.proceed();
//   }

// //类静态方法
// @Execute("package:example/receiver_test.dart", "Receiver", "+tap")
// @pragma("vm:entry-point")
// static dynamic tap(PointCut pointcut) {
//   print('[beike_aspectd]: Execute static method!');
//   pointcut.proceed();
// }

// //构造方法
// @Execute("package:example/receiver_test.dart", "Receiver", "+Receiver")
// @pragma("vm:entry-point")
// dynamic receiveTapped(PointCut pointcut) {
//   dynamic obj = pointcut.proceed();
//   print('[beike_aspectd]: Execute constructor method!');
//   pointcut.proceed();
//   return obj;
// }

// //库静态方法
// @Execute("package:example/main.dart", "", "+injectDemo")
// @pragma("vm:entry-point")
// static void injectDemo(PointCut pointcut) {
//   print('[beike_aspectd]: Execute library static method!');
//   pointcut.proceed();
// }
}

@Aspect()
@pragma("vm:entry-point")
class RegularExecuteDemo {
  RegularExecuteDemo();

// //实例方法
//   @Execute("package:example/main.dart", "_MyHomePageState", "-.*",
//       isRegex: true)
//   @pragma("vm:entry-point")
//   dynamic _incrementCounter(PointCut pointcut) {
//     print('[beike_aspectd]: regex execute hook instance method!');
//     return pointcut.proceed();
//   }

// //类静态方法
// @Execute("package:example/main.dart", "_MyHomePageState", "+.*", isRegex: true)
// @pragma("vm:entry-point")
// dynamic  appInit(PointCut pointcut) {
//   print('[beike_aspectd]: regex execute static method!');
//   return pointcut.proceed();
// }

// //构造方法
// @Execute("package:example/receiver_test.dart", "Receiver", "+.*", isRegex: true)
// @pragma("vm:entry-point")
// dynamic receiveTapped(PointCut pointcut) {
//   dynamic obj = pointcut.proceed();
//   print('[beike_aspectd]: regex execute constructor method!');
//   pointcut.proceed();
//   return obj;
// }

// //库静态方法
// @Execute("package:example/main.dart", "", "+.*", isRegex: true)
// @pragma("vm:entry-point")
// static dynamic injectDemo(PointCut pointcut) {
//   print('[beike_aspectd]: regex execute library static method!');
//   return pointcut.proceed();
// }
}

@Aspect()
@pragma("vm:entry-point")
class InjectDemo {
  InjectDemo();

//实例方法
  @Inject("package:example/main.dart", "_MyHomePageState", "-onPluginDemo",
      lineNum: 104)
  @pragma("vm:entry-point")
  void onPluginDemo(PointCut pointcut) {
    Object p = Object(); //Aspectd Ignore

    print('[beike_aspectd]:Inject instance method!');
    // Object bo; //Aspectd Ignore
    print(p);
  }

// //类静态方法
// @Inject("package:example/receiver_test.dart", "Receiver", "+tap",
//     lineNum: 8)
// @pragma("vm:entry-point")
// static dynamic tap(PointCut pointcut) {
//   print('Inject static method!');
//   Object instance; //Aspectd Ignore
//   Object context; //Aspectd Ignore
//   print(instance);
//   print(context);
// }

// //构造方法
// @Inject("package:example/receiver_test.dart", "Receiver", "+Receiver",
//     lineNum: 5)
// @pragma("vm:entry-point")
// dynamic receiveTapped(PointCut pointcut) {
//   dynamic obj = pointcut.proceed();
//   print('Inject constructor method!');
//   Object instance; //Aspectd Ignore
//   Object context; //Aspectd Ignore
//   print(instance);
//   print(context);
// }

// //库静态方法
// @Inject("package:example/main.dart", "", "+injectDemo", lineNum: 23)
// @pragma("vm:entry-point")
// static void injectDemo(PointCut pointcut) {
//   print('Inject library static method!');
//   Object instance; //Aspectd Ignore
//   Object context; //Aspectd Ignore
//   print(instance);
//   print(context);
// }
}

@Aspect()
@pragma("vm:entry-point")
class InjectSameLineDemo {
  InjectSameLineDemo();

//  @Inject("package:flutter/src/material/page.dart","MaterialPageRoute","-buildPage", lineNum:87)
//  @pragma("vm:entry-point")
//  void routeAfterPage() {
//
//    {
//
//      print("----Hook buildPage 87----");
//    }
//
//
//  }
//
//  @Inject("package:flutter/src/material/page.dart","MaterialPageRoute","-buildPage", lineNum:87)
//  @pragma("vm:entry-point")
//  void routeBeforePage() {
//
//    {
//      dynamic self = this;
//      print(self);
//      print("----Hook buildPage 87----");
//    }
//  }
//
//  @Inject("package:flutter/src/material/page.dart","MaterialPageRoute","-buildPage", lineNum:87)
//  @pragma("vm:entry-point")
//  void routeAfterPage2() {
//
//    {
//
//      print("----Hook buildPage 87----");
//    }
//
//
//  }
//
//  @Inject("package:flutter/src/material/page.dart","MaterialPageRoute","-buildPage", lineNum:88)
//  @pragma("vm:entry-point")
//  void routeAfterPage3() {
//    print("----Hook buildPage 88----");
//  }
}

@Aspect()
@pragma("vm:entry-point")
class AddDemo {
  @pragma("vm:entry-point")
  AddDemo();

  @Add("package:example/receiver_test.dart", "Receiver")
  @pragma("vm:entry-point")
  dynamic addTest(PointCut pointCut, int j, {String? s, int? i}) {
    print('[beike_aspectd]: Add method');
  }

// @Add("package:example\\/.+\\.dart", ".*", isRegex: true)
// @pragma("vm:entry-point")
// void addTestRegular(PointCut pointCut) {
//   print('Regular add method');
// }

}

@Aspect()
@pragma("vm:entry-point")
class RegexFilterSuperAddDemo {
  @pragma("vm:entry-point")
  RegexFilterSuperAddDemo();

// @Add("package:example\\/.+\\.dart", ".*", isRegex: true, superCls: 'Widget')
// @pragma("vm:entry-point")
// void addTestRegularFilterSuper(PointCut pointCut) {
//   print('[beike_aspectd]: Regular add method filter super');
// }
}
