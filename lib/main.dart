import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';

void main() => runApp(const GeoSensorsApp());

class GeoSensorsApp extends StatelessWidget {
  const GeoSensorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo & Sensors',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const GeoSensorsPage(),
    );
  }
}

class GeoSensorsPage extends StatefulWidget {
  const GeoSensorsPage({super.key});

  @override
  State<GeoSensorsPage> createState() => _GeoSensorsPageState();
}

class _GeoSensorsPageState extends State<GeoSensorsPage> {
  Position? _position;
  String _address = '--';
  double? _compass;
  List<double>? _accelerometerValues;
  List<double>? _gyroscopeValues;
  bool _isLoading = false;

  // Получение местоположения
  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Проверяем, включены ли службы геолокации
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Службы геолокации отключены. Включите GPS.');
        return;
      }

      // Запрашиваем разрешение
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError('Разрешение на геолокацию не предоставлено');
        return;
      }

      // Получаем текущую позицию
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Преобразуем координаты в адрес
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      setState(() {
        _position = pos;
        if (placemarks.isNotEmpty) {
          _address = '${placemarks.first.locality ?? ''}, '
              '${placemarks.first.street ?? ''} '
              '${placemarks.first.thoroughfare ?? ''}';
        } else {
          _address = 'Адрес не найден';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Ошибка: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    
    // Подписываемся на данные акселерометра
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerValues = [event.x, event.y, event.z];
      });
    });

    // Подписываемся на данные гироскопа
    gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeValues = [event.x, event.y, event.z];
      });
    });

    // Подписываемся на данные компаса
    FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        _compass = event.heading;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo & Sensors Demo'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Кнопка получения местоположения
              ElevatedButton(
                onPressed: _isLoading ? null : _getLocation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(width: 10),
                          Text('Определение...',
                              style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : const Text(
                        'Определить местоположение',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),

              const SizedBox(height: 20),

              // Карточка с координатами
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Геолокация',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _position != null
                            ? 'Широта: ${_position!.latitude.toStringAsFixed(6)}'
                            : 'Широта: --',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        _position != null
                            ? 'Долгота: ${_position!.longitude.toStringAsFixed(6)}'
                            : 'Долгота: --',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Адрес:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _address,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Карточка компаса
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Компас',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange, width: 2),
                          ),
                          child: Stack(
                            children: [
                              // Стрелка компаса
                              if (_compass != null)
                                Center(
                                  child: Transform.rotate(
                                    angle: (_compass! * 3.1415926535 / 180),
                                    child: const Icon(
                                      Icons.navigation,
                                      size: 60,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              // Северная метка
                              const Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    'N',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _compass != null
                              ? 'Направление: ${_compass!.toStringAsFixed(2)}°'
                              : 'Компас: --',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Карточка с акселерометром
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Акселерометр',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSensorValue('X', _accelerometerValues?[0]),
                          _buildSensorValue('Y', _accelerometerValues?[1]),
                          _buildSensorValue('Z', _accelerometerValues?[2]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _accelerometerValues != null
                            ? 'X: ${_accelerometerValues![0].toStringAsFixed(2)}, '
                                'Y: ${_accelerometerValues![1].toStringAsFixed(2)}, '
                                'Z: ${_accelerometerValues![2].toStringAsFixed(2)}'
                            : 'Акселерометр: --',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Карточка с гироскопом
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Гироскоп',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSensorValue('X', _gyroscopeValues?[0]),
                          _buildSensorValue('Y', _gyroscopeValues?[1]),
                          _buildSensorValue('Z', _gyroscopeValues?[2]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _gyroscopeValues != null
                            ? 'X: ${_gyroscopeValues![0].toStringAsFixed(2)}, '
                                'Y: ${_gyroscopeValues![1].toStringAsFixed(2)}, '
                                'Z: ${_gyroscopeValues![2].toStringAsFixed(2)}'
                            : 'Гироскоп: --',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Информация о датчиках
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Информация',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Двигайте устройство, чтобы увидеть изменение показаний датчиков\n'
                        '• Поворачивайте устройство для работы компаса\n'
                        '• Для геолокации требуется разрешение и включённый GPS',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorValue(String axis, double? value) {
    return Column(
      children: [
        Text(
          axis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value != null ? value.toStringAsFixed(2) : '--',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}