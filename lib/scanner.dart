import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

class Scanner extends StatefulWidget {
  @override
  _ScannerState createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool isScan = false;
  late AudioPlayer player;

  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
  }

  @override
  void dispose() {
    controller?.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Column(children: [
                      Text(result!.code),
                      ElevatedButton(
                        onPressed: () async {
                          await player.setAsset('assets/audio/send.mp3');
                          player.play();
                          await controller!.resumeCamera();
                          senddata(result!.code);
                          setState(() {
                            result = null;
                          });
                        },
                        child: Text('Enviar'),
                      )
                    ])
                  : Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      await player.setAsset('assets/audio/scan.mp3');
      player.play();
      await controller.pauseCamera();
      isScan = true;
      print(scanData.code);
      setState(() {
        result = scanData;
      });
    });
  }

  Future<bool> senddata(String cedula) async {
    bool result = false;
    var url = Uri.parse('https://asotkdalajuela.com/db_link_flutter/insertdata.php');
    var response = await http.post(url, body: {'cedula': cedula});
    print('Response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('Response body: ${response.body}');
      if (response.body == "1") {
        result = true;
      }
    }
    return result;
  }
}
