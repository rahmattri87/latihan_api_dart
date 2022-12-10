import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:intl/intl.dart';

import 'user.dart';

class Controller {
  String getDateNow() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss');
    final String dateNow = formatter.format(now);
    return dateNow;
  }

  /*SQL Connection*/
  Future<MySqlConnection> connectSql() async {
    var setting = ConnectionSettings(
        host: '127.0.0.1',
        port: 3306,
        user: 'dart2',
        password: 'password',
        db: 'vigenesia');
    var cn = await MySqlConnection.connect(setting);
    return cn;
  }

  /*USER*/
  Future<Response> getUserData(Request request) async {
    var conn = await connectSql();
    var sql = "SELECT * FROM USER";
    var user = await conn.query(sql, []);
    return Response.ok(user.toString());
  }

  Future<Response> getUserDataFilter(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var name = "%" + obj['name'] + "%";

    var conn = await connectSql();
    var sql = "SELECT * FROM USER WHERE nama like ?";
    var user = await conn.query(sql, [name]);
    return Response.ok(user.toString());
  }

  Future<Response> postUserData(Request request) async {
    String body = await request.readAsString();
    User user = userFromJson(body);
    user.tanggal_input = getDateNow();
    user.modified = getDateNow();

    var conn = await connectSql();
    var sqlExecute = """
        INSERT INTO user (nama, profesi, email, role_id, is_active, tanggal_input, modified) VALUES
        (
          '${user.nama}','${user.profesi}','${user.email}','${user.role_id}',
          '${user.is_active}','${user.tanggal_input}','${user.modified}'
        )        
    """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM USER WHERE nama = ?";
    var userResponse = await conn.query(sql, [user.nama]);

    return Response.ok(userResponse.toString());
  }

  Future<Response> putUserData(Request request) async {
    String body = await request.readAsString();
    User user = userFromJson(body);
    user.modified = getDateNow();

    var conn = await connectSql();
    var sqlExecute = """
        UPDATE user SET nama ='${user.nama}', profesi = '${user.profesi}',
                        email = '${user.email}', role_id = '${user.role_id}', 
                        modified='${user.modified}' 
        WHERE iduser ='${user.iduser}'
    """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM USER WHERE iduser = ?";
    var userResponse = await conn.query(sql, [user.iduser]);

    return Response.ok(userResponse.toString());
  }

  Future<Response> deleteUser(Request request) async {
    String body = await request.readAsString();
    User user = userFromJson(body);

    var conn = await connectSql();
    var sqlExecute = """ 
      DELETE FROM USER WHERE iduser ='${user.iduser}'
    """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM USER WHERE iduser = ?";
    var userResponse = await conn.query(sql, [user.iduser]);

    return Response.ok(userResponse.toString());
  }

  /*ROLE*/

  /*MOTIVASI*/
}
