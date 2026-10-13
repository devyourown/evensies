/// Where receipt photos live on this device: files on phones, memory in the browser (docs/API.md, Web app: an unsent
/// photo on the web is gone with the tab).
library;

export 'blob_store_memory.dart' if (dart.library.io) 'blob_store_io.dart';

/// `pending`: prepared, not uploaded yet (kept); `cache`: uploaded or downloaded (the OS may clear it).
enum BlobArea { pending, cache }
