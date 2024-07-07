import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class Address {
  final String city;
  final String street;
  final String zip;
  final String floor;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  Address(
      {required this.city,
      required this.street,
      required this.zip,
      required this.floor});

  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

@JsonSerializable()
class User {
  final String id;
  final String sex;
  final String lastName;
  final String firstName;
  final String middleName;
  final String nationality;
  final String phoneNumberPrefix;
  final String phoneNumber;
  final DateTime birthDate;
  final String bornAt;
  final String maritalStatus;
  final Address address;
  final List<User> parents;
  final String? image;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  User(
      {required this.id,
      required this.sex,
      required this.lastName,
      required this.firstName,
      required this.middleName,
      required this.nationality,
      required this.phoneNumberPrefix,
      required this.phoneNumber,
      required this.birthDate,
      required this.bornAt,
      required this.maritalStatus,
      required this.address,
      required this.parents,
      this.image});

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
