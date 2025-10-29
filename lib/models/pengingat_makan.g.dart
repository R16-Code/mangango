// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pengingat_makan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PengingatMakanAdapter extends TypeAdapter<PengingatMakan> {
  @override
  final int typeId = 3;

  @override
  PengingatMakan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PengingatMakan(
      times: (fields[0] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PengingatMakan obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.times);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PengingatMakanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
