import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final file = File('C:/Users/secre/.gemini/antigravity/brain/695ebd3a-7b9d-4950-932c-eb0552884d16/.user_uploaded/media__1784924882263.jpg');
  if (!file.existsSync()) {
    print('Image not found');
    return;
  }
  
  final image = img.decodeImage(file.readAsBytesSync());
  if (image == null) return;
  
  final width = image.width;
  final height = image.height;
  
  // The image has 3 rows. 
  // Row 1: 4 items.
  // Row 2: 6 items (heads).
  // Row 3: 6 items.
  
  final outDir = Directory('assets/illustrations/mascot');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }
  
  // Let's manually crop the most important ones.
  // Row 1 (Top): width / 4. Height: height / 3.
  final r1h = height ~/ 3.2;
  
  // Top left: Waving (Wave)
  final waveImg = img.copyCrop(image, x: 0, y: 0, width: width ~/ 4, height: r1h);
  File('${outDir.path}/wave.png').writeAsBytesSync(img.encodePng(waveImg));
  
  // Top second: Idle (Front)
  final idleImg = img.copyCrop(image, x: width ~/ 4, y: 0, width: width ~/ 4, height: r1h);
  File('${outDir.path}/idle.png').writeAsBytesSync(img.encodePng(idleImg));
  
  // Bottom row: 6 items. Y starts around height * 0.6. Height: height * 0.4
  final r3y = (height * 0.6).toInt();
  final r3h = height - r3y;
  final r3w = width ~/ 6;
  
  // Bottom 2nd: Reading Bible
  final readingImg = img.copyCrop(image, x: r3w * 1, y: r3y, width: r3w, height: r3h);
  File('${outDir.path}/reading.png').writeAsBytesSync(img.encodePng(readingImg));
  
  // Bottom 4th: Celebrate
  final celebrateImg = img.copyCrop(image, x: r3w * 4, y: r3y, width: r3w, height: r3h);
  File('${outDir.path}/celebrate.png').writeAsBytesSync(img.encodePng(celebrateImg));
  
  // Bottom 5th: Praying
  final prayingImg = img.copyCrop(image, x: r3w * 5, y: r3y, width: r3w, height: r3h);
  File('${outDir.path}/praying.png').writeAsBytesSync(img.encodePng(prayingImg));
  
  print('Cropped successfully!');
}
