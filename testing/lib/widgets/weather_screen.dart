import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_service.dart';
import '../utils/weather_utils.dart';

class WeatherScreen extends StatefulWidget {
  final Weather? weather;
  final Position? position;
  final Placemark? placemark;

  const WeatherScreen({
    super.key,
    required this.weather,
    required this.position,
    required this.placemark
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>{
  @override
  Widget build(BuildContext context){
    final hasError = widget.weather == null || widget.position == null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: hasError //ternary for which build to show
        ?
        Column( //shows this if weather or location is error
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 7),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: 20),
            Text(
              'An error occured. Try again later!', style: TextStyle(
                fontSize: 24,
                color: Colors.black 
              ),
            ),
    
            SizedBox(height: 20),      
            Lottie.asset('assets/LoadingFiles.json'),
      
            SizedBox(height: 20),  
            Text('Wait wait wait!! jeep jam will fix things!', style: 
              TextStyle(
                fontSize: 18,
                color: Colors.black)
                )
          ],
        )
        
        : //if it returns valid information it returns weather weather lang
        Column(
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 7),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: 20),
            Text('Weather in the area',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(WeatherUtils.getWeatherIcon(widget.weather?.mainCondition),
                  width: 160,  
                  height: 160,
                  fit: BoxFit.contain,
                  ),
                
                  Text('  ${widget.weather?.temperature.round()}°C', 
                  style: TextStyle(
                    fontSize: 50,
                  ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
        
              Text('${widget.weather?.description}',
              style: TextStyle(
                fontSize: 16
              ),
              ),

              SizedBox(width: 20),  //spacing

              Text('Feels like: ${widget.weather?.feelsLike.round()}°',
              style: TextStyle(
                fontSize: 16
              ),),

              SizedBox(width: 20),  //spacing
        
              Text('Humidity: ${widget.weather?.humidity}',
              style: TextStyle(
                fontSize: 16
              ),),
            ],),
            SizedBox(height: 4,),
        
          ],
        )

      ),
    );
  }

}