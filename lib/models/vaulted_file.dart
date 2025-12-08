import 'dart:convert';

/// Enum representing the type of file stored in the vault
enum VaultedFileType {
  image,
  video,
  document,
  other;

  String get displayName {
    switch (this) {
      case VaultedFileType.image:
        return 'Image';
      case VaultedFileType.video:
        return 'Video';
      case VaultedFileType.document:
        return 'Document';
      case VaultedFileType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case VaultedFileType.image:
        return 'picture_icon.png';
      case VaultedFileType.video:
        return 'video_icon.png';
      case VaultedFileType.document:
      case VaultedFileType.other:
        return 'otherfiles_icon.png';
    }
  }

  static VaultedFileType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return VaultedFileType.image;
      case 'video':
        return VaultedFileType.video;
      case 'document':
        return VaultedFileType.document;
      default:
        return VaultedFileType.other;
    }
  }
}

/// Model representing a file stored in the vault
class VaultedFile {
  final String id;
  final String originalName;
  final String vaultPath;
  final String? originalPath;
  final VaultedFileType type;
  final String mimeType;
  final int fileSize;
  final DateTime dateAdded;
  final DateTime? dateModified;
  final String? thumbnailPath;
  final Map<String, dynamic>? metadata;

  const VaultedFile({
    required this.id,
    required this.originalName,
    required this.vaultPath,
    this.originalPath,
    required this.type,
    required this.mimeType,
    required this.fileSize,
    required this.dateAdded,
    this.dateModified,
    this.thumbnailPath,
    this.metadata,
  });

  /// Create a copy with updated fields
  VaultedFile copyWith({
    String? id,
    String? originalName,
    String? vaultPath,
    String? originalPath,
    VaultedFileType? type,
    String? mimeType,
    int? fileSize,
    DateTime? dateAdded,
    DateTime? dateModified,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
  }) {
    return VaultedFile(
      id: id ?? this.id,
      originalName: originalName ?? this.originalName,
      vaultPath: vaultPath ?? this.vaultPath,
      originalPath: originalPath ?? this.originalPath,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalName': originalName,
      'vaultPath': vaultPath,
      'originalPath': originalPath,
      'type': type.name,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'dateAdded': dateAdded.toIso8601String(),
      'dateModified': dateModified?.toIso8601String(),
      'thumbnailPath': thumbnailPath,
      'metadata': metadata,
    };
  }

  /// Create from JSON map
  factory VaultedFile.fromJson(Map<String, dynamic> json) {
    return VaultedFile(
      id: json['id'] as String,
      originalName: json['originalName'] as String,
      vaultPath: json['vaultPath'] as String,
      originalPath: json['originalPath'] as String?,
      type: VaultedFileType.fromString(json['type'] as String),
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      dateModified: json['dateModified'] != null
          ? DateTime.parse(json['dateModified'] as String)
          : null,
      thumbnailPath: json['thumbnailPath'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create from JSON string
  factory VaultedFile.fromJsonString(String jsonString) {
    return VaultedFile.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Get file extension from original name
  String get extension {
    final parts = originalName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Get formatted file size
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Check if file is an image
  bool get isImage => type == VaultedFileType.image;

  /// Check if file is a video
  bool get isVideo => type == VaultedFileType.video;

  /// Check if file is a document
  bool get isDocument => type == VaultedFileType.document;

  @override
  String toString() {
    return 'VaultedFile(id: $id, name: $originalName, type: $type, size: $formattedSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VaultedFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Supported image extensions
const List<String> supportedImageExtensions = [
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'tiff', 'tif'
];

/// Supported video extensions
const List<String> supportedVideoExtensions = [
  'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv', 'm4v', '3gp'
];

/// Supported document extensions
const List<String> supportedDocumentExtensions = [
  'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
  'txt', 'rtf', 'csv', 'odt', 'ods', 'odp', 'epub'
];

/// Get file type from extension
VaultedFileType getFileTypeFromExtension(String extension) {
  final ext = extension.toLowerCase().replaceAll('.', '');
  
  if (supportedImageExtensions.contains(ext)) {
    return VaultedFileType.image;
  } else if (supportedVideoExtensions.contains(ext)) {
    return VaultedFileType.video;
  } else if (supportedDocumentExtensions.contains(ext)) {
    return VaultedFileType.document;
  }
  return VaultedFileType.other;
}

/// Get file type from MIME type
VaultedFileType getFileTypeFromMime(String mimeType) {
  final mime = mimeType.toLowerCase();
  
  if (mime.startsWith('image/')) {
    return VaultedFileType.image;
  } else if (mime.startsWith('video/')) {
    return VaultedFileType.video;
  } else if (mime.startsWith('application/pdf') ||
             mime.startsWith('application/msword') ||
             mime.startsWith('application/vnd.') ||
             mime.startsWith('text/')) {
    return VaultedFileType.document;
  }
  return VaultedFileType.other;
}

