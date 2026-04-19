import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Map<String, dynamic>? weatherData;
  bool loading = false;
  String city = "Cochabamba,BO";
  String? errorMsg;
  final TextEditingController _controller =
      TextEditingController(text: "Cochabamba,BO");

  Future<void> _fetchWeather([String? newCity]) async {
    setState(() {
      loading = true;
      errorMsg = null;
    });
    final service = WeatherService();
    final queryCity = newCity ?? city;
    final data = await service.fetchWeatherByCity(queryCity);
    if (data == null) {
      setState(() {
        weatherData = null;
        loading = false;
        errorMsg =
            "Could not load weather for '$queryCity'. Check the city name.";
      });
    } else {
      setState(() {
        weatherData = data;
        city = queryCity;
        loading = false;
        errorMsg = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekDays = [
      'SUNDAY',
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY'
    ];
    String day = weekDays[now.weekday % 7];
    String date =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    String? iconCode =
        weatherData != null ? weatherData!["weather"][0]["icon"] : null;
    String? iconUrl = iconCode != null
        ? "https://openweathermap.org/img/wn/$iconCode@4x.png"
        : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City/Department input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    labelText: 'City or Department',
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _fetchWeather(value.trim());
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () {
                        if (_controller.text.trim().isNotEmpty) {
                          _fetchWeather(_controller.text.trim());
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B2D8E), // Purple
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Search',
                    style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (loading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B2D8E)), // Purple
              ),
            )
          else if (errorMsg != null)
            Center(
              child: Text(
                errorMsg!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (weatherData != null)
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (weatherData!["name"] ?? "CITY NAME")
                                .toString()
                                .toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                          ),
                          const SizedBox(height: 2),
                          Text(day,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color)),
                          Text(date,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.water_drop,
                                  size: 18,
                                  color: Theme.of(context).iconTheme.color),
                              const SizedBox(width: 4),
                              Text(
                                weatherData!["main"]?["humidity"] != null
                                    ? "${weatherData!["main"]["humidity"]}%"
                                    : "-",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_downward,
                                size: 12,
                                color: Theme.of(context).iconTheme.color),
                            Text(
                              weatherData!["main"]?["temp_min"] != null
                                  ? "${weatherData!["main"]["temp_min"].round()}°"
                                  : "-",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_upward,
                                size: 12,
                                color: Theme.of(context).iconTheme.color),
                            Text(
                              weatherData!["main"]?["temp_max"] != null
                                  ? "${weatherData!["main"]["temp_max"].round()}°"
                                  : "-",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    iconUrl != null
                        ? Image.network(
                            iconUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.cloud,
                                size: 60,
                                color: Theme.of(context).iconTheme.color),
                          )
                        : Icon(Icons.cloud,
                            size: 60, color: Theme.of(context).iconTheme.color),
                    const SizedBox(width: 16),
                    Text(
                      weatherData!["main"]?["temp"] != null
                          ? "${weatherData!["main"]["temp"].round()}°"
                          : "-",
                      style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 36,
                          color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    Expanded(
                      child: Text(
                        weatherData!["weather"]?[0]?["description"] != null
                            ? weatherData!["weather"][0]["description"]
                                .toString()
                                .toUpperCase()
                            : "NO DATA",
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Center(
              child: Text(
                "No weather data available",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}