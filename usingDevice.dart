import 'package:flutter/material.dart';
import 'package:flutter_bluetooth/bluetooth.dart';

class ControllingDevice extends StatefulWidget {
  @override
  _ControllingDeviceState createState() => _ControllingDeviceState();
}

class _ControllingDeviceState extends State<ControllingDevice> {
  Get bluetooth = Get();

  int _stepper = 0;

  List<Widget> _connectToDevice() {
    List<Widget> x = [];
    bluetooth.devicesList.forEach(
      (device) {
        x.add(
          RaisedButton(
            onPressed: () {
              bluetooth.connect(device);
            },
            child: Text(
              device.name,
            ),
          ),
        );
      },
    );
    return x;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stepper(
        currentStep: _stepper,
        onStepContinue: () {
          setState(
            () {
              _stepper += 1;
            },
          );
          if (_stepper == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Controller(),
              ),
            );
          }
        },
        steps: [
          Step(
            title: Text("Start App"),
            content: RaisedButton(
              elevation: 2,
              child: Text(
                "You must tap this, you can tap it multiple times",
                softWrap: true,
              ),
              onPressed: () {
                bluetooth.enableBluetooth();
              },
            ),
          ),
          Step(
            title: Text("Connect to your device"),
            content: RaisedButton(
              elevation: 2,
              child: Text("Open Bluetooth Settings"),
              onPressed: () {
                bluetooth.openSettings();
              },
            ),
          ),
          Step(
            title: Text("Get Paired Devices"),
            content: RaisedButton(
              elevation: 2,
              child: Text(
                "This App Needs You To Tap This, You Must Now Wait 15 Seconds",
                softWrap: true,
              ),
              onPressed: () {
                bluetooth.getPairedDevices();
              },
            ),
          ),
          Step(
            title: Text("Pair To The Device In App"),
            content: Column(
              children: _connectToDevice(),
            ),
          ),
          Step(
            title: Text("Controller"),
            content: RaisedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Controller(),
                  ),
                );
              },
              child: Text("Go now"),
            ),
          ),
        ],
      ),
    );
  }
}

class Controller extends StatefulWidget {
  @override
  _ControllerState createState() => _ControllerState();
}

class _ControllerState extends State<Controller> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
