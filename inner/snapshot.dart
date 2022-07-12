import 'dart:io';

void main(List<String> args) async {

  final String dartPath = Platform.executable;

  List<String> command = <String>['--snapshot=../lib/bin/starter.snapshot', 'tool/starter.dart'];


  Process result = await Process.start(
    dartPath,
    command

  );

  command = <String>['--deterministic', '--snapshot=flutter_frontend_server/frontend_server.dart.snapshot', 'flutter_frontend_server/starter.dart'];

  result = await Process.start(
      dartPath,
      command
  );
}