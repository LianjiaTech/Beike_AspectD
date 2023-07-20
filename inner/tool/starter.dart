import 'package:args/args.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:path/path.dart' as p;

import '../transformer/plugins/aop/transformer/aop_tranform_utils.dart' show AopUtils;
import '../transformer/transformer_wrapper.dart';
import '../util/dill_ops.dart';

const String _kOptionInput = 'input';
const String _kOptionOutput = 'output';
const String _kOptionSdkRoot = 'sdk-root';
const String _kOptionMode = 'mode';
Map<String, Library> libraryAbbrMap = <String, Library>{};
Map<String, Class> classAbbrMap = <String, Class>{};
Map<String, CanonicalName> canonicalMap = <String, CanonicalName>{};

int main(List<String> args) {
  final ArgParser parser = ArgParser()
    ..addOption(_kOptionInput, help: 'Input dill file')
    ..addOption(_kOptionOutput, help: 'Output dill file')
    ..addOption(_kOptionSdkRoot, help: 'Sdk root path')
    ..addOption(_kOptionMode, help: 'Transformer mode, flutter as default');
  final ArgResults argResults = parser.parse(args);
  final String intputDill = argResults[_kOptionInput];
  final String outputDill = argResults[_kOptionOutput];
  final String sdkRoot = argResults[_kOptionSdkRoot];

  final DillOps dillOps = DillOps();
  final Component component = dillOps.readComponentFromDill(intputDill);
  late Component platformStrongComponent;
  if (sdkRoot != null) {
    platformStrongComponent =
        dillOps.readComponentFromDill(p.join(sdkRoot, 'platform_strong.dill'));
    for (Library library in platformStrongComponent.libraries) {
      libraryAbbrMap.putIfAbsent(library.name!, () => library.reference.node! as Library);

      for (Class clazz in library.classes) {
        classAbbrMap.putIfAbsent(library.name! + '.' + clazz.name,
            () => clazz.reference.node as Class);
      }
    }

    for (CanonicalName canonicalName in platformStrongComponent.root.children) {
      canonicalMap.putIfAbsent(canonicalName.name, () => canonicalName);
    }
  }
//
//  if (AopUtils.isDartMode) {
//    completeDartComponent(component);
//  }

  var children = component.root.children;
  final List<String> childrenToExchange = <String>[];

  for (CanonicalName canonicalName in children) {
    if (canonicalMap[canonicalName.name] != null) {
      childrenToExchange.add(canonicalName.name);
    }

    Library? library = libraryAbbrMap[canonicalName.name];
    CanonicalName canonical = canonicalMap[canonicalName.name] as CanonicalName;
    library ??= libraryAbbrMap[canonicalName.name.replaceAll(':', '.')];
    if (canonicalName.reference == null) {
      // canonicalName.reference = Reference()..node = library;
    } else if (canonicalName.reference.canonicalName != null &&
        canonicalName.reference.node == null) {
      canonicalName.reference.node = library;
    }

//    if(library == null) {
//
//      continue;
//    }
//
//    for(CanonicalName subCanonicalName in canonicalName.children) {
//
//      final String name = subCanonicalName.parent.name + '.' + subCanonicalName.name;
//      final Class clazz = classAbbrMap[name];
//
//      if (subCanonicalName.reference == null) {
//        subCanonicalName.reference = Reference()..node = clazz;
//      } else if (subCanonicalName.reference.canonicalName != null &&
//          subCanonicalName.reference.node == null) {
//        subCanonicalName.reference.node = clazz;
//      }
//    }
  }

//  for (Library library in component.libraries) {
//    List<LibraryDependency> dependencies = library.dependencies;
//
//    for (LibraryDependency dependency in dependencies) {
//      final String libName =
//          dependency.importedLibraryReference.canonicalName.name.replaceAll(':', '.');
//
//      if (libraryAbbrMap[libName] != null) {
//        dependency.importedLibraryReference.node = libraryAbbrMap[libName];
//      }
//    }
//  }
//
//  for (String name in childrenToExchange) {
//    component.root.removeChild(name);
//    component.root.adoptChild(canonicalMap[name]);
//  }
//  component.adoptChildren();

  final TransformerWrapper transformerWrapper =
      TransformerWrapper(platformStrongComponent);
  transformerWrapper.transform(component);

  dillOps.writeDillFile(component, outputDill);
  return 0;
}

void completeDartComponent(Component component) {
  final Map<String, Library> componentLibraryMap = <String, Library>{};
  for (Library library in component.libraries) {
    componentLibraryMap.putIfAbsent(
        library.importUri.toString(), () => library);
  }
  for (CanonicalName canonicalName
      in List<CanonicalName>.from(component.root.children.toList())) {
    if (!componentLibraryMap.containsKey(canonicalName.name)) {
      Library? library = libraryAbbrMap[canonicalName.name];
      library ??= libraryAbbrMap[canonicalName.name.replaceAll(':', '.')];
      component.root.removeChild(canonicalName.name);
      component.libraries.add(library!);
    }
  }
  component.adoptChildren();
}
