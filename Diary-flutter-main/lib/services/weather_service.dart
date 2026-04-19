

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = '81abdb156266e6cf225173a0f5059020';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const Duration _timeout = Duration(seconds: 5);

  /// Check if there is an internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final result =
          await InternetAddress.lookup('google.com').timeout(_timeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Fetch weather data by city name
  Future<Map<String, dynamic>?> fetchWeatherByCity(String city) async {
    try {
      // Check connection before making request
      if (!await hasInternetConnection()) {
        throw Exception('No internet connection');
      }

      final url =
          Uri.parse('$_baseUrl?q=$city&appid=$_apiKey&units=metric&lang=en');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      rethrow; // Re-throw the exception to handle it in the widget
    }
  }

  /// Fetch weather data by geographic coordinates
  Future<Map<String, dynamic>?> fetchWeatherByCoords(
      double lat, double lon) async {
    try {
      // Check connection before making request
      if (!await hasInternetConnection()) {
        throw Exception('No internet connection');
      }

      final url = Uri.parse(
          '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=en');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      rethrow; // Re-throw the exception to handle it in the widget
    }
  }
}