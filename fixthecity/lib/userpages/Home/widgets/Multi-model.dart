import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'dart:math';

class Detection {
  final String label;
  final double confidence;
  final double x, y, w, h;
  Detection({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
}

Future<List<Detection>> classifyWithMultipleModels(
    Uint8List imageBytes,
    List<String> modelPaths,
    List<List<String>> modelLabels,
    img.Image originalImage,
    ) async {
  final detections = <Detection>[];
  const inputSize = 640;

  final resized = img.copyResize(originalImage, width: inputSize, height: inputSize);
  final inputTensor = OrtValueTensor.createTensorWithDataList(
    _imageToFloat32(resized),
    [1, 3, inputSize, inputSize],
  );

  for (int i = 0; i < modelPaths.length; i++) {
    final modelPath = modelPaths[i];
    final labels = modelLabels[i];
    final rawModel = await rootBundle.load(modelPath);

    final session = OrtSession.fromBuffer(
      rawModel.buffer.asUint8List(),
      OrtSessionOptions(),
    );

    final inputName = session.inputNames.first;
    final outputs = await session.runAsync(OrtRunOptions(), {
      inputName: inputTensor,
    });

    final output = outputs?.first?.value;
    if (output != null && output is List && output.isNotEmpty) {
      final rawList = output.first as List;
      detections.addAll(_parseDetections(rawList, labels, originalImage, inputSize));
    }

    outputs?.forEach((e) => e?.release());
    session.release();
  }

  inputTensor.release();

  final nms = _nonMaxSuppression(detections, 0.5);
  return nms;
}

List<Detection> _parseDetections(
    List<dynamic> rawDetections,
    List<String> labels,
    img.Image image,
    int inputSize,
    ) {
  final results = <Detection>[];

  for (int i = 0; i < rawDetections.length; i++) {
    final data = rawDetections[i].cast<double>();
    if (data.length < 6) continue;

    final objectness = data[4];
    final classScores = data.sublist(5);

    double maxScore = -double.infinity;
    int classIdx = -1;
    for (int j = 0; j < classScores.length; j++) {
      if (classScores[j] > maxScore) {
        maxScore = classScores[j];
        classIdx = j;
      }
    }

    final confidence = objectness * maxScore;
    if (confidence < 0.5 || classIdx < 0 || classIdx >= labels.length) continue;

    final label = labels[classIdx];
    final x = data[0] * (image.width / inputSize);
    final y = data[1] * (image.height / inputSize);
    final w = data[2] * (image.width / inputSize);
    final h = data[3] * (image.height / inputSize);

    results.add(Detection(
      label: label,
      confidence: confidence,
      x: x,
      y: y,
      w: w,
      h: h,
    ));
  }
  return results;
}

Float32List _imageToFloat32(img.Image image) {
  final inputSize = image.width;
  final floats = Float32List(3 * inputSize * inputSize);
  int i = 0;
  for (int y = 0; y < inputSize; y++) {
    for (int x = 0; x < inputSize; x++) {
      final pixel = image.getPixel(x, y);
      floats[i] = pixel.r / 255.0;
      floats[i + inputSize * inputSize] = pixel.g / 255.0;
      floats[i + 2 * inputSize * inputSize] = pixel.b / 255.0;
      i++;
    }
  }
  return floats;
}

List<Detection> _nonMaxSuppression(List<Detection> detections, double iouThreshold) {
  detections.sort((a, b) => b.confidence.compareTo(a.confidence));
  final kept = <Detection>[];

  while (detections.isNotEmpty) {
    final current = detections.removeAt(0);
    kept.add(current);
    detections.removeWhere(
          (d) => d.label == current.label && _iou(current, d) > iouThreshold,
    );
  }

  return kept;
}

double _iou(Detection a, Detection b) {
  final xA = max(a.x - a.w / 2, b.x - b.w / 2);
  final yA = max(a.y - a.h / 2, b.y - b.h / 2);
  final xB = min(a.x + a.w / 2, b.x + b.w / 2);
  final yB = min(a.y + a.h / 2, b.y + b.h / 2);

  final interArea = max(0, xB - xA) * max(0, yB - yA);
  final boxAArea = a.w * a.h;
  final boxBArea = b.w * b.h;

  return interArea / (boxAArea + boxBArea - interArea);
}