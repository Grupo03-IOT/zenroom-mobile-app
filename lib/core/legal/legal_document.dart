import 'dart:convert';

import 'package:flutter/services.dart';

import '../l10n/zenroom_i18n.dart';

/// Texto único de los documentos legales; la Web Application lleva una copia
/// idéntica en `src/shared/legal/legal.json`.
const legalAsset = 'assets/legal/legal.json';

class LegalSection {
  LegalSection.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      heading = json['heading'] as String,
      body = json['body'] as List<dynamic>;

  final String id;
  final String heading;

  /// Un texto es un párrafo y una lista es una enumeración con viñetas.
  final List<dynamic> body;
}

class LegalDocument {
  LegalDocument.fromJson(Map<String, dynamic> json)
    : title = json['title'] as String,
      effective = json['effective'] as String,
      intro = json['intro'] as String,
      sections = [
        for (final section in json['sections'] as List<dynamic>)
          LegalSection.fromJson(section as Map<String, dynamic>),
      ];

  final String title;
  final String effective;
  final String intro;
  final List<LegalSection> sections;
}

/// Documentos por tipo (`terms` o `privacy`) e idioma.
class LegalDocuments {
  LegalDocuments._(this._json);

  final Map<String, dynamic> _json;

  static Future<LegalDocuments> load() async {
    final data = await rootBundle.load(legalAsset);
    final text = utf8.decode(Uint8List.sublistView(data));
    return LegalDocuments._(jsonDecode(text) as Map<String, dynamic>);
  }

  LegalDocument of(String kind, AppLanguage language) => LegalDocument.fromJson(
    (_json[kind] as Map<String, dynamic>)[language.code]
        as Map<String, dynamic>,
  );
}
