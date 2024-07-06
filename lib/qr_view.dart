import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRViewPage extends StatefulWidget {
  const QRViewPage({super.key});

  @override
  State<StatefulWidget> createState() => QRViewState();
}

class QRViewState extends State<QRViewPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                    ? Column(
                        children: [
                          Text(
                              'Barcode Type: ${result?.format.name}   Data: ${result?.code}'),
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(result?.code);
                              },
                              child: Text('Confirm'))
                        ],
                      )
                    : const Text('Scan a code'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
