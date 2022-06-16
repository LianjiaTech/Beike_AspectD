// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:dart_style/dart_style.dart' show DartFormatter;
import '../../test/utils/io_utils.dart' show computeRepoDirUri;

main(List<String> args) {
  final Uri repoDir = computeRepoDirUri();
  String generated = generateAstHelper(repoDir);
  new File.fromUri(computeAstHelperUri(repoDir))
      .writeAsStringSync(generated, flush: true);
}

Uri computeAstHelperUri(Uri repoDir) {
  return repoDir.resolve(
      "pkg/front_end/lib/src/fasta/util/direct_parser_ast_helper.dart");
}

String generateAstHelper(Uri repoDir) {
  StringBuffer out = new StringBuffer();
  File f = new File.fromUri(
      repoDir.resolve("pkg/_fe_analyzer_shared/lib/src/parser/listener.dart"));
  List<int> rawBytes = f.readAsBytesSync();

  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  Utf8BytesScanner scanner = new Utf8BytesScanner(bytes, includeComments: true);
  Token firstToken = scanner.tokenize();

  out.write(r"""
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/assert.dart';
import 'package:_fe_analyzer_shared/src/parser/block_kind.dart';
import 'package:_fe_analyzer_shared/src/parser/declaration_kind.dart';
import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/parser/identifier_context.dart';
import 'package:_fe_analyzer_shared/src/parser/listener.dart';
import 'package:_fe_analyzer_shared/src/parser/member_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/error_token.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/fasta/messages.dart';

// ignore_for_file: lines_longer_than_80_chars

// THIS FILE IS AUTO GENERATED BY
// 'tool/_fasta/direct_parser_ast_helper_creator.dart'
// Run this command to update it:
// 'dart pkg/front_end/tool/_fasta/direct_parser_ast_helper_creator.dart'

abstract class DirectParserASTContent {
  final String what;
  final DirectParserASTType type;
  Map<String, Object?> get deprecatedArguments;
  List<DirectParserASTContent>? children;

  DirectParserASTContent(this.what, this.type);

  // TODO(jensj): Compare two ASTs.
}

enum DirectParserASTType { BEGIN, END, HANDLE }

abstract class AbstractDirectParserASTListener implements Listener {
  List<DirectParserASTContent> data = [];

  void seen(DirectParserASTContent entry);

""");

  ParserCreatorListener listener = new ParserCreatorListener(out);
  ClassMemberParser parser = new ClassMemberParser(listener);
  parser.parseUnit(firstToken);

  out.writeln("}");
  out.writeln("");
  out.write(listener.newClasses.toString());

  return new DartFormatter().format("$out");
}

class ParserCreatorListener extends Listener {
  final StringSink out;
  bool insideListenerClass = false;
  String? currentMethodName;
  String? latestSeenParameterTypeToken;
  String? latestSeenParameterTypeTokenQuestion;
  final List<Parameter> parameters = <Parameter>[];
  final StringBuffer newClasses = new StringBuffer();

  ParserCreatorListener(this.out);

  void beginClassDeclaration(Token begin, Token? abstractToken, Token name) {
    if (name.lexeme == "Listener") insideListenerClass = true;
  }

  void endClassDeclaration(Token beginToken, Token endToken) {
    insideListenerClass = false;
  }

  void beginMethod(
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? varFinalOrConst,
      Token? getOrSet,
      Token name) {
    currentMethodName = name.lexeme;
  }

  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    void end() {
      parameters.clear();
      currentMethodName = null;
    }

