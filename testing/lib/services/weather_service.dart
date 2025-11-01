
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'location.dart';

class Weather{
  final String cityName;
  final double temperature;
  final String mainCondition;

  Weather({required this.cityName ,required this.temperature, required this.mainCondition});

  factory Weather.fromJson(Map<String, dynamic> json){
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
     mainCondition: json['weather'][0]['main'],
     );
  }
}


class WeatherService {

  static const BASE_URL =  'https://api.openweathermap.org/data/2.5/weather';

  final String apiKey;

  WeatherService(this.apiKey);


  Future getWeather(String cityName) async{
    final response = await http.get(Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric'));

    if (response.statusCode == 200){
      return Weather.fromJson(jsonDecode(response.body));
    }
  }

  
}
