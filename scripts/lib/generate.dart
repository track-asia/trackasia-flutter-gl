import 'dart:io';
import 'dart:convert';

import 'package:mustache_template/mustache_template.dart';
import 'package:recase/recase.dart';

import 'conversions.dart';

main() async {
  final currentPath = Directory.current.path;
  final styleFilePath = '$currentPath/input/style.json';
  final styleJson = jsonDecode(await File(styleFilePath).readAsString());

  final layerTypes = [
    "symbol",
    "circle",
    "line",
    "fill",
    "fill-extrusion",
    "raster",
    "hillshade",
    "heatmap",
  ];

  final sourceTypes = [
    "vector",
    "raster",
    "raster_dem",
    "geojson",
    "video",
    "image"
  ];

  final renderContext = {
    "layerTypes": [
      for (final type in layerTypes)
        {
          "type": type,
          "typePascal": ReCase(type).pascalCase,
          "typeCamel": ReCase(type).camelCase,
          "paint_properties": buildStyleProperties(styleJson, "paint_$type"),
          "layout_properties": buildStyleProperties(styleJson, "layout_$type"),
        },
    ],
    "sourceTypes": [
      for (final type in sourceTypes)
        {
          "type": type.replaceAll("_", "-"),
          "typePascal": ReCase(type).pascalCase,
          "properties": buildSourceProperties(styleJson, "source_$type"),
        },
    ],
    'expressions': buildExpressionProperties(styleJson)
  };

  // required for deduplication
  renderContext["all_layout_properties"] = <dynamic>{
    for (final type in renderContext["layerTypes"]!)
      ...type["layout_properties"].map((p) => p["value"])
  }.map((p) => {"property": p}).toList();

  const templates = [
    "trackasia_gl/android/src/main/java/org/track-asia/trackasiagl/LayerPropertyConverter.java",
    "trackasia_gl/ios/trackasia_gl/Sources/trackasia_gl/LayerPropertyConverter.swift",
    "trackasia_gl/lib/src/layer_expressions.dart",
    "trackasia_gl/lib/src/layer_properties.dart",
    "trackasia_gl_web/lib/src/layer_tools.dart",
    "trackasia_gl_platform_interface/lib/src/source_properties.dart",
  ];

  for (final template in templates) {
    await render(renderContext, template);
  }
}

Future<void> render(
  Map<String, List> renderContext,
  String path,
) async {
  final currentParentPath = Directory.current.parent.path;

  final pathItems = path.split("/");
  final filename = pathItems.removeLast();
  final outputPath = '$currentParentPath/${pathItems.join("/")}';

  print("Rendering $filename");
  final templateFile =
      await File('$currentParentPath/scripts/templates/$filename.template')
          .readAsString();

  final template = Template(templateFile);
  final outputFile = File('$outputPath/$filename');

  outputFile.writeAsString(template.renderString(renderContext));
}

List<Map<String, dynamic>> buildStyleProperties(
    Map<String, dynamic> styleJson, String key) {
  final Map<String, dynamic> items = styleJson[key];

  return items.entries.map((e) => buildStyleProperty(e.key, e.value)).toList();
}

Map<String, dynamic> buildStyleProperty(
    String key, Map<String, dynamic> value) {
  final typeDart = dartTypeMappingTable[value["type"]];
  final nestedTypeDart = dartTypeMappingTable[value["value"]] ??
      dartTypeMappingTable[value["value"]?["type"]];
  final camelCase = ReCase(key).camelCase;

  return <String, dynamic>{
    'value': key,
    'isFloatArrayProperty': typeDart == "List" && nestedTypeDart == "double",
    'isVisibilityProperty': key == "visibility",
    'requiresLiteral': key == "icon-image",
    'isIosAsCamelCase': renamedIosProperties.containsKey(camelCase),
    'iosAsCamelCase': renamedIosProperties[camelCase],
    'doc': value["doc"],
    'docSplit': buildDocSplit(value).map((s) => {"part": s}).toList(),
    'valueAsCamelCase': camelCase
  };
}

List<Map<String, dynamic>> buildSourceProperties(
    Map<String, dynamic> styleJson, String key) {
  final Map<String, dynamic> items = styleJson[key];

  return items.entries
      .where((e) => e.key != "*" && e.key != "type")
      .map((e) => buildSourceProperty(e.key, e.value))
      .toList();
}

