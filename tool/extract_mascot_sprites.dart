import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('C:/Users/secre/.gemini/antigravity/brain/695ebd3a-7b9d-4950-932c-eb0552884d16/.user_uploaded/media__1784924882263.jpg');
  if (!file.existsSync()) {
    print('Image not found');
    return;
  }

  print('Loading image...');
  final image = img.decodeImage(file.readAsBytesSync());
  if (image == null) return;

  final width = image.width;
  final height = image.height;

  // Helper to check if a pixel is background (white/near-white)
  bool isBg(img.Pixel p) {
    return p.r > 240 && p.g > 240 && p.b > 240;
  }

  // Find rows by Y-axis projection
  List<List<int>> findSegments(int max, bool Function(int) hasContent) {
    List<List<int>> segments = [];
    int? start;
    for (int i = 0; i < max; i++) {
      if (hasContent(i)) {
        start ??= i;
      } else {
        if (start != null) {
          segments.add([start, i - 1]);
          start = null;
        }
      }
    }
    if (start != null) {
      segments.add([start, max - 1]);
    }
    return segments;
  }

  print('Finding rows...');
  final rowSegments = findSegments(height, (y) {
    for (int x = 0; x < width; x++) {
      if (!isBg(image.getPixel(x, y))) return true;
    }
    return false;
  });

  print('Found ${rowSegments.length} rows.');

  List<img.Image> extractedSheep = [];

  for (var row in rowSegments) {
    final yStart = row[0];
    final yEnd = row[1];

    final colSegments = findSegments(width, (x) {
      for (int y = yStart; y <= yEnd; y++) {
        if (!isBg(image.getPixel(x, y))) return true;
      }
      return false;
    });

    for (var col in colSegments) {
      final xStart = col[0];
      final xEnd = col[1];
      
      // We have a bounding box for a sheep
      final sheepImg = img.copyCrop(image, x: xStart, y: yStart, width: xEnd - xStart + 1, height: yEnd - yStart + 1);
      extractedSheep.add(sheepImg);
    }
  }

  print('Extracted ${extractedSheep.length} sheep.');

  // Names mapping based on the sheet visual order:
  // Row 1 (4 items): wave, front, side, back
  // Row 2 (6 items): happy, wink, surprised, thinking, smile, normal
  // Row 3 (6 items): idle, pointing, reading, love, welcome, praying
  
  // Wait, looking at the image:
  // Row 3: normal, pointing, reading, holding heart, open arms, praying
  // The user listed 16 names:
  // happy, wink, surprised, thinking, smile
  // idle, front, side, back
  // wave, pointing, reading, love, welcome, praying, sleep
  // Wait, there's sleep? Let me map them exactly:
  final names = [
    'actions/wave.png',
    'poses/front.png',
    'poses/side.png',
    'poses/back.png',
    'expressions/happy.png',
    'expressions/wink.png',
    'expressions/surprised.png',
    'expressions/thinking.png',
    'expressions/smile.png',
    'expressions/normal.png', // The 6th head in row 2? I will map it to normal, or maybe sleep? The prompt says 16 assets.
    'poses/idle.png',
    'actions/pointing.png',
    'actions/reading.png',
    'actions/love.png',
    'actions/welcome.png',
    'actions/praying.png',
  ];
  
  // If the 6th head is sleep? In the prompt: "mascot_sleep.png". The 6th head has closed eyes, which could be sleep!
  // I will replace 'expressions/normal.png' with 'actions/sleep.png' if it matches closed eyes.
  names[9] = 'actions/sleep.png';

  final outDirs = [
    'assets/mascot/expressions',
    'assets/mascot/poses',
    'assets/mascot/actions',
  ];

  for (var dir in outDirs) {
    final d = Directory(dir);
    if (!d.existsSync()) d.createSync(recursive: true);
  }

  for (int i = 0; i < extractedSheep.length && i < names.length; i++) {
    print('Processing ${names[i]}...');
    img.Image sheep = extractedSheep[i];
    
    // 1. Make background transparent (Flood fill from corners)
    // Actually, a simpler way is to make all white/near-white pixels transparent, 
    // BUT that would make white parts of the sheep (like wool/eyes) transparent!
    // So flood fill is required.
    // Flood fill algorithm:
    List<List<int>> q = [];
    final visited = List.generate(sheep.width, (_) => List.filled(sheep.height, false));
    
    // Add edges to queue
    for (int x = 0; x < sheep.width; x++) {
      q.add([x, 0]);
      q.add([x, sheep.height - 1]);
    }
    for (int y = 0; y < sheep.height; y++) {
      q.add([0, y]);
      q.add([sheep.width - 1, y]);
    }
    
    // Flood fill
    while (q.isNotEmpty) {
      final p = q.removeLast();
      int px = p[0];
      int py = p[1];
      if (px < 0 || px >= sheep.width || py < 0 || py >= sheep.height) continue;
      if (visited[px][py]) continue;
      
      final pixel = sheep.getPixel(px, py);
      if (pixel.r > 230 && pixel.g > 230 && pixel.b > 230) {
        visited[px][py] = true;
        sheep.setPixelRgba(px, py, 0, 0, 0, 0); // Transparent
        q.add([px + 1, py]);
        q.add([px - 1, py]);
        q.add([px, py + 1]);
        q.add([px, py - 1]);
      }
    }
    
    // 2. Pad by 10% and make 1024x1024
    int maxDim = sheep.width > sheep.height ? sheep.width : sheep.height;
    int pad = (maxDim * 0.1).toInt();
    int newSize = maxDim + 2 * pad;
    
    img.Image padded = img.Image(width: newSize, height: newSize, numChannels: 4);
    // fill with transparent
    for (var p in padded) { p.a = 0; }
    
    int dx = (newSize - sheep.width) ~/ 2;
    int dy = (newSize - sheep.height) ~/ 2;
    img.compositeImage(padded, sheep, dstX: dx, dstY: dy);
    
    // Resize to 1024x1024
    img.Image finalImg = img.copyResize(padded, width: 1024, height: 1024, interpolation: img.Interpolation.cubic);
    
    File('assets/mascot/${names[i]}').writeAsBytesSync(img.encodePng(finalImg));
  }
  
  print('Done!');
}
