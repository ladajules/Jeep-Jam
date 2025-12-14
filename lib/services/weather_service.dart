import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class Weather{
  final double temperature;
  final String mainCondition;
  final double feelsLike;
  final String description;
  final int humidity;

  Weather({
    required this.temperature, 
    required this.mainCondition, 
    required this.feelsLike, 
    required this.description, 
    required this.humidity,
  });

  factory Weather.fromJson(Map<String, dynamic> json){
    return Weather(
      temperature: json['temperature']['degrees'].toDouble(),
      mainCondition: json['weatherCondition']['type'],
      feelsLike: json['feelsLikeTemperature']['degrees'].toDouble(),
      description: json['weatherCondition']['description']['text'],
      humidity: json['relativeHumidity'],
    );
  }
}


class WeatherService {
  static const baseURL = 'https://weather.googleapis.com/v1/currentConditions:lookup';

  String? weatherApiKey = dotenv.env['GOOGLE_CLOUD_API_KEY'];
    final logger = Logger();

  WeatherService(this.weatherApiKey);

  Future<Weather?> getWeather(double? longitude, double? latitude) async{
    
    final response = await http.get(Uri.parse('$baseURL?key=$weatherApiKey&location.latitude=$latitude&location.longitude=$longitude'));
    if (response.statusCode == 200){
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      logger.e('weather service broken mygoodness');
      return null;
    }
  }

}
