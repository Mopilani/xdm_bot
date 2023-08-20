import 'dart:io';
import 'dart:math';

int main() {
  var minionsCount = 16;
  // var size = Random().nextInt(4294967296);
  var size = 133456187;
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
  print('Segs: ');
  for (var i = 0; i < minionsCount; i++) {
    if (i == 0) {
      print('Seg: ${i + 1} ${segSize + r2}');
    } else {
      print('Seg: ${i + 1} $segSize');
    }
  }
  // static int s;

  exit(-1);
  // throw -1;
}

go(String go) {
  print(go);
  if (go == 'go') {
    return -1;
  }
  if (go == 'Go') {
    return -2;
  }
  if (go == 'gO') {
    return 3;
  }
  if (go == "GO") {
    return 0;
  }
}
