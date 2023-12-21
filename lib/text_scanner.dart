import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:text_recognition/result_screen.dart';

class TextScanner extends StatefulWidget {
  const TextScanner({Key? key}) : super(key: key);

  @override
  State<TextScanner> createState() => _TextScannerState();
}

class _TextScannerState extends State<TextScanner> with WidgetsBindingObserver {
  bool isPermissionGranted = false;
  late final Future<void> future;

  CameraController? cameraController;
  final textRecogniser = TextRecognizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    future = requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopCamera();
    textRecogniser.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        cameraController != null &&
        cameraController!.value.isInitialized) {
      startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          return Stack(children: [
            if (isPermissionGranted)
              FutureBuilder<List<CameraDescription>>(
                  future: availableCameras(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      initCameraController(snapshot.data!);
                      return Center(
                        child: CameraPreview(cameraController!),
                      );
                    } else {
                      return const LinearProgressIndicator();
                    }
                  }),
            Scaffold(
                appBar: AppBar(
                  title: const Text(' Metin Tanıma Örneği '),
                ),
                backgroundColor:
                    isPermissionGranted ? Colors.transparent : null,
                body: isPermissionGranted
                    ? Column(children: [
                        Expanded(child: Container()),
                        Container(
                            padding: const EdgeInsets.only(bottom: 30),
                            child: ElevatedButton(
                                onPressed: () {
                                  scanImage();
                                },
                                child: const Text('Metin Tara ')))
                      ])
                    : Center(
                        child: Container(
                            padding:
                                const EdgeInsets.only(left: 24.0, right: 24.0),
                            child: const Text(
                              ' Kamera İzni Reddedildi ',
                              textAlign: TextAlign.center,
                            ))))
          ]);
        });
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    isPermissionGranted = status == PermissionStatus.granted;
  }

  void initCameraController(List<CameraDescription> cameras) {
    if (cameraController != null) {
      return;
    }

    CameraDescription? camera;
    for (var a = 0; a < cameras.length; a++) {
      final CameraDescription current = cameras[a];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }
    if (camera != null) {
      cameraSelected(camera);
    }
  }

  Future<void> cameraSelected(CameraDescription camera) async {
    cameraController =
        CameraController(camera, ResolutionPreset.max, enableAudio: false);
    await cameraController?.initialize();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void startCamera() {
    if (cameraController != null) {
      cameraSelected(cameraController!.description);
    }
  }

  void stopCamera() {
    if (cameraController != null) {
      cameraController?.dispose();
    }
  }

  Future<void> scanImage() async {
    if (cameraController == null) {
      return;
    }
    final navigator = Navigator.of(context);
    try {
      final pictureFile = await cameraController!.takePicture();
      final file = File(pictureFile.path);
      final inputImage = InputImage.fromFile(file);
      final recognizerText = await textRecogniser.processImage(inputImage);
      await navigator.push(MaterialPageRoute(
          builder: (context) => ResultScreen(
                text: recognizerText.text,
              )));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Metin taranırken bir hata oluştu '),
        ),
      );
    }
  }
}
