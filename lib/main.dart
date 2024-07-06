import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ftf_bluetooth/qr_view.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:uuid/uuid.dart';

final _messangerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FTF_BLE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
      ),
      scaffoldMessengerKey: _messangerKey,
      home: const MyHomePage(title: 'FTF Bluetooth'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const uuid = const Uuid();

class _MyHomePageState extends State<MyHomePage> {
  final deviceUuid = uuid.v4();
  final characteristicUuid = uuid.v4();

  late final AdvertiseData advertiseData;
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  late final ServiceDescription service;

  final AdvertiseSettings advertiseSettings = AdvertiseSettings(
      connectable: true,
      advertiseMode: AdvertiseMode.advertiseModeBalanced,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
      timeout: 10000);

  final AdvertiseSetParameters advertiseSetParameters =
      AdvertiseSetParameters();

  StreamSubscription<MessagePacket>? _dataSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _deviceSub;

  String _randomData = "";
  String _receivedData = "";
  bool _isSupported = false;

  String _scannedRemoteDeviceUuid = "";

  BluetoothDevice? _remoteDevice;
  List<BluetoothService> _remoteServices = [];

  @override
  void initState() {
    advertiseData = AdvertiseData(
      serviceUuid: deviceUuid,
    );

    _randomData = Random().nextInt(10000).toString();

    print('Data in characteristics');
    print(Uint8List.fromList(_randomData.codeUnits));

    final CharacteristicDescription characteristic2 = CharacteristicDescription(
      uuid: characteristicUuid,
      value: Uint8List.fromList(_randomData.codeUnits),
      write: true,
      writeNR: true,
    );

    service = ServiceDescription(
      uuid: deviceUuid,
      characteristics: [characteristic2],
    );

    initPlatformState();
    super.initState();
  }

  Future<void> initPlatformState() async {
    print('Init for: $deviceUuid');
    try {
      if (await FlutterBluePlus.isSupported == false) {
        print("Bluetooth not supported by this device");
        return;
      }

      if (await FlutterBlePeripheral().isSupported == false) {
        print("Bluetooth peripheral not supported by this device");
        return;
      }

      print('Adding BLE service');
      await FlutterBlePeripheral().addService(service);

      print('Bluetooth starting');

      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }

      _dataSub = FlutterBlePeripheral().getDataReceived.listen((data) {
        print('DATA RECEIVED');
        print(data.characteristicUUID);
        setState(() {
          _receivedData = String.fromCharCodes(data.value);
        });
      });

      setState(() {
        _isSupported = true;
      });
    } catch (e) {
      print('Bluetooth initialization error');
      print(e);
    }
  }

  Future<void> _toggleAdvertise() async {
    print('Toggle BLE advertising');
    if (FlutterBlePeripheral().isAdvertising) {
      await FlutterBlePeripheral().stop();
    } else {
      await FlutterBlePeripheral().start(
        advertiseData: advertiseData,
        advertiseSettings: advertiseSettings,
      );
    }
  }

  void _startScan() async {
    print('Start scan');
    _scanSub = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last;
          print(
              '${r.device.remoteId.str}: "${r.advertisementData.connectable}" found!');
          if (r.advertisementData.serviceUuids.isNotEmpty) {
            if (r.advertisementData.serviceUuids.first.str ==
                _scannedRemoteDeviceUuid) {
              print(
                  '${r.device.remoteId.str}: "${r.advertisementData.connectable}" found!');
              print('${r.advertisementData.advName}: name');
              setState(() {
                _remoteDevice = r.device;
              });
            }
          }
        }
      },
      onError: (e) => print(e),
    );

    FlutterBluePlus.cancelWhenScanComplete(_scanSub!);

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      print('Scan failed');
      print(e);
    }
  }

  Future<void> _setNotification(
      BluetoothCharacteristic characteristic, bool enable) async {
    await characteristic.setNotifyValue(enable, forceIndications: true);
    characteristic.lastValueStream.listen((value) {
      print('Characteristic value changed: ${String.fromCharCodes(value)}');
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    print('Connecting to device');

    _deviceSub =
        device.connectionState.listen((BluetoothConnectionState state) async {
      print(state);
      if (state == BluetoothConnectionState.disconnected) {
        print("${device.disconnectReason}");
      }
      if (state == BluetoothConnectionState.connected) {
        final services = await device.discoverServices();
        setState(() {
          _remoteServices = services;
        });
      }
    });

    device.cancelWhenDisconnected(_deviceSub!, delayed: true, next: true);

    await device.connect();
  }

  void _readServices() async {
    print('Reading services');
    _remoteServices.forEach((service) {
      if (service.serviceUuid.str == _scannedRemoteDeviceUuid) {
        print('services');
        print(service.remoteId);
        print(service.serviceUuid);

        var characteristics = service.characteristics;

        characteristics.forEach((c) async {
          if (c.properties.read) {
            print('READIDNG');
            print(c.characteristicUuid.str);
            final value = await c.read();
            print(value);
            if (value.isNotEmpty) {
              setState(() {
                _receivedData = String.fromCharCodes(value);
              });
            }
          }
          if (c.properties.write) {
            print('WRITING');
            print(c.characteristicUuid);
            await c.write(Uint8List.fromList(_randomData.codeUnits));
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Scanned device uuid $_scannedRemoteDeviceUuid'),
            MaterialButton(
              onPressed: () async {
                final data = await Navigator.push<String?>(
                  context,
                  MaterialPageRoute(builder: (context) => const QRViewPage()),
                );
                if (data != null) {
                  setState(() {
                    _scannedRemoteDeviceUuid = data;
                  });
                }
              },
              child: Text(
                'Scan remote device QR',
                style: Theme.of(context)
                    .primaryTextTheme
                    .labelLarge!
                    .copyWith(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Device uuid in QR below'),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: PrettyQrView.data(
                    data: deviceUuid,
                  ),
                ),
              ),
            ),
            Text('Is Bluetooth supported and working: $_isSupported'),
            const SizedBox(height: 6),
            Text('Current UUID: ${advertiseData.serviceUuid}'),
            const SizedBox(height: 6),
            Text('Current characteristics UUID: $characteristicUuid'),
            const SizedBox(height: 6),
            Text('Current random DATA: $_randomData'),
            const SizedBox(height: 6),
            Text('Received DATA (should match remote device): $_receivedData'),
            const SizedBox(height: 12),
            StreamBuilder(
              stream: FlutterBlePeripheral().onPeripheralStateChanged,
              initialData: PeripheralState.unknown,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                return Text(
                  'Peripheral state: ${(snapshot.data as PeripheralState).name}',
                );
              },
            ),
            MaterialButton(
              onPressed: _toggleAdvertise,
              child: Text(
                'Toggle advertising',
                style: Theme.of(context)
                    .primaryTextTheme
                    .labelLarge!
                    .copyWith(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<BluetoothAdapterState>(
              stream: FlutterBluePlus.adapterState,
              initialData: BluetoothAdapterState.unknown,
              builder: (context, snapshot) {
                if (snapshot.data == BluetoothAdapterState.on &&
                    _scannedRemoteDeviceUuid.isNotEmpty) {
                  return MaterialButton(
                    onPressed: () => _startScan(),
                    child: Text(
                      'Scan for device',
                      style: Theme.of(context)
                          .primaryTextTheme
                          .labelLarge!
                          .copyWith(color: Colors.blue),
                    ),
                  );
                }
                return Text(
                  'Adapter state: ${snapshot.data?.name}',
                );
              },
            ),
            if (_remoteDevice != null) ...[
              Text('Remote device: ${_remoteDevice?.isConnected}'),
              MaterialButton(
                onPressed: () {
                  _connectToDevice(_remoteDevice!);
                },
                child: Text(
                  'Connect to device',
                  style: Theme.of(context)
                      .primaryTextTheme
                      .labelLarge!
                      .copyWith(color: Colors.blue),
                ),
              ),
              if (_remoteServices.isNotEmpty)
                MaterialButton(
                  onPressed: () => _readServices(),
                  child: Text(
                    'Read services',
                    style: Theme.of(context)
                        .primaryTextTheme
                        .labelLarge!
                        .copyWith(color: Colors.blue),
                  ),
                ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _dataSub?.cancel();
    _deviceSub?.cancel();
    super.dispose();
  }
}
