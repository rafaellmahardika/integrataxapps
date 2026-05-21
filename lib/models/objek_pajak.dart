class ObjekPajakSearchResult {
  final String kdPropinsi;
  final String kdDati2;
  final String kdKecamatan;
  final String kdKelurahan;
  final String kdBlok;
  final String noUrut;
  final String kdJnsOp;
  final String namaWajibPajak;
  final String jalanObjekPajak;

  const ObjekPajakSearchResult({
    required this.kdPropinsi,
    required this.kdDati2,
    required this.kdKecamatan,
    required this.kdKelurahan,
    required this.kdBlok,
    required this.noUrut,
    required this.kdJnsOp,
    required this.namaWajibPajak,
    required this.jalanObjekPajak,
  });

  factory ObjekPajakSearchResult.fromJson(Map<String, dynamic> json) {
    return ObjekPajakSearchResult(
      kdPropinsi: '${json['kdPropinsi'] ?? ''}',
      kdDati2: '${json['kdDati2'] ?? ''}',
      kdKecamatan: '${json['kdKecamatan'] ?? ''}',
      kdKelurahan: '${json['kdKelurahan'] ?? ''}',
      kdBlok: '${json['kdBlok'] ?? ''}',
      noUrut: '${json['noUrut'] ?? ''}',
      kdJnsOp: '${json['kdJnsOp'] ?? ''}',
      namaWajibPajak: '${json['nmWpSppt'] ?? '-'}',
      jalanObjekPajak: '${json['jalanOp'] ?? '-'}',
    );
  }

  String get nop => [
    kdPropinsi,
    kdDati2,
    kdKecamatan,
    kdKelurahan,
    kdBlok,
    noUrut,
    kdJnsOp,
  ].join('.');
}

class ObjekPajakListItem extends ObjekPajakSearchResult {
  final int luasBumi;
  final int njopBumi;
  final int totalLuasBangunan;
  final int totalNilaiBangunan;

  const ObjekPajakListItem({
    required super.kdPropinsi,
    required super.kdDati2,
    required super.kdKecamatan,
    required super.kdKelurahan,
    required super.kdBlok,
    required super.noUrut,
    required super.kdJnsOp,
    required super.namaWajibPajak,
    required super.jalanObjekPajak,
    required this.luasBumi,
    required this.njopBumi,
    required this.totalLuasBangunan,
    required this.totalNilaiBangunan,
  });

  factory ObjekPajakListItem.fromJson(Map<String, dynamic> json) {
    return ObjekPajakListItem(
      kdPropinsi: '${json['kdPropinsi'] ?? ''}',
      kdDati2: '${json['kdDati2'] ?? ''}',
      kdKecamatan: '${json['kdKecamatan'] ?? ''}',
      kdKelurahan: '${json['kdKelurahan'] ?? ''}',
      kdBlok: '${json['kdBlok'] ?? ''}',
      noUrut: '${json['noUrut'] ?? ''}',
      kdJnsOp: '${json['kdJnsOp'] ?? ''}',
      namaWajibPajak: '${json['nmWpSppt'] ?? '-'}',
      jalanObjekPajak: '${json['jalanOp'] ?? '-'}',
      luasBumi: _asInt(json['luasBumi']),
      njopBumi: _asInt(json['njopBumi']),
      totalLuasBangunan: _asInt(json['totalLuasBng']),
      totalNilaiBangunan: _asInt(json['totalNilaiBng']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
