// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pengguna.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PenggunaAdapter extends TypeAdapter<Pengguna> {
  @override
  final int typeId = 0;

  @override
  Pengguna read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pengguna(
      id: fields[0] as String,
      username: fields[1] as String,
      hashedPassword: fields[2] as String,
      salt: fields[3] as String,
      reminderTimes: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Pengguna obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.hashedPassword)
      ..writeByte(3)
      ..write(obj.salt)
      ..writeByte(4)
      ..write(obj.reminderTimes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PenggunaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
