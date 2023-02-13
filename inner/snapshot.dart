import 'dart:io';

void main(List<String> args) async {
  final String dartPath = Platform.executable;

  List<String> command = <String>[
    '--snapshot=../lib/bin/starter.snapshot',
    'tool/starter.dart'
  ];

  print('Start generating starter.snapshot...');
  Process result = await Process.start(dartPath, command);

  stdout.addStream(result.stdout);
  stderr.addStream(result.stderr);

  if (await result.exitCode == 0) {
    print('Generated starter.snapshot successfully!');
  } else {
    print('Failed t0 generate starter.snapshot!');
  }

  command = <String>[
    '--deterministic',
    '--snapshot=flutter_frontend_server/frontend_server.dart.snapshot',
    'flutter_frontend_server/starter.dart'
  ];

  print('Start generating frontend_server.dart.snapshot...');

  result = await Process.start(dartPath, command);

  if (await result.exitCode == 0) {
    print('Generated frontend_server.dart.snapshot successfully!');
  } else {
    print('Failed t0 generate frontend_server.dart.snapshot!');
  }

  stdout.addStream(result.stdout);
  stderr.addStream(result.stderr);
}
