import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/vaulted_file.dart';

/// Service for managing vaulted files storage
class VaultService {
  VaultService._();
  static final VaultService instance = VaultService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _vaultIndexKey = 'vault_file_index';
  static const String _vaultFolderName = '.locker_vault';

  Directory? _vaultDirectory;
  List<VaultedFile>? _cachedFiles;

  /// Initialize the vault service
  Future<void> initialize() async {
    await _ensureVaultDirectory();
    await _loadFileIndex();
  }

  /// Get the vault directory
  Future<Directory> _ensureVaultDirectory() async {
    if (_vaultDirectory != null && await _vaultDirectory!.exists()) {
      return _vaultDirectory!;
    }

    final appDir = await getApplicationDocumentsDirectory();
    _vaultDirectory = Directory('${appDir.path}/$_vaultFolderName');

    if (!await _vaultDirectory!.exists()) {
      await _vaultDirectory!.create(recursive: true);
    }

    // Create subdirectories for different file types
    await Directory('${_vaultDirectory!.path}/images').create(recursive: true);
    await Directory('${_vaultDirectory!.path}/videos').create(recursive: true);
    await Directory('${_vaultDirectory!.path}/documents').create(recursive: true);
    await Directory('${_vaultDirectory!.path}/thumbnails').create(recursive: true);

    return _vaultDirectory!;
  }

  /// Get subdirectory path for file type
  String _getSubdirectory(VaultedFileType type) {
    switch (type) {
      case VaultedFileType.image:
        return 'images';
      case VaultedFileType.video:
        return 'videos';
      case VaultedFileType.document:
      case VaultedFileType.other:
        return 'documents';
    }
  }

