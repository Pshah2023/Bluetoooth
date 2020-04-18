import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/services.dart';

class Get {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState bluetoothState = BluetoothState.UNKNOWN;
  // Initializing a global key, as it would help us in showing a SnackBar later

  // Get the instance of the Bluetooth
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  dynamic connection;

  int deviceState;

  bool isDisconnecting = false;

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;

  // Define some variables, which will be required later
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice device;
  bool connected = false;
  bool isButtonUnavailable = false;

  void initState() {
    // Get current state
    FlutterBluetoothSerial.instance.state.then(
      (state) {
        bluetoothState = state;
      },
    );

    deviceState = 0; // neutral

    // If the bluetooth of the device is not enabled,
    // then request permission to turn on bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance.onStateChanged().listen(
      (BluetoothState state) {
        bluetoothState = state;
        if (bluetoothState == BluetoothState.STATE_OFF) {
          isButtonUnavailable = true;
        }
        getPairedDevices();
      },
    );
  }

  void dispose() {
    // Avoid memory leak and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
  }

  // Request Bluetooth permission from the user
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    devicesList = devices;
  }

  void onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }
  }

  // Method to disconnect bluetooth
  void disconnect() async {
    isButtonUnavailable = true;
    deviceState = 0;

    await connection.close();
    print('Device disconnected');
    if (!connection.isConnected) {
      connected = false;
      isButtonUnavailable = false;
    }
  }

  Future<void> connect(BluetoothDevice x) async {
    try {
      BluetoothConnection _connection =
          await BluetoothConnection.toAddress(x.address);
      connection = _connection;
    } catch (oof) {
      print(
        oof.toString(),
      );
    }
  }

  // Method to send message,
  // for turning the Bluetooth device on
  Future<String> sendMessageAndReceiveMessage(
      BluetoothDevice x, String message) async {
    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(x.address);

      connection.input.listen(
        (Uint8List data) {
          print('Data incoming: ${ascii.decode(data)}');
          connection.output.add(data); // Sending data

          if (ascii.decode(data).contains('!')) {
            connection.finish(); // Closing connection
            print('Disconnecting by local host');
          }
        },
      ).onDone(
        () {
          print('Disconnected by remote request');
        },
      );
    } catch (exception) {
      return exception.toString();
    }
  }

  void sendMessage(BluetoothDevice x, String messageToSend) async {
    BluetoothConnection _connection =
        await BluetoothConnection.toAddress(x.address);
    _connection.output.add(utf8.encode(messageToSend));
    await _connection.output.allSent;
    print('Device Turned On');
    deviceState = 1;
  }

  // // Method to send message,
  // // for turning the Bluetooth device off
  void sendOffMessageToBluetooth() async {
    connection.output.add(utf8.encode("0" + "\r\n"));
    await connection.output.allSent;
    print('Device Turned Off');

    deviceState = -1; // device off
  }

  void openSettings() {
    FlutterBluetoothSerial.instance.openSettings();
  }
}