    if (insideListenerClass &&
        (currentMethodName!.startsWith("begin") ||
            currentMethodName!.startsWith("end") ||
            currentMethodName!.startsWith("handle"))) {
      StringBuffer sb = new StringBuffer();
      sb.write("  ");
      Token token = beginToken;
      Token? latestToken;
      while (true) {
        if (latestToken != null && latestToken.charEnd < token.charOffset) {
          sb.write(" ");
        }
        sb.write(token.lexeme);
        if ((token is BeginToken &&
                token.type == TokenType.OPEN_CURLY_BRACKET) ||
            token is SimpleToken && token.type == TokenType.FUNCTION) {
          break;
        }
        if (token == endToken) {
          throw token.runtimeType;
        }
        latestToken = token;
        token = token.next!;
      }

      if (token is SimpleToken && token.type == TokenType.FUNCTION) {
        return end();
      } else {
        sb.write("\n    ");
        String typeString;
        String typeStringCamel;
        String name;
        if (currentMethodName!.startsWith("begin")) {
          typeString = "BEGIN";
          typeStringCamel = "Begin";
          name = currentMethodName!.substring("begin".length);
        } else if (currentMethodName!.startsWith("end")) {
          typeString = "END";
          typeStringCamel = "End";
          name = currentMethodName!.substring("end".length);
        } else if (currentMethodName!.startsWith("handle")) {
          typeString = "HANDLE";
          typeStringCamel = "Handle";
          name = currentMethodName!.substring("handle".length);
        } else {
          throw "Unexpected.";
        }

        String className = "DirectParserASTContent${name}${typeStringCamel}";
        sb.write("$className data = new $className(");
        sb.write("DirectParserASTType.");
        sb.write(typeString);
        for (int i = 0; i < parameters.length; i++) {
          Parameter param = parameters[i];
          sb.write(', ');
          sb.write(param.name);
          sb.write(': ');
          sb.write(param.name);
        }

        sb.write(");");
        sb.write("\n    ");
        sb.write("seen(data);");
        sb.write("\n  ");

        newClasses
            .write("class DirectParserASTContent${name}${typeStringCamel} "
                "extends DirectParserASTContent {\n");

        for (int i = 0; i < parameters.length; i++) {
          Parameter param = parameters[i];
          newClasses.write("  final ");
          newClasses.write(param.type);
          newClasses.write(param.hasQuestion ? '?' : '');
          newClasses.write(' ');
          newClasses.write(param.name);
          newClasses.write(';\n');
        }
        newClasses.write('\n');
        newClasses.write("  DirectParserASTContent${name}${typeStringCamel}"
            "(DirectParserASTType type");
        String separator = ", {";
        for (int i = 0; i < parameters.length; i++) {
          Parameter param = parameters[i];
          newClasses.write(separator);
          if (!param.hasQuestion) {
            newClasses.write('required ');
          }
          newClasses.write('this.');
          newClasses.write(param.name);
          separator = ", ";
        }
        if (parameters.isNotEmpty) {
          newClasses.write('}');
        }
        newClasses.write(') : super("$name", type);\n\n');
        newClasses.write("Map<String, Object?> get deprecatedArguments => {");
        for (int i = 0; i < parameters.length; i++) {
          Parameter param = parameters[i];
          newClasses.write('"');
          newClasses.write(param.name);
          newClasses.write('": ');
          newClasses.write(param.name);
          newClasses.write(',');
        }
        newClasses.write("};\n");
        newClasses.write("}\n");
      }

      sb.write("}");
      sb.write("\n\n");

      out.write(sb.toString());
    }
    end();
  }

  @override
  void handleNoType(Token lastConsumed) {
    latestSeenParameterTypeToken = null;
    latestSeenParameterTypeTokenQuestion = null;
  }

  void handleType(Token beginToken, Token? questionMark) {
    latestSeenParameterTypeToken = beginToken.lexeme;
    latestSeenParameterTypeTokenQuestion = questionMark?.lexeme;
  }

  void endFormalParameter(
      Token? thisKeyword,
      Token? periodAfterThis,
      Token nameToken,
      Token? initializerStart,
      Token? initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    parameters.add(new Parameter(
        nameToken.lexeme,
        latestSeenParameterTypeToken ?? 'dynamic',
        latestSeenParameterTypeTokenQuestion == null ? false : true));
  }
}

class Parameter {
  final String name;
  final String type;
  final bool hasQuestion;

  Parameter(this.name, this.type, this.hasQuestion);
}