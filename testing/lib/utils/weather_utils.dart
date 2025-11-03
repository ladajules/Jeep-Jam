

String getWeatherIcon (String? mainCondition){
    if (mainCondition == null){
      return 'assets/weather_icons/sunny.json';
    }

    switch(mainCondition.toLowerCase()){
      case 'clouds':
      return 'assets/weather_icons/cloudy.json';

      case 'rain':
      return 'assets/weather_icons/rain.json';

      case 'heavy_rain':
      return 'assets/weather_icons/thunderstorm.json';

      case 'thunderstorm':
      return 'assets/weather_icons/thunderstorm.json';

      case 'clear':
      return 'assets/weather_icons/sunny.json';

      case 'wind':
      return 'assets/weather_icons/windy.json';

      default:
      return 'assets/weather_icons/cloudy.json';
    }
  }