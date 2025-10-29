// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tempat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TempatAdapter extends TypeAdapter<Tempat> {
  @override
  final int typeId = 1;

  @override
  Tempat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tempat(
      id: fields[0] as int,
      nama: fields[1] as String,
      alamat: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      kisaranHarga: fields[5] as String,
      rating: fields[6] as double,
      jamBuka: fields[7] as String,
      jamTutup: fields[8] as String,
      urlMaps: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Tempat obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.alamat)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.kisaranHarga)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.jamBuka)
      ..writeByte(8)
      ..write(obj.jamTutup)
      ..writeByte(9)
      ..write(obj.urlMaps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TempatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
