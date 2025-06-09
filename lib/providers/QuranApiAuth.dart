import 'package:http/http.dart' as http;
import 'dart:convert';

class QuranApiAuth {
  final String clientId;
  final String clientSecret;
  final String authEndpoint;

  String? _accessToken;
  DateTime? _tokenExpiry;

  QuranApiAuth({
    required this.clientId,
    required this.clientSecret,
    required this.authEndpoint,
  });

  Future<String?> getAccessToken() async {

    if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
      print('Using cached access token.');
      return _accessToken;
    }

    print('Requesting new access token...');
    final url = Uri.parse(authEndpoint);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); 

        print('Access token obtained successfully.');
        return _accessToken;
      } else {
        print('Failed to get access token. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }


  Future<http.Response?> authenticatedGet(String dataEndpoint) async {
    final token = await getAccessToken();
    if (token == null) {
      print('No access token available. Cannot make authenticated request.');
      return null;
    }

    final url = Uri.parse(dataEndpoint);
    try {
      final response = await http.get(
        url,
        headers: {
          'x-auth-token': token,
          'x-client-id': clientId,
        },
      );
      return response;
    } catch (e) {
      print('Error making authenticated request: $e');
      return null;
    }
  }


}