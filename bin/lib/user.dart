import 'dart:convert';
import 'dart:ffi';

import 'controller.dart';

class User {
  final int iduser;
  final String? nama;
  final String? profesi;
  final String? email;
  final String? password;
  final int role_id;
  final int is_active;
  String? tanggal_input;
  String? modified;

  User({
    required this.iduser,
    required this.nama,
    required this.profesi,
    required this.email,
    required this.password,
    required this.role_id,
    required this.is_active,
    required this.tanggal_input,
    required this.modified,
  });

  Map<String, dynamic> toMap() => {
        'iduser': iduser,
        'nama': nama,
        'profesi': profesi,
        'email': email,
        'password': password,
        'role_id': role_id,
        'is_active': is_active,
        'tanggal_input': tanggal_input,
        'modified': modified
      };

  final Controller ctrl = Controller();

  factory User.fromJson(Map<String, dynamic> json) => User(
        iduser: json['iduser'],
        nama: json['nama'],
        profesi: json['profesi'],
        email: json['email'],
        password: json['password'],
        role_id: json['role_id'],
        is_active: 1,
        tanggal_input: json['tanggal_input'],
        modified: json['modified'],
      );
}

User userFromJson(String str) => User.fromJson(json.decode(str));


/*
{
   "iduser":123,
   "nama":"Rahmat Tri Yunandar",
   "profesi":"Dosen",
   "email":"rahmat.rtr@bsi.ac.id",
   "password":"password",
   "role_id":1,
   "is_active":1,
   "tanggal_input":"2022-10-17 00:00:00.000Z",
   "modified":"2022-10-17 00:00:00.000Z"
}
*/
