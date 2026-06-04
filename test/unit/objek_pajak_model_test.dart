// test/unit/objek_pajak_model_test.dart
//
// Unit tests for ObjekPajakSearchResult and ObjekPajakListItem model parsing.
// These tests verify robust null-safety handling in fromJson constructors.

import 'package:flutter_test/flutter_test.dart';
import 'package:integratax/models/objek_pajak.dart';

void main() {
  group('ObjekPajakSearchResult.fromJson()', () {
    const fullJson = {
      'kdPropinsi': '32',
      'kdDati2': '04',
      'kdKecamatan': '010',
      'kdKelurahan': '001',
      'kdBlok': '002',
      'noUrut': '0001',
      'kdJnsOp': '0',
      'nmWpSppt': 'BUDI SANTOSO',
      'jalanOp': 'JL. MERDEKA NO. 1',
    };

    test('parses a complete JSON object correctly', () {
      final result = ObjekPajakSearchResult.fromJson(fullJson);
      expect(result.kdPropinsi, equals('32'));
      expect(result.kdDati2, equals('04'));
      expect(result.kdKecamatan, equals('010'));
      expect(result.kdKelurahan, equals('001'));
      expect(result.kdBlok, equals('002'));
      expect(result.noUrut, equals('0001'));
      expect(result.kdJnsOp, equals('0'));
      expect(result.namaWajibPajak, equals('BUDI SANTOSO'));
      expect(result.jalanObjekPajak, equals('JL. MERDEKA NO. 1'));
    });

    test('NOP getter returns dot-joined segments', () {
      final result = ObjekPajakSearchResult.fromJson(fullJson);
      expect(result.nop, equals('32.04.010.001.002.0001.0'));
    });

    test('empty JSON produces empty strings (no crash)', () {
      final result = ObjekPajakSearchResult.fromJson({});
      expect(result.kdPropinsi, equals(''));
      expect(result.namaWajibPajak, equals('-'));
      expect(result.jalanObjekPajak, equals('-'));
    });

    test('null field values fall back to empty string or dash', () {
      final result = ObjekPajakSearchResult.fromJson({
        'kdPropinsi': null,
        'nmWpSppt': null,
        'jalanOp': null,
      });
      expect(result.kdPropinsi, equals(''));
      expect(result.namaWajibPajak, equals('-'));
      expect(result.jalanObjekPajak, equals('-'));
    });

    test('integer field values are coerced to string', () {
      final result = ObjekPajakSearchResult.fromJson({
        ...fullJson,
        'kdPropinsi': 32, // integer instead of string
      });
      expect(result.kdPropinsi, equals('32'));
    });

    test('NOP with empty segments still does not crash', () {
      final result = ObjekPajakSearchResult.fromJson({});
      expect(() => result.nop, returnsNormally);
    });
  });

  group('ObjekPajakListItem.fromJson()', () {
    const fullJson = {
      'kdPropinsi': '51',
      'kdDati2': '71',
      'kdKecamatan': '010',
      'kdKelurahan': '001',
      'kdBlok': '098',
      'noUrut': '0019',
      'kdJnsOp': '0',
      'nmWpSppt': 'JOKO SOLDER',
      'jalanOp': 'JL. HARAPAN NO. 190',
      'luasBumi': 1756,
      'njopBumi': 3906910352,
      'totalLuasBng': '814',
      'totalNilaiBng': '4560725052',
    };

    test('parses integer luasBumi correctly', () {
      final item = ObjekPajakListItem.fromJson(fullJson);
      expect(item.luasBumi, equals(1756));
    });

    test('parses string totalLuasBng correctly (coerces to int)', () {
      final item = ObjekPajakListItem.fromJson(fullJson);
      expect(item.totalLuasBangunan, equals(814));
    });

    test('parses string totalNilaiBng correctly (coerces to int)', () {
      final item = ObjekPajakListItem.fromJson(fullJson);
      expect(item.totalNilaiBangunan, equals(4560725052));
    });

    test('null numeric fields fall back to 0', () {
      final item = ObjekPajakListItem.fromJson({
        ...fullJson,
        'luasBumi': null,
        'njopBumi': null,
        'totalLuasBng': null,
        'totalNilaiBng': null,
      });
      expect(item.luasBumi, equals(0));
      expect(item.njopBumi, equals(0));
      expect(item.totalLuasBangunan, equals(0));
      expect(item.totalNilaiBangunan, equals(0));
    });

    test('non-numeric string fields fall back to 0', () {
      final item = ObjekPajakListItem.fromJson({
        ...fullJson,
        'luasBumi': 'not-a-number',
        'totalLuasBng': 'abc',
      });
      expect(item.luasBumi, equals(0));
      expect(item.totalLuasBangunan, equals(0));
    });

    test('double numeric value is truncated to int', () {
      final item = ObjekPajakListItem.fromJson({
        ...fullJson,
        'luasBumi': 1756.9, // double from upstream
      });
      expect(item.luasBumi, equals(1756));
    });

    test('completely empty JSON does not crash', () {
      expect(() => ObjekPajakListItem.fromJson({}), returnsNormally);
    });

    test('is a subtype of ObjekPajakSearchResult', () {
      final item = ObjekPajakListItem.fromJson(fullJson);
      expect(item, isA<ObjekPajakSearchResult>());
    });
  });
}
