import 'dart:math';

void main() {
  var minionsCount = 8;
  var size = Random().nextInt(4294967296);
  var segSize = size / minionsCount;
  var r2 = size % minionsCount;
  print('Size: $size');
  print('Seg Size: $segSize');
  print('Rest: $r2');
  print('---- Solution ----');
  var fixedSize = size - r2;
  print('FixedSize: $fixedSize');
  segSize = fixedSize / minionsCount;
  print('Seg Size: $segSize');
  print('Seg Size Rounded: ${segSize.round()}');
  print('Rest: $r2');
}