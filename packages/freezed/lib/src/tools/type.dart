import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import 'imports.dart';

extension DartTypeX on DartType {
  bool get isNullable {
    final that = this;
    if (that is TypeParameterType) {
      return that.bound.isNullable;
    }
    return isDynamic || nullabilitySuffix == NullabilitySuffix.question;
  }
}

/// Renders a type based on its string + potential import alias
String resolveFullTypeStringFrom(
  LibraryElement originLibrary,
  DartType type, {
  required bool withNullability,
}) {
  String buildType(String name, List<DartType> typeArguments) {
    if (typeArguments.isNotEmpty) {
      name += '<${typeArguments.map(
            (t) => resolveFullTypeStringFrom(
              originLibrary,
              t,
              withNullability: withNullability,
            ),
          ).join(', ')}>';
    }
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      name += '?';
    }

    return name;
  }

  // The parameter is a typedef in the form of
  // SomeTypedef typedef
  //
  // In this case the analyzer would expand that typedef using getDisplayString
  // For example for:
  //
  // typedef SomeTypedef = Function(String);
  //
  // it would generate:
  // 'dynamic Function(String)'
  //
  // Instead of 'SomeTypedef'
  final String displayType;
  final int? libraryId;
  if (type.alias?.element != null) {
    final alias = type.alias!;
    final element = alias.element;
    displayType = buildType(element.name, alias.typeArguments);
    libraryId = element.library.id;
  } else if (type is InterfaceType) {
    final element = type.element;
    displayType = buildType(element.name, type.typeArguments);
    libraryId = element.library.id;
  } else {
    displayType = type.getDisplayString(withNullability: withNullability);
    libraryId = null;
  }

  final owner = originLibrary.prefixes.firstWhereOrNull(
    (e) {
      return e.imports.any((l) {
        return l.importedLibrary!.anyTransitiveExport((library) {
          return library.id == libraryId;
        });
      });
    },
  );

  if (owner != null) {
    return '${owner.name}.$displayType';
  }

  return displayType;
}
