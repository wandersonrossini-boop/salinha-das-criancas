class ImageHelper {
  /// Converts a URL (especially Google Drive/Google User Content) to a direct, CORS-friendly URL.
  /// Uses images.weserv.nl as a reliable proxy to bypass browser CORS restrictions on Flutter Web.
  static String getProxiedImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    
    final trimmed = url.trim();
    
    // Handle Google Drive / User Content links
    if (trimmed.contains('drive.google.com') || trimmed.contains('googleusercontent.com')) {
      String fileId = '';
      
      // Matches /file/d/[ID]/view or similar
      final regExpFile = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
      final matchFile = regExpFile.firstMatch(trimmed);
      if (matchFile != null && matchFile.groupCount >= 1) {
        fileId = matchFile.group(1)!;
      } else {
        // Matches ?id=[ID] or &id=[ID]
        final regExpId = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
        final matchId = regExpId.firstMatch(trimmed);
        if (matchId != null && matchId.groupCount >= 1) {
          fileId = matchId.group(1)!;
        } else {
          // Matches /d/[ID] (for lh3.googleusercontent.com/d/ID)
          final regExpContent = RegExp(r'/d/([a-zA-Z0-9_-]+)');
          final matchContent = regExpContent.firstMatch(trimmed);
          if (matchContent != null && matchContent.groupCount >= 1) {
            fileId = matchContent.group(1)!;
          }
        }
      }
      
      if (fileId.isNotEmpty) {
        // We use images.weserv.nl which is a Cloudflare-backed open source image proxy.
        // It bypasses CORS perfectly on Flutter Web and caches images for fast loading.
        return 'https://images.weserv.nl/?url=drive.google.com/uc?export=view%26id=$fileId';
      }
    }
    
    return trimmed;
  }
}
