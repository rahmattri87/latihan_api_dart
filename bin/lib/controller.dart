import 'dart:convert';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:intl/intl.dart';
import 'user.dart';

class Controller {
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

  /*USER -> CRUD*/
  Future<Response> getUserData(Request request) async {
    var conn = await connectSql();
    var sql = "SELECT * FROM USER";
    var user = await conn.query(sql, []);

    var response = _responseSuccessMsg(user.toString());
    return Response.ok(response.toString());
  }

  Future<Response> getUserDataWithAuth(Request request) async {
    final isValidRequest = await _isValidRequestHeader(request);
    if (!isValidRequest) {
      var response = _responseErrorMsg('Invalid Token');
      return Response.forbidden(jsonEncode(response));
    }

    var conn = await connectSql();
    var sql = "SELECT * FROM USER";
    var data = await conn.query(sql, []);

    final Map<String, dynamic> user = new Map<String, dynamic>();

    for (var row in data) {
      user["iduser"] = row["iduser"];
      user["nama"] = row["nama"];
      user["profesi"] = row["profesi"];
      user["email"] = row["email"];
      user["password"] = row["password"];
      user["role_id"] = row["role_id"];
      user["is_active"] = row["is_active"];
    }

    var response = jsonEncode(_responseSuccessMsg(user));
    return Response.ok(response.toString());
  }

  Future<Response> getUserDataFilter(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var name = "%" + obj['name'] + "%";

    var conn = await connectSql();
    var sql = "SELECT * FROM USER WHERE nama like ?";
    var user = await conn.query(sql, [name]);
    var response = _responseSuccessMsg(user.toString());
    return Response.ok(response.toString());
  }

  Future<Response> postUserData(Request request) async {
    String body = await request.readAsString();
    User user = userFromJson(body);

    if (!_isValid(user)) {
      return Response.badRequest(
          body: _responseErrorMsg('Error when validate input data'));
    }

    user.tanggal_input = getDateNow();
    user.modified = getDateNow();

    var conn = await connectSql();
    var sqlExecute = """
    INSERT INTO user (iduser, nama, profesi, email, role_id,
    is_active, tanggal_input, modified)
    VALUES
    (
    '${user.iduser}',
    '${user.nama}','${user.profesi}','${user.email}','${user.role_id}',
    '${user.is_active}','${user.tanggal_input}','${user.modified}'
    )
    """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM USER WHERE nama = ?";
    var userResponse = await conn.query(sql, [user.nama]);

    var response = _responseSuccessMsg(userResponse.toString());
    return Response.ok(response.toString());
  }

  Future<Response> putUserData(Request request) async {
    String body = await request.readAsString();
    User user = userFromJson(body);

    if (!_isValid(user)) {
      return Response.badRequest(
          body: _responseErrorMsg('Error when validate input data'));
    }

    user.modified = getDateNow();

    var conn = await connectSql();
    var sqlExecute = """
      UPDATE user SET
      nama ='${user.nama}', profesi = '${user.profesi}',
      email = '${user.email}', role_id = '${user.role_id}',
      modified='${user.modified}'
      WHERE iduser ='${user.iduser}'
      """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM USER WHERE iduser = ?";
    var userResponse = await conn.query(sql, [user.iduser]);

    var response = _responseSuccessMsg(userResponse.toString());
    return Response.ok(response.toString());
  }

  Future<Response> deleteUser(Request request) async {
    String body = await request.readAsString();
    User user = userFromJson(body);

    var conn = await connectSql();
    var sqlExecute = """
    DELETE FROM USER WHERE iduser ='${user.iduser}'""";

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM USER WHERE iduser = ?";
    var userResponse = await conn.query(sql, [user.iduser]);

    var response = _responseSuccessMsg(userResponse.toString());
    return Response.ok(response.toString());
  }

  Future<Response> signUp(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var email = "%${obj['email']}%";

    var conn = await connectSql();
    var sql = "SELECT * FROM USER WHERE email like ?";
    var user = await conn.query(sql, [email]);
    if (user.isNotEmpty) {
      var strBase = "";

      for (var row in user) {
        strBase =
            '{"iduser": ${row["iduser"]},"email": "${row["email"]}", "password": "${row["password"]}" }';
      }

      final bytes = utf8.encode(strBase.toString());
      final base64Str = base64.encode(bytes);
      final token = "Bearer-$base64Str";
      var response = _responseSuccessMsg(token);
      return Response.ok(jsonEncode(response));
    } else {
      var response = _responseErrorMsg('User Not Found');
      return Response.forbidden(jsonEncode(response));
    }
  }

  /* Date Time */
  String getDateNow() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss');
    final String dateNow = formatter.format(now);
    return dateNow;
  }

  /*
    FUNCTION FOR AUTHORIZATION
  */

  bool _isValid(User user) {
    if (user.nama == null ||
        user.profesi == null ||
        user.email == null ||
        user.role_id == 0) {
      return false;
    }

    return true;
  }

  Future<bool> _isValidRequestHeader(Request request) async {
    //final authorizationHeader = request.headers['Authorization'] ?? request.headers['authorization'];
    //return Response.ok(authorizationHeader);

    // final token = request.headers['token'] ?? request.headers['token'];
    // return Response.ok(token);

    final authHeader =
        request.headers['Authorization'] ?? request.headers['authorization'];
    final parts = authHeader?.split('-');

    if (parts == null || parts.length != 2 || !parts[0].contains('Bearer')) {
      return false;
    }

    final token = parts[1];
    var validUser = await _isValidToken(token);
    if (validUser) {
      return true;
    } else {
      return false;
    }
  }

  Future<Response> getCheckAuth(Request request) async {
    String result = "";
    final isValidRequest = await _isValidRequestHeader(request);
    if (isValidRequest) {
      result = '{"isValid": true}';
      return Response.ok(result.toString());
    } else {
      result = '{"isValid": false}';
      return Response.forbidden(result.toString());
    }
  }

  // verify the token
  Future<bool> _isValidToken(String token) async {
    final str = utf8.decode(base64.decode(token));
    var obj = json.decode(str);
    var iduser = obj['iduser'];

    var conn = await connectSql();
    var sql = "SELECT * FROM USER WHERE iduser = ?";
    var user = await conn.query(sql, [iduser]);

    if (user.isEmpty) {
      return false;
    } else {
      return true;
    }
  }
}

Map<String, dynamic> _responseSuccessMsg(dynamic msg) {
  return {'status': 200, 'Success': true, 'data': msg};
}

Map<String, dynamic> _responseErrorMsg(dynamic msg) {
  return {'status': 400, 'Success': false, 'data': msg};
}
