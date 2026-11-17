import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import 'detection.dart';

/// What a scan found, split into the five V1 categories.
class ScanResult {
  ScanResult({
    required this.totalPhotos,
    required this.exactGroups,
    required this.similarGroups,
    required this.screenshots,
    required this.blurry,
    required this.largeVideos,
    required this.entities,
  });

  /// Asset id -> platform asset, for thumbnails on the review screen.
  /// Detection itself never touches this map; it stays in the UI layer.
  final Map<String, AssetEntity> entities;

  final int totalPhotos;
  final List<PhotoGroup> exactGroups;
  final List<PhotoGroup> similarGroups;

  /// Screenshot assets (from the system Screenshots album, when the
  /// platform exposes one). Not a group: each screenshot is reviewed
  /// on its own, newest first.
  final List<ScannedAsset> screenshots;

  /// Assets whose thumbnail variance is under the blur threshold.
  final List<ScannedAsset> blurry;

  /// Videos sorted largest first.
  final List<ScannedAsset> largeVideos;

  int get totalGroups => exactGroups.length + similarGroups.length;

  int get bytesFreeable =>
      exactGroups.fold(0, (s, g) => s + g.bytesFreeable) +
      similarGroups.fold(0, (s, g) => s + g.bytesFreeable);
}

/// Scans the photo library entirely on-device.
///
/// - Reads thumbnails (64px) for the perceptual hash, never the
///   full photo, unless the file is needed for the exact SHA-256.
/// - Fingerprints are the only thing kept in memory; photos are never
///   copied, uploaded or sent anywhere.
/// - Screenshots come from the system Screenshots album (name match),
///   because there is no reliable filename API. If the platform does
///   not expose that album, the category is simply empty.
/// - Blurry is a variance heuristic (see detection.dart). It flags
///   candidates; the review screen decides.
class ScanEngine {
  ScanEngine({this.similarityThreshold = 10, this.blurThreshold = 90});

  final int similarityThreshold;

  /// Thumbnail greyscale variance under this value counts as blurry.
  /// Plain-colour photos (a clear sky, a white wall) also score low,
  /// so this category is Pro-gated and review-only in V1.
  final double blurThreshold;

  /// Requests photo permission. Returns true when the scan may run.
  Future<bool> ensurePermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    return state.isAuth;
  }

  Future<ScanResult> scan({
    void Function(int scanned, int total)? onProgress,
  }) async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    final videoPaths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: true,
    );

    final assets = <ScannedAsset>[];
    final screenshots = <ScannedAsset>[];
    final blurry = <ScannedAsset>[];
    final videos = <ScannedAsset>[];
    final entities = <String, AssetEntity>{};

    var total = 0;
    for (final p in paths) {
      total += await p.assetCountAsync;
    }
    var scanned = 0;

    // The "all photos" album first; named albums (e.g. Screenshots)
    // are scanned too, but only their assets are tagged, never
    // double-counted -- see the [seen] set.
    final seen = <String>{};
    for (final path in paths) {
      final isScreenshotAlbum = _isScreenshotAlbum(path.name);
      var page = 0;
      while (true) {
        final pageAssets =
            await path.getAssetListPaged(page: page, size: 200);
        if (pageAssets.isEmpty) break;
        for (final asset in pageAssets) {
          if (!seen.add(asset.id)) continue;
          final scannedAsset = await _scanAsset(asset);
          if (scannedAsset == null) continue;
          entities[asset.id] = asset;
          assets.add(scannedAsset);
          if (isScreenshotAlbum) screenshots.add(scannedAsset);
          if (scannedAsset.blurScore < blurThreshold) {
            blurry.add(scannedAsset);
          }
          scanned++;
          onProgress?.call(scanned, total);
        }
        page++;
      }
    }

    for (final path in videoPaths) {
      var page = 0;
      while (true) {
        final pageAssets =
            await path.getAssetListPaged(page: page, size: 200);
        if (pageAssets.isEmpty) break;
        for (final asset in pageAssets) {
          if (!seen.add(asset.id)) continue;
          entities[asset.id] = asset;
          final file = await asset.file;
          final size = file == null ? 0 : await file.length();
          videos.add(ScannedAsset(
            id: asset.id,
            width: asset.width,
            height: asset.height,
            fileSize: size,
            created: asset.createDateTime,
            durationSeconds: asset.duration,
            isVideo: true,
            albumName: path.name,
          ));
        }
        page++;
      }
    }

    videos.sort((a, b) => b.fileSize.compareTo(a.fileSize));
    final groups = groupAssets(assets, threshold: similarityThreshold);
    return ScanResult(
      totalPhotos: scanned,
      exactGroups:
          groups.where((g) => g.kind == GroupKind.exact).toList(),
      similarGroups:
          groups.where((g) => g.kind == GroupKind.similar).toList(),
      screenshots: screenshots,
      blurry: blurry,
      largeVideos: videos,
      entities: entities,
    );
  }

  Future<ScannedAsset?> _scanAsset(AssetEntity asset) async {
    Uint8List? thumb;
    try {
      thumb = await asset.thumbnailDataWithSize(
        const ThumbnailSize(64, 64),
        quality: 70,
      );
    } catch (_) {
      thumb = null;
    }
    String? exact;
    var size = 0;
    try {
      final file = await asset.file;
      if (file != null) {
        size = await file.length();
        // Exact hash only for files under 50 MB, so a huge panorama
        // does not stall the scan. Similar detection still covers it.
        if (size < 50 * 1024 * 1024) {
          exact = exactHashOf(await file.readAsBytes());
        }
      }
    } catch (_) {
      exact = null;
    }
    return ScannedAsset(
      id: asset.id,
      width: asset.width,
      height: asset.height,
      fileSize: size,
      created: asset.createDateTime,
      exactHash: exact,
      dHash: thumb == null ? null : dHashOf(thumb),
      blurScore: thumb == null ? 0 : blurScoreOf(thumb),
    );
  }

  bool _isScreenshotAlbum(String name) {
    final lower = name.toLowerCase();
    return lower.contains('screenshot') ||
        lower.contains('屏幕快照') ||
        lower.contains('截屏') ||
        lower.contains('screenshots');
  }

  /// Deletes by asset id through PhotoKit / the Android media store.
  /// On both platforms the photos land in Recently Deleted / trash
  /// for 30 days -- the app never permanently deletes in one step.
  static Future<List<String>> deleteIds(List<String> ids) =>
      PhotoManager.editor.deleteWithIds(ids);
}
