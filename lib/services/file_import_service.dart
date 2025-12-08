import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../models/vaulted_file.dart';
import 'permission_service.dart';
import 'vault_service.dart';

/// Service for importing files from various sources
class FileImportService {
  FileImportService._();
  static final FileImportService instance = FileImportService._();

  final ImagePicker _imagePicker = ImagePicker();
  final PermissionService _permissionService = PermissionService.instance;
  final VaultService _vaultService = VaultService.instance;

  /// Import images from gallery (multiple selection)
  Future<ImportResult> importImagesFromGallery({
    bool deleteOriginals = false,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Request permission
      final hasPermission = await _permissionService.requestPhotosPermission();
      if (!hasPermission) {
        return ImportResult(
          success: false,
          error: 'Photo library permission denied',
          importedFiles: [],
        );
      }

      // Pick multiple images
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 100,
      );

      if (images.isEmpty) {
        return ImportResult(
          success: true,
          importedFiles: [],
          message: 'No images selected',
        );
      }

      // Convert to FileToVault list
      final filesToVault = <FileToVault>[];
      for (final image in images) {
        final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
        filesToVault.add(FileToVault(
          sourcePath: image.path,
          originalName: image.name,
          type: VaultedFileType.image,
          mimeType: mimeType,
        ));
      }

      // Add to vault
      final imported = await _vaultService.addFiles(
        files: filesToVault,
        deleteOriginals: deleteOriginals,
        onProgress: onProgress,
      );

      return ImportResult(
        success: true,
        importedFiles: imported,
        message: 'Imported ${imported.length} image(s)',
      );
    } catch (e) {
      debugPrint('Error importing images from gallery: $e');
      return ImportResult(
        success: false,
        error: 'Failed to import images: $e',
        importedFiles: [],
      );
    }
  }

  /// Import videos from gallery (multiple selection)
  Future<ImportResult> importVideosFromGallery({
    bool deleteOriginals = false,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Request permission
      final hasPermission = await _permissionService.requestVideosPermission();
      if (!hasPermission) {
        return ImportResult(
          success: false,
          error: 'Video library permission denied',
          importedFiles: [],
        );
      }

      // Pick video - ImagePicker doesn't support multi video, use file_picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: true,
          importedFiles: [],
          message: 'No videos selected',
        );
      }

      // Convert to FileToVault list
      final filesToVault = <FileToVault>[];
      for (final file in result.files) {
        if (file.path == null) continue;
        
        final mimeType = lookupMimeType(file.path!) ?? 'video/mp4';
        filesToVault.add(FileToVault(
          sourcePath: file.path!,
          originalName: file.name,
          type: VaultedFileType.video,
          mimeType: mimeType,
        ));
      }

      // Add to vault
      final imported = await _vaultService.addFiles(
        files: filesToVault,
        deleteOriginals: deleteOriginals,
        onProgress: onProgress,
      );

      return ImportResult(
        success: true,
        importedFiles: imported,
        message: 'Imported ${imported.length} video(s)',
      );
    } catch (e) {
      debugPrint('Error importing videos from gallery: $e');
      return ImportResult(
        success: false,
        error: 'Failed to import videos: $e',
        importedFiles: [],
      );
    }
  }

  /// Capture photo from camera
  Future<ImportResult> capturePhotoFromCamera() async {
    try {
      // Request camera permission
      final hasPermission = await _permissionService.requestCameraPermission();
      if (!hasPermission) {
        return ImportResult(
          success: false,
          error: 'Camera permission denied',
          importedFiles: [],
        );
      }

      // Capture photo
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image == null) {
        return ImportResult(
          success: true,
          importedFiles: [],
          message: 'No photo captured',
        );
      }

      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      final imported = await _vaultService.addFile(
        sourcePath: image.path,
        originalName: image.name,
        type: VaultedFileType.image,
        mimeType: mimeType,
        deleteOriginal: true, // Camera captures are temporary
      );

      if (imported == null) {
        return ImportResult(
          success: false,
          error: 'Failed to save photo to vault',
          importedFiles: [],
        );
      }

      return ImportResult(
        success: true,
        importedFiles: [imported],
        message: 'Photo captured and saved',
      );
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return ImportResult(
        success: false,
        error: 'Failed to capture photo: $e',
        importedFiles: [],
      );
    }
  }

  /// Record video from camera
  Future<ImportResult> recordVideoFromCamera({
    Duration? maxDuration,
  }) async {
    try {
      // Request permissions
      final hasCamera = await _permissionService.requestCameraPermission();
      final hasMic = await _permissionService.requestMicrophonePermission();
      
      if (!hasCamera) {
        return ImportResult(
          success: false,
          error: 'Camera permission denied',
          importedFiles: [],
        );
      }

      if (!hasMic) {
        return ImportResult(
          success: false,
          error: 'Microphone permission denied',
          importedFiles: [],
        );
      }

      // Record video
      final video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration ?? const Duration(minutes: 10),
      );

      if (video == null) {
        return ImportResult(
          success: true,
          importedFiles: [],
          message: 'No video recorded',
        );
      }

      final mimeType = lookupMimeType(video.path) ?? 'video/mp4';
      final imported = await _vaultService.addFile(
        sourcePath: video.path,
        originalName: video.name,
        type: VaultedFileType.video,
        mimeType: mimeType,
        deleteOriginal: true, // Camera captures are temporary
      );

      if (imported == null) {
        return ImportResult(
          success: false,
          error: 'Failed to save video to vault',
          importedFiles: [],
        );
      }

      return ImportResult(
        success: true,
        importedFiles: [imported],
        message: 'Video recorded and saved',
      );
    } catch (e) {
      debugPrint('Error recording video: $e');
      return ImportResult(
        success: false,
        error: 'Failed to record video: $e',
        importedFiles: [],
      );
    }
  }

  /// Import documents from file manager
  Future<ImportResult> importDocuments({
    bool deleteOriginals = false,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Pick documents
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedDocumentExtensions,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: true,
          importedFiles: [],
          message: 'No documents selected',
        );
      }

      // Convert to FileToVault list
      final filesToVault = <FileToVault>[];
      for (final file in result.files) {
        if (file.path == null) continue;
        
        final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';
        filesToVault.add(FileToVault(
          sourcePath: file.path!,
          originalName: file.name,
          type: VaultedFileType.document,
          mimeType: mimeType,
        ));
      }

      // Add to vault
      final imported = await _vaultService.addFiles(
        files: filesToVault,
        deleteOriginals: deleteOriginals,
        onProgress: onProgress,
      );

      return ImportResult(
        success: true,
        importedFiles: imported,
        message: 'Imported ${imported.length} document(s)',
      );
    } catch (e) {
      debugPrint('Error importing documents: $e');
      return ImportResult(
        success: false,
        error: 'Failed to import documents: $e',
        importedFiles: [],
      );
    }
  }

  /// Import any files from file manager
  Future<ImportResult> importAnyFiles({
    bool deleteOriginals = false,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Pick any files
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: true,
          importedFiles: [],
          message: 'No files selected',
        );
      }

      // Convert to FileToVault list with auto-detected types
      final filesToVault = <FileToVault>[];
      for (final file in result.files) {
        if (file.path == null) continue;
        
        final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';
        final extension = file.extension ?? '';
        final type = getFileTypeFromExtension(extension);
        
        filesToVault.add(FileToVault(
          sourcePath: file.path!,
          originalName: file.name,
          type: type,
          mimeType: mimeType,
        ));
      }

      // Add to vault
      final imported = await _vaultService.addFiles(
        files: filesToVault,
        deleteOriginals: deleteOriginals,
        onProgress: onProgress,
      );

      return ImportResult(
        success: true,
        importedFiles: imported,
        message: 'Imported ${imported.length} file(s)',
      );
    } catch (e) {
      debugPrint('Error importing files: $e');
      return ImportResult(
        success: false,
        error: 'Failed to import files: $e',
        importedFiles: [],
      );
    }
  }

  /// Import media (images and videos) from gallery
  Future<ImportResult> importMediaFromGallery({
    bool deleteOriginals = false,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Request permissions
      final permissions = await _permissionService.requestAllMediaPermissions();
      if (!permissions.mediaGranted) {
        return ImportResult(
          success: false,
          error: 'Media permission denied',
          importedFiles: [],
        );
      }

      // Pick media files (images and videos)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: true,
          importedFiles: [],
          message: 'No media selected',
        );
      }

      // Convert to FileToVault list
      final filesToVault = <FileToVault>[];
      for (final file in result.files) {
        if (file.path == null) continue;
        
        final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';
        final type = getFileTypeFromMime(mimeType);
        
        filesToVault.add(FileToVault(
          sourcePath: file.path!,
          originalName: file.name,
          type: type,
          mimeType: mimeType,
        ));
      }

      // Add to vault
      final imported = await _vaultService.addFiles(
        files: filesToVault,
        deleteOriginals: deleteOriginals,
        onProgress: onProgress,
      );

      return ImportResult(
        success: true,
        importedFiles: imported,
        message: 'Imported ${imported.length} media file(s)',
      );
    } catch (e) {
      debugPrint('Error importing media: $e');
      return ImportResult(
        success: false,
        error: 'Failed to import media: $e',
        importedFiles: [],
      );
    }
  }
}

/// Result of an import operation
class ImportResult {
  final bool success;
  final String? error;
  final String? message;
  final List<VaultedFile> importedFiles;

  const ImportResult({
    required this.success,
    this.error,
    this.message,
    required this.importedFiles,
  });

  int get importedCount => importedFiles.length;

  @override
  String toString() {
    if (success) {
      return 'ImportResult: Success - ${message ?? "Imported $importedCount file(s)"}';
    }
    return 'ImportResult: Failed - $error';
  }
}

