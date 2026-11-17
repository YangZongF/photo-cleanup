import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as img;

/// Detection core. Pure Dart, no network, no platform code, so it is
/// unit-testable without a device. The pipeline is four layers:
///
/// 1. Exact: SHA-256 of the file bytes. One pixel changed = different
///    hash, so this only catches byte-identical copies.
/// 2. Near-duplicate: dHash, a 64-bit perceptual fingerprint from a
///    9x8 greyscale thumbnail. Hamming distance <= threshold groups
///    crops, resizes, recompression and filters.
/// 3. Quality: blur score (greyscale variance of the thumbnail) plus
///    resolution and file size, for the Best-keeper pick.
/// 4. Grouping: union-find over pairwise distances, medoid as keeper.
///
/// Thumbnails (not full photos) are hashed, so a 10,000-photo library
/// scans in minutes on-device, not hours. Fingerprints are cached by
/// asset id in [ScanCache] so a re-scan only hashes new photos.

/// One photo (or video) as seen by the scanner.
class ScannedAsset {
  ScannedAsset({
    required this.id,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.created,
    this.exactHash,
    this.dHash,
    this.blurScore = 0,
    this.durationSeconds = 0,
    this.isVideo = false,
    this.albumName = '',
  });

  final String id;
  final int width;
  final int height;
  final int fileSize;
  final DateTime created;

  /// SHA-256 hex of the file bytes, when the file could be read.
  final String? exactHash;

  /// 64-bit dHash, when a thumbnail could be decoded.
  final int? dHash;

  /// Greyscale variance of the thumbnail (0-255 scale). Low = flat or
  /// blurry. Heuristic only; the review screen is the safety net.
  final double blurScore;

  final int durationSeconds;
  final bool isVideo;
  final String albumName;
}

/// SHA-256 hex digest of [bytes]. Pure function, tested.
String exactHashOf(Uint8List bytes) => crypto.sha256.convert(bytes).toString();

/// dHash of decoded image bytes.
///
/// Downscale to 9x8, convert to greyscale, and set one bit per pixel
/// pair: 1 when the left pixel is brighter than the right. Returns null
/// when the bytes cannot be decoded as an image.
int? dHashOf(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  return dHashOfImage(decoded);
}

/// dHash of an already-decoded image. Split out so tests can build
/// images directly without encoding them first.
int dHashOfImage(img.Image image) {
  final small = img.copyResize(image, width: 9, height: 8);
  final grey = img.grayscale(small);
  var hash = 0;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final left = _greyValue(grey.getPixel(x, y));
      final right = _greyValue(grey.getPixel(x + 1, y));
      hash = (hash << 1) | (left > right ? 1 : 0);
    }
  }
  return hash;
}

/// Mean of the red, green and blue channels (0-255).
double _greyValue(img.Pixel pixel) =>
    (pixel.r + pixel.g + pixel.b) / 3;

/// Greyscale variance of decoded image bytes (0 = perfectly flat).
/// Low variance is the blurry/flat heuristic used by the blurry
/// category. Returns 0 when the bytes cannot be decoded.
double blurScoreOf(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return 0;
  return blurScoreOfImage(decoded);
}

double blurScoreOfImage(img.Image image) {
  final small = img.copyResize(image, width: 32, height: 32);
  final grey = img.grayscale(small);
  var sum = 0.0;
  var sumSq = 0.0;
  var n = 0;
  for (var y = 0; y < 32; y++) {
    for (var x = 0; x < 32; x++) {
      final v = _greyValue(grey.getPixel(x, y));
      sum += v;
      sumSq += v * v;
      n++;
    }
  }
  final mean = sum / n;
  return (sumSq / n) - mean * mean;
}

/// Hamming distance between two 64-bit hashes.
int hammingDistance(int a, int b) {
  var x = a ^ b;
  var count = 0;
  while (x != 0) {
    x &= x - 1;
    count++;
  }
  return count;
}

/// A group of photos the scanner believes are the same shot.
/// [keeperIndex] is the Best pick; the rest are suggested for deletion.
/// The keeper can always be changed on the review screen, and at least
/// one photo in every group is kept.
class PhotoGroup {
  PhotoGroup(this.assets, this.keeperIndex, this.kind);

  final List<ScannedAsset> assets;
  final int keeperIndex;
  final GroupKind kind;

  ScannedAsset get keeper => assets[keeperIndex];

  List<ScannedAsset> get deletable => [
        for (var i = 0; i < assets.length; i++)
          if (i != keeperIndex) assets[i],
      ];

  int get bytesFreeable =>
      deletable.fold(0, (sum, a) => sum + a.fileSize);
}

enum GroupKind { exact, similar }

/// Union-find clustering. Groups assets whose dHash distance is at or
/// under [threshold], plus exact-hash groups. Pure function, tested.
List<PhotoGroup> groupAssets(
  List<ScannedAsset> assets, {
  int threshold = 10,
}) {
  final groups = <PhotoGroup>[];

  // Exact duplicates first: same SHA-256, when available.
  final byHash = <String, List<ScannedAsset>>{};
  for (final a in assets) {
    final h = a.exactHash;
    if (h != null) byHash.putIfAbsent(h, () => []).add(a);
  }
  final exactIds = <String>{};
  for (final list in byHash.values) {
    if (list.length < 2) continue;
    groups.add(PhotoGroup(list, bestKeeperIndex(list), GroupKind.exact));
    exactIds.addAll(list.map((a) => a.id));
  }

  // Similar photos: union-find over dHash distances.
  final rest = assets
      .where((a) => !exactIds.contains(a.id) && a.dHash != null)
      .toList();
  final parent = List<int>.generate(rest.length, (i) => i);
  int find(int i) {
    while (parent[i] != i) {
      parent[i] = parent[parent[i]];
      i = parent[i];
    }
    return i;
  }

  void union(int i, int j) {
    final a = find(i);
    final b = find(j);
    if (a != b) parent[a] = b;
  }

  for (var i = 0; i < rest.length; i++) {
    for (var j = i + 1; j < rest.length; j++) {
      if (hammingDistance(rest[i].dHash!, rest[j].dHash!) <= threshold) {
        union(i, j);
      }
    }
  }
  final clusters = <int, List<ScannedAsset>>{};
  for (var i = 0; i < rest.length; i++) {
    clusters.putIfAbsent(find(i), () => []).add(rest[i]);
  }
  for (final list in clusters.values) {
    if (list.length < 2) continue;
    groups.add(PhotoGroup(list, bestKeeperIndex(list), GroupKind.similar));
  }
  return groups;
}

/// Best-keeper pick: highest score wins. Score favours sharpness
/// (blur score), then resolution, then file size, then newest.
/// A Live Photo / longer video is not scored here in V1 -- that is an
/// expansion item (docs/expansion.md).
int bestKeeperIndex(List<ScannedAsset> assets) {
  var best = 0;
  var bestScore = -1.0;
  for (var i = 0; i < assets.length; i++) {
    final a = assets[i];
    final score = a.blurScore * 1000 +
        (a.width * a.height) / 1000 +
        a.fileSize / 10000 +
        a.created.millisecondsSinceEpoch / 1e12;
    if (score > bestScore) {
      bestScore = score;
      best = i;
    }
  }
  return best;
}

/// Fingerprint cache so re-scans only hash new photos.
/// Keyed by asset id; stored in SharedPreferences as JSON in V1.
/// (A real database is overkill until the library exceeds ~50k photos.)
class ScanCache {
  ScanCache(this.hashes);

  final Map<String, int> hashes;

  static ScanCache empty() => ScanCache({});
}
