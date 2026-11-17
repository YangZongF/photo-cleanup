import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_cleanup/core/detection.dart';

img.Image _solid(int w, int h, int grey) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      image.setPixelRgb(x, y, grey, grey, grey);
    }
  }
  return image;
}

img.Image _halfSplit() {
  // Left half dark, right half bright: dHash bits are all 0 except
  // the column where the split falls.
  final image = img.Image(width: 32, height: 32);
  for (var y = 0; y < 32; y++) {
    for (var x = 0; x < 32; x++) {
      final v = x < 16 ? 0 : 255;
      image.setPixelRgb(x, y, v, v, v);
    }
  }
  return image;
}

ScannedAsset _asset(String id, {int? hash, String? exact}) => ScannedAsset(
      id: id,
      width: 100,
      height: 100,
      fileSize: 1000,
      created: DateTime(2026, 1, 1),
      exactHash: exact,
      dHash: hash,
      blurScore: 100,
    );

void main() {
  test('identical images have the same dHash, different ones differ', () {
    final a = dHashOfImage(_halfSplit());
    final b = dHashOfImage(_halfSplit());
    final c = dHashOfImage(_solid(32, 32, 128));
    expect(a, b);
    expect(hammingDistance(a, c), greaterThan(0));
  });

  test('hamming distance counts differing bits', () {
    expect(hammingDistance(0, 0), 0);
    expect(hammingDistance(0, 7), 3);
    expect(hammingDistance(0xFF, 0x0F), 4);
  });

  test('exact duplicates group together, keep-one holds', () {
    final groups = groupAssets([
      _asset('a', exact: 'deadbeef'),
      _asset('b', exact: 'deadbeef'),
      _asset('c', exact: 'other'),
    ]);
    expect(groups.length, 1);
    expect(groups.first.kind, GroupKind.exact);
    expect(groups.first.assets.length, 2);
    expect(groups.first.deletable.length, 1);
  });

  test('similar photos group by dHash threshold', () {
    final base = dHashOfImage(_halfSplit());
    final groups = groupAssets([
      _asset('a', hash: base),
      _asset('b', hash: base ^ 1), // one bit different
      _asset('c', hash: base ^ 0xFFFFFFFFFFFFFFFF), // far away
    ], threshold: 10);
    expect(groups.length, 1);
    expect(groups.first.kind, GroupKind.similar);
    expect(groups.first.assets.map((a) => a.id), containsAll(['a', 'b']));
  });

  test('blur score: flat image scores near zero', () {
    expect(blurScoreOfImage(_solid(32, 32, 200)), closeTo(0, 0.001));
    expect(blurScoreOfImage(_halfSplit()), greaterThan(1000));
  });

  test('exact hash is stable and 64 hex chars', () {
    final hash = exactHashOf(Uint8List.fromList([1, 2, 3]));
    expect(hash, exactHashOf(Uint8List.fromList([1, 2, 3])));
    expect(hash.length, 64);
  });
}