  /// Load file index from secure storage
  Future<List<VaultedFile>> _loadFileIndex() async {
    if (_cachedFiles != null) return _cachedFiles!;

    try {
      final indexJson = await _storage.read(key: _vaultIndexKey);
      if (indexJson == null || indexJson.isEmpty) {
        _cachedFiles = [];
        return _cachedFiles!;
      }

      final List<dynamic> jsonList = jsonDecode(indexJson);
      _cachedFiles = jsonList
          .map((json) => VaultedFile.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedFiles!;
    } catch (e) {
      debugPrint('Error loading vault index: $e');
      _cachedFiles = [];
      return _cachedFiles!;
    }
  }

  /// Save file index to secure storage
  Future<void> _saveFileIndex() async {
    try {
      final jsonList = _cachedFiles?.map((file) => file.toJson()).toList() ?? [];
      await _storage.write(key: _vaultIndexKey, value: jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving vault index: $e');
    }
  }

  /// Generate a unique encrypted filename
  String _generateVaultFilename(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = utf8.encode('$originalName$timestamp${DateTime.now()}');
    final hash = sha256.convert(randomBytes).toString().substring(0, 16);
    
    final extension = originalName.contains('.')
        ? originalName.split('.').last
        : '';
    
    return extension.isNotEmpty ? '$hash.$extension' : hash;
  }

  /// Add a file to the vault
  Future<VaultedFile?> addFile({
    required String sourcePath,
    required String originalName,
    required VaultedFileType type,
    required String mimeType,
    bool deleteOriginal = false,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        debugPrint('Source file does not exist: $sourcePath');
        return null;
      }

      await _ensureVaultDirectory();
      
      final vaultFilename = _generateVaultFilename(originalName);
      final subdirectory = _getSubdirectory(type);
      final vaultPath = '${_vaultDirectory!.path}/$subdirectory/$vaultFilename';
      
      // Copy file to vault
      await sourceFile.copy(vaultPath);
      
      final fileSize = await sourceFile.length();
      final fileId = sha256
          .convert(utf8.encode('$vaultPath${DateTime.now().millisecondsSinceEpoch}'))
          .toString()
          .substring(0, 24);

      final vaultedFile = VaultedFile(
        id: fileId,
        originalName: originalName,
        vaultPath: vaultPath,
        originalPath: sourcePath,
        type: type,
        mimeType: mimeType,
        fileSize: fileSize,
        dateAdded: DateTime.now(),
      );

      // Add to index
      _cachedFiles ??= [];
      _cachedFiles!.add(vaultedFile);
      await _saveFileIndex();

      // Delete original if requested
      if (deleteOriginal) {
        try {
          await sourceFile.delete();
        } catch (e) {
          debugPrint('Could not delete original file: $e');
        }
      }

      return vaultedFile;
    } catch (e) {
      debugPrint('Error adding file to vault: $e');
      return null;
    }
  }

  /// Add multiple files to the vault (batch import)
  Future<List<VaultedFile>> addFiles({
    required List<FileToVault> files,
    bool deleteOriginals = false,
    Function(int current, int total)? onProgress,
  }) async {
    final results = <VaultedFile>[];
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      onProgress?.call(i + 1, files.length);
      
      final result = await addFile(
        sourcePath: file.sourcePath,
        originalName: file.originalName,
        type: file.type,
        mimeType: file.mimeType,
        deleteOriginal: deleteOriginals,
      );
      
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }

  /// Remove a file from the vault
  Future<bool> removeFile(String fileId) async {
    try {
      final files = await _loadFileIndex();
      final fileIndex = files.indexWhere((f) => f.id == fileId);
      
      if (fileIndex == -1) return false;
      
      final file = files[fileIndex];
      
      // Delete the actual file
      final vaultFile = File(file.vaultPath);
      if (await vaultFile.exists()) {
        await vaultFile.delete();
      }
      
      // Delete thumbnail if exists
      if (file.thumbnailPath != null) {
        final thumbFile = File(file.thumbnailPath!);
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      }
      
      // Remove from index
      _cachedFiles!.removeAt(fileIndex);
      await _saveFileIndex();
      
      return true;
    } catch (e) {
      debugPrint('Error removing file from vault: $e');
      return false;
    }
  }

  /// Remove multiple files from the vault
  Future<int> removeFiles(List<String> fileIds) async {
    int removed = 0;
    for (final id in fileIds) {
      if (await removeFile(id)) {
        removed++;
      }
    }
    return removed;
  }

  /// Get all vaulted files
  Future<List<VaultedFile>> getAllFiles() async {
    return await _loadFileIndex();
  }

  /// Get files by type
  Future<List<VaultedFile>> getFilesByType(VaultedFileType type) async {
    final files = await _loadFileIndex();
    return files.where((f) => f.type == type).toList();
  }

  /// Get file by ID
  Future<VaultedFile?> getFileById(String fileId) async {
    final files = await _loadFileIndex();
    try {
      return files.firstWhere((f) => f.id == fileId);
    } catch (e) {
      return null;
    }
  }

  /// Get the actual file from vault
  Future<File?> getVaultedFile(String fileId) async {
    final vaultedFile = await getFileById(fileId);
    if (vaultedFile == null) return null;
    
    final file = File(vaultedFile.vaultPath);
    if (!await file.exists()) return null;
    
    return file;
  }

  /// Get file counts by type
  Future<Map<VaultedFileType, int>> getFileCounts() async {
    final files = await _loadFileIndex();
    final counts = <VaultedFileType, int>{};
    
    for (final type in VaultedFileType.values) {
      counts[type] = files.where((f) => f.type == type).length;
    }
    
    return counts;
  }

  /// Get total storage used
  Future<int> getTotalStorageUsed() async {
    final files = await _loadFileIndex();
    return files.fold<int>(0, (sum, file) => sum + file.fileSize);
  }

  /// Export a file from vault to a location
  Future<File?> exportFile(String fileId, String destinationPath) async {
    try {
      final vaultedFile = await getFileById(fileId);
      if (vaultedFile == null) return null;
      
      final sourceFile = File(vaultedFile.vaultPath);
      if (!await sourceFile.exists()) return null;
      
      return await sourceFile.copy(destinationPath);
    } catch (e) {
      debugPrint('Error exporting file: $e');
      return null;
    }
  }

  /// Search files by name
  Future<List<VaultedFile>> searchFiles(String query) async {
    final files = await _loadFileIndex();
    final lowerQuery = query.toLowerCase();
    return files
        .where((f) => f.originalName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Clear all vault data (use with caution!)
  Future<void> clearVault() async {
    try {
      if (_vaultDirectory != null && await _vaultDirectory!.exists()) {
        await _vaultDirectory!.delete(recursive: true);
      }
      _cachedFiles = [];
      await _storage.delete(key: _vaultIndexKey);
      _vaultDirectory = null;
    } catch (e) {
      debugPrint('Error clearing vault: $e');
    }
  }

  /// Refresh the cache
  Future<void> refresh() async {
    _cachedFiles = null;
    await _loadFileIndex();
  }
}

/// Helper class for batch file import
class FileToVault {
  final String sourcePath;
  final String originalName;
  final VaultedFileType type;
  final String mimeType;

  const FileToVault({
    required this.sourcePath,
    required this.originalName,
    required this.type,
    required this.mimeType,
  });
}

