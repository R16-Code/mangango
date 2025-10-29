// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_kurs.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CacheKursAdapter extends TypeAdapter<CacheKurs> {
  @override
  final int typeId = 2;

  @override
  CacheKurs read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheKurs(
      currencyCode: fields[0] as String,
      rate: fields[1] as double,
      lastUpdated: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CacheKurs obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.currencyCode)
      ..writeByte(1)
      ..write(obj.rate)
      ..writeByte(2)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheKursAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
