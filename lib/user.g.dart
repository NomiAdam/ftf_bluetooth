// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
      city: json['city'] as String,
      street: json['street'] as String,
      zip: json['zip'] as String,
      floor: json['floor'] as String,
    );

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
      'city': instance.city,
      'street': instance.street,
      'zip': instance.zip,
      'floor': instance.floor,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      sex: json['sex'] as String,
      lastName: json['lastName'] as String,
      firstName: json['firstName'] as String,
      middleName: json['middleName'] as String,
      nationality: json['nationality'] as String,
      phoneNumberPrefix: json['phoneNumberPrefix'] as String,
      phoneNumber: json['phoneNumber'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      bornAt: json['bornAt'] as String,
      maritalStatus: json['maritalStatus'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      parents: (json['parents'] as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      image: json['image'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'sex': instance.sex,
      'lastName': instance.lastName,
      'firstName': instance.firstName,
      'middleName': instance.middleName,
      'nationality': instance.nationality,
      'phoneNumberPrefix': instance.phoneNumberPrefix,
      'phoneNumber': instance.phoneNumber,
      'birthDate': instance.birthDate.toIso8601String(),
      'bornAt': instance.bornAt,
      'maritalStatus': instance.maritalStatus,
      'address': instance.address,
      'parents': instance.parents,
      'image': instance.image,
    };
