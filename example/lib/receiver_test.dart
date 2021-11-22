class Receiver {

  final int j;

  Receiver({this.j = 25});

  static void tap() {
    
  }

   void receiveTapped(int i, {int j}) {
    print('[KWLM]:onPluginDemo111 Called!');
  }
}


class Receiver2 extends Receiver {

}

class Receiver3 extends Receiver2 {

}

class Receiver4 {

}