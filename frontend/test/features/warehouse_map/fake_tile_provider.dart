import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Tile provider dùng cho test: luôn trả về một ảnh 1x1 trong bộ nhớ nên các
/// widget test KHÔNG bao giờ gọi mạng để tải tile OpenStreetMap.
class FakeTileProvider extends TileProvider {
  /// PNG 1x1 trong suốt.
  static final Uint8List _transparentPixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpe'
    'qz8AAAAASUVORK5CYII=',
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_transparentPixel);
  }
}