Map<String, dynamic> buildSourceProperty(
    String key, Map<String, dynamic> value) {
  final camelCase = ReCase(key).camelCase;
  final typeDart = dartTypeMappingTable[value["type"]];
  final typeSwift = swiftTypeMappingTable[value["type"]];
  final nestedTypeDart = dartTypeMappingTable[value["value"]] ??
      dartTypeMappingTable[value["value"]?["type"]];
  final nestedTypeSwift = swiftTypeMappingTable[value["value"]] ??
      swiftTypeMappingTable[value["value"]?["type"]];

  var defaultValue = value["default"];
  if (defaultValue is List) {
    defaultValue = "const$defaultValue";
  } else if (defaultValue is String) {
    defaultValue = '"$defaultValue"';
  }

  return <String, dynamic>{
    'value': key,
    'doc': value["doc"],
    'default': defaultValue,
    'hasDefault': value["default"] != null,
    'type': nestedTypeDart == null ? typeDart : "$typeDart<$nestedTypeDart>",
    'typeSwift':
        nestedTypeSwift == null ? typeSwift : "$typeSwift<$nestedTypeSwift>",
    'docSplit': buildDocSplit(value).map((s) => {"part": s}).toList(),
    'valueAsCamelCase': camelCase
  };
}

List<String> buildDocSplit(Map<String, dynamic> item) {
  final defaultValue = item["default"];
  final maxValue = item["maximum"];
  final minValue = item["minimum"];
  final type = item["type"];
  final Map<dynamic, dynamic>? sdkSupport = item["sdk-support"];

  final Map<String, dynamic>? values = item["values"];
  final result = splitIntoChunks(item["doc"]!, 70);
  if (type != null) {
    result.add("");
    result.add("Type: $type");
    if (defaultValue != null) result.add("  default: $defaultValue");
    if (minValue != null) result.add("  minimum: $minValue");
    if (maxValue != null) result.add("  maximum: $maxValue");
    if (values != null) {
      result.add("Options:");
      for (final value in values.entries) {
        result.add('  "${value.key}"');
        result.addAll(
            splitIntoChunks("${value.value["doc"]}", 70, prefix: "     "));
      }
    }
  }
  if (sdkSupport != null) {
    final Map<String, dynamic>? basic = sdkSupport["basic functionality"];
    final Map<String, dynamic>? dataDriven = sdkSupport["data-driven styling"];

    result.add("");
    result.add("Sdk Support:");
    if (basic != null && basic.isNotEmpty) {
      result.add("  basic functionality with ${basic.keys.join(", ")}");
    }
    if (dataDriven != null && dataDriven.isNotEmpty) {
      result.add("  data-driven styling with ${dataDriven.keys.join(", ")}");
    }
  }

  return result;
}

List<String> splitIntoChunks(String input, int lineLength,
    {String prefix = ""}) {
  final words = input.split(" ");
  final chunks = <String>[];

  var chunk = "";
  for (final word in words) {
    final nextChunk = chunk.isEmpty ? prefix + word : "$chunk $word";
    if (nextChunk.length > lineLength || chunk.endsWith("\n")) {
      chunks.add(chunk.replaceAll("\n", ""));
      chunk = prefix + word;
    } else {
      chunk = nextChunk;
    }
  }
  chunks.add(chunk);

  return chunks;
}

List<Map<String, dynamic>> buildExpressionProperties(
    Map<String, dynamic> styleJson) {
  final Map<String, dynamic> items = styleJson["expression_name"]["values"];

  final renamed = {
    "var": "varExpression",
    "in": "inExpression",
    "case": "caseExpression",
    "to-string": "toStringExpression",
    "+": "plus",
    "*": "multiply",
    "-": "minus",
    "%": "precent",
    ">": "larger",
    ">=": "largerOrEqual",
    "<": "smaller",
    "<=": "smallerOrEqual",
    "!=": "notEqual",
    "==": "equal",
    "/": "divide",
    "^": "xor",
    "!": "not",
  };

  return items.entries
      .map((e) => <String, dynamic>{
            'value': e.key,
            'doc': e.value["doc"],
            'docSplit': buildDocSplit(e.value).map((s) => {"part": s}).toList(),
            'valueAsCamelCase': ReCase(renamed[e.key] ?? e.key).camelCase
          })
      .toList();
}
