import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share/share.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool _isRecording = false;
  int _secondsLeft = 60;
  late Timer _timer;

  // Variables for accelerometer data
  bool _accelAvailable = false;
  List<double> _accelData = List.filled(3, 0.0);
  StreamSubscription? _accelSubscription;
  final List<List<dynamic>> _dataStorage = [];

  @override
  void initState() {
    super.initState();
    _checkAccelerometerStatus();
  }

  // Timer functionalities
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        _resetTimer();
        return;
      }
      if (_isRecording) {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  void _pauseTimer() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    setState(() {
      _isRecording = false;
    });
  }

  // Check if accelerometer is available on the device
  void _checkAccelerometerStatus() async {
    await SensorManager()
        .isSensorAvailable(Sensors.ACCELEROMETER)
        .then((result) {
      setState(() {
        _accelAvailable = result;
      });
    });
  }

  // Start reading accelerometer data and save to storage
  Future<void> _startAccelerometer() async {
    if (_accelSubscription != null) return;
    if (_accelAvailable) {
      final stream = await SensorManager().sensorUpdates(
        sensorId: Sensors.ACCELEROMETER,
        interval: const Duration(milliseconds: 50),
      );
      _accelSubscription = stream.listen((sensorEvent) {
        setState(() {
          _accelData = sensorEvent.data;
          _dataStorage.add([
            DateTime.now().millisecondsSinceEpoch,
            _accelData[0],
            _accelData[1],
            _accelData[2]
          ]);
        });
      });
    }
  }

  // Reset timer and save data when recording finishes
  void _resetTimer() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    setState(() {
      _isRecording = false;
      _secondsLeft = 60;
    });
    _saveDataToCSV();
    _printTable();
  }

  // Save the data to a CSV file
  Future<void> _saveDataToCSV() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final File file = File('$path/accelerometer_data.csv');

    String csvData = const ListToCsvConverter().convert(_dataStorage);
    await file.writeAsString(csvData);
  }

  // Print the table (data) in the console
  void _printTable() {
    for (var row in _dataStorage) {
      print(row);
    }
  }

  // Share the saved CSV data
  void _shareCSV() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final File file = File('$path/accelerometer_data.csv');

    await Share.shareFiles([file.path], subject: 'Accelerometer Data');
  }

  // Stop the accelerometer stream subscription
  void _stopAccelerometer() {
    if (_accelSubscription == null) return;
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  // UI Building
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording Timer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              iconSize: 100.0,
              icon: Icon(
                _isRecording ? Icons.pause : Icons.fiber_manual_record,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  if (_isRecording) {
                    _pauseTimer();
                    _stopAccelerometer();
                  } else {
                    _startTimer();
                    _startAccelerometer();
                    _isRecording = true;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              '00:${_secondsLeft.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _shareCSV,
              child: const Text('Share CSV Data'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    _stopAccelerometer();
    super.dispose();
  }
}
