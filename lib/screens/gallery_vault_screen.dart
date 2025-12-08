import 'dart:io';
import 'package:flutter/material.dart';
import '../models/vaulted_file.dart';
import '../services/file_import_service.dart';
import '../services/vault_service.dart';
import '../themes/app_colors.dart';
import '../utils/toast_utils.dart';

/// Gallery vault screen - main screen after authentication
class GalleryVaultScreen extends StatefulWidget {
  const GalleryVaultScreen({super.key});

  @override
  State<GalleryVaultScreen> createState() => _GalleryVaultScreenState();
}

class _GalleryVaultScreenState extends State<GalleryVaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VaultService _vaultService = VaultService.instance;
  final FileImportService _importService = FileImportService.instance;

  List<VaultedFile> _allFiles = [];
  bool _isLoading = true;
  bool _isImporting = false;
  int _importProgress = 0;
  int _importTotal = 0;
  Set<String> _selectedFiles = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeVault();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeVault() async {
    await _vaultService.initialize();
    await _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await _vaultService.getAllFiles();
      setState(() {
        _allFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('Failed to load files');
    }
  }

  List<VaultedFile> _getFilteredFiles(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _allFiles;
      case 1:
        return _allFiles.where((f) => f.type == VaultedFileType.image).toList();
      case 2:
        return _allFiles.where((f) => f.type == VaultedFileType.video).toList();
      case 3:
        return _allFiles
            .where((f) =>
                f.type == VaultedFileType.document ||
                f.type == VaultedFileType.other)
            .toList();
      default:
        return _allFiles;
    }
  }

  void _showImportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ImportOptionsSheet(
        onImportImages: _importImagesFromGallery,
        onImportVideos: _importVideosFromGallery,
        onImportMedia: _importMediaFromGallery,
        onCapturePhoto: _capturePhoto,
        onRecordVideo: _recordVideo,
        onImportDocuments: _importDocuments,
        onImportAnyFiles: _importAnyFiles,
      ),
    );
  }

  Future<void> _importImagesFromGallery() async {
    Navigator.pop(context);
    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = 0;
    });

    final result = await _importService.importImagesFromGallery(
      onProgress: (current, total) {
        setState(() {
          _importProgress = current;
          _importTotal = total;
        });
      },
    );

    setState(() => _isImporting = false);

    if (result.success && result.importedCount > 0) {
      ToastUtils.showSuccess('Imported ${result.importedCount} image(s)');
      await _loadFiles();
    } else if (!result.success) {
      ToastUtils.showError(result.error ?? 'Import failed');
    } else {
      ToastUtils.showInfo('No images selected');
    }
  }

  Future<void> _importVideosFromGallery() async {
    Navigator.pop(context);
    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = 0;
    });

    final result = await _importService.importVideosFromGallery(
      onProgress: (current, total) {
        setState(() {
          _importProgress = current;
          _importTotal = total;
        });
      },
    );

    setState(() => _isImporting = false);

    if (result.success && result.importedCount > 0) {
      ToastUtils.showSuccess('Imported ${result.importedCount} video(s)');
      await _loadFiles();
    } else if (!result.success) {
      ToastUtils.showError(result.error ?? 'Import failed');
    } else {
      ToastUtils.showInfo('No videos selected');
    }
  }

  Future<void> _importMediaFromGallery() async {
    Navigator.pop(context);
    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = 0;
    });

    final result = await _importService.importMediaFromGallery(
      onProgress: (current, total) {
        setState(() {
          _importProgress = current;
          _importTotal = total;
        });
      },
    );

    setState(() => _isImporting = false);

    if (result.success && result.importedCount > 0) {
      ToastUtils.showSuccess('Imported ${result.importedCount} file(s)');
      await _loadFiles();
    } else if (!result.success) {
      ToastUtils.showError(result.error ?? 'Import failed');
    } else {
      ToastUtils.showInfo('No media selected');
    }
  }

  Future<void> _capturePhoto() async {
    Navigator.pop(context);
    setState(() => _isImporting = true);

    final result = await _importService.capturePhotoFromCamera();

    setState(() => _isImporting = false);

    if (result.success && result.importedCount > 0) {
      ToastUtils.showSuccess('Photo saved to vault');
      await _loadFiles();
    } else if (!result.success) {
      ToastUtils.showError(result.error ?? 'Capture failed');
    }
  }

  Future<void> _recordVideo() async {
    Navigator.pop(context);
    setState(() => _isImporting = true);

    final result = await _importService.recordVideoFromCamera();

    setState(() => _isImporting = false);

    if (result.success && result.importedCount > 0) {
      ToastUtils.showSuccess('Video saved to vault');
      await _loadFiles();
    } else if (!result.success) {
      ToastUtils.showError(result.error ?? 'Recording failed');
    }
  }

  Future<void> _importDocuments() async {
    Navigator.pop(context);
    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = 0;
    });

    final result = await _importService.importDocuments(
      onProgress: (current, total) {
        setState(() {
          _importProgress = current;
          _importTotal = total;
        });
      },
    );

    setState(() => _isImporting = false);

    if (result.success && result.importedCount > 0) {
      ToastUtils.showSuccess('Imported ${result.importedCount} document(s)');
      await _loadFiles();
    } else if (!result.success) {
      ToastUtils.showError(result.error ?? 'Import failed');
    } else {
      ToastUtils.showInfo('No documents selected');
    }
  }

  Future<void> _importAnyFiles() async {
    Navigator.pop(context);
    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = 0;
    });

    final result = await _importService.importAnyFiles(
      onProgress: (current, total) {
        setState(() {
          _importProgress = current;
          _importTotal = total;
        });
      },
    );

    setState(() => _isImporting = false);

    if (result.success && result.importedCount > 0) {
      ToastUtils.showSuccess('Imported ${result.importedCount} file(s)');
      await _loadFiles();
    } else if (!result.success) {
      ToastUtils.showError(result.error ?? 'Import failed');
    } else {
      ToastUtils.showInfo('No files selected');
    }
  }

  void _toggleSelection(String fileId) {
    setState(() {
      if (_selectedFiles.contains(fileId)) {
        _selectedFiles.remove(fileId);
        if (_selectedFiles.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFiles.add(fileId);
      }
    });
  }

  void _enterSelectionMode(String fileId) {
    setState(() {
      _isSelectionMode = true;
      _selectedFiles.add(fileId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedFiles.clear();
    });
  }

  Future<void> _deleteSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightBackground,
        title: Text(
          'Delete Files',
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedFiles.length} file(s)? This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: AppColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deleted = await _vaultService.removeFiles(_selectedFiles.toList());
      ToastUtils.showSuccess('Deleted $deleted file(s)');
      _exitSelectionMode();
      await _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isImporting) _buildImportProgress(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFileGrid(0),
                _buildFileGrid(1),
                _buildFileGrid(2),
                _buildFileGrid(3),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: AppColors.accent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          '${_selectedFiles.length} selected',
          style: const TextStyle(
            fontFamily: 'ProductSans',
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _deleteSelectedFiles,
          ),
        ],
      );
    }

    return AppBar(
      title: Text(
        'Gallery Vault',
        style: TextStyle(
          fontFamily: 'ProductSans',
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: AppColors.lightTextPrimary),
          onPressed: () {
            // TODO: Add search functionality
            ToastUtils.showInfo('Search coming soon');
          },
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: AppColors.lightTextPrimary),
          onPressed: () {
            // TODO: Add settings menu
          },
        ),
      ],
    );
  }

  Widget _buildImportProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.accent.withValues(alpha: 0.1),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
              value: _importTotal > 0 ? _importProgress / _importTotal : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _importTotal > 0
                  ? 'Importing... $_importProgress / $_importTotal'
                  : 'Importing...',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.lightTextTertiary,
        indicatorColor: AppColors.accent,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontFamily: 'ProductSans',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'ProductSans',
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.grid_view_rounded, size: 18),
                const SizedBox(width: 6),
                Text('All (${_allFiles.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                    'Images (${_allFiles.where((f) => f.type == VaultedFileType.image).length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                    'Videos (${_allFiles.where((f) => f.type == VaultedFileType.video).length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                    'Docs (${_allFiles.where((f) => f.type == VaultedFileType.document || f.type == VaultedFileType.other).length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGrid(int tabIndex) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.accent),
        ),
      );
    }

    final files = _getFilteredFiles(tabIndex);

    if (files.isEmpty) {
      return _buildEmptyState(tabIndex);
    }

    return RefreshIndicator(
      onRefresh: _loadFiles,
      color: AppColors.accent,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return _buildFileItem(file);
        },
      ),
    );
  }

  Widget _buildFileItem(VaultedFile file) {
    final isSelected = _selectedFiles.contains(file.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(file.id);
        } else {
          _openFile(file);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(file.id);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightBackgroundSecondary,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: AppColors.accent, width: 3)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSelected ? 5 : 8),
              child: _buildFileThumbnail(file),
            ),
          ),
          // Selection indicator
          if (_isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.accent : Colors.white,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.accent : AppColors.lightBorder,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          // Video duration indicator
          if (file.isVideo)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, size: 14, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      file.formattedSize,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'ProductSans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // File type badge for documents
          if (file.isDocument)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  file.originalName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'ProductSans',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileThumbnail(VaultedFile file) {
    if (file.isImage) {
      return Image.file(
        File(file.vaultPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(file);
        },
      );
    }
    return _buildPlaceholder(file);
  }

  Widget _buildPlaceholder(VaultedFile file) {
    IconData icon;
    Color color;

    switch (file.type) {
      case VaultedFileType.image:
        icon = Icons.image;
        color = Colors.blue;
        break;
      case VaultedFileType.video:
        icon = Icons.videocam;
        color = Colors.red;
        break;
      case VaultedFileType.document:
        icon = _getDocumentIcon(file.extension);
        color = _getDocumentColor(file.extension);
        break;
      case VaultedFileType.other:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
        break;
    }

    return Container(
      color: color.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              file.extension.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'ProductSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  void _openFile(VaultedFile file) {
    // TODO: Implement file viewer
    ToastUtils.showInfo('Opening ${file.originalName}');
  }

  Widget _buildEmptyState(int tabIndex) {
    String title;
    String subtitle;
    IconData icon;

    switch (tabIndex) {
      case 0:
        title = 'No files yet';
        subtitle = 'Your hidden files will appear here';
        icon = Icons.folder_open_outlined;
        break;
      case 1:
        title = 'No images yet';
        subtitle = 'Import images from gallery or camera';
        icon = Icons.image_outlined;
        break;
      case 2:
        title = 'No videos yet';
        subtitle = 'Import videos from gallery or camera';
        icon = Icons.videocam_outlined;
        break;
      case 3:
        title = 'No documents yet';
        subtitle = 'Import PDFs, Word docs, and more';
        icon = Icons.description_outlined;
        break;
      default:
        title = 'No files yet';
        subtitle = 'Tap + to add files';
        icon = Icons.folder_open_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightBackgroundSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
              fontFamily: 'ProductSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.lightTextSecondary,
              fontFamily: 'ProductSans',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showImportDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showImportDialog,
      backgroundColor: AppColors.accent,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Import',
        style: TextStyle(
          fontFamily: 'ProductSans',
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Import options bottom sheet
class _ImportOptionsSheet extends StatelessWidget {
  final VoidCallback onImportImages;
  final VoidCallback onImportVideos;
  final VoidCallback onImportMedia;
  final VoidCallback onCapturePhoto;
  final VoidCallback onRecordVideo;
  final VoidCallback onImportDocuments;
  final VoidCallback onImportAnyFiles;

  const _ImportOptionsSheet({
    required this.onImportImages,
    required this.onImportVideos,
    required this.onImportMedia,
    required this.onCapturePhoto,
    required this.onRecordVideo,
    required this.onImportDocuments,
    required this.onImportAnyFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Files',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightTextPrimary,
                    fontFamily: 'ProductSans',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose where to import from',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.lightTextSecondary,
                    fontFamily: 'ProductSans',
                  ),
                ),
                const SizedBox(height: 24),

                // Gallery section
                _buildSectionHeader('From Gallery'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ImportOptionTile(
                        icon: Icons.photo_library_outlined,
                        label: 'Images',
                        color: Colors.blue,
                        onTap: onImportImages,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImportOptionTile(
                        icon: Icons.video_library_outlined,
                        label: 'Videos',
                        color: Colors.red,
                        onTap: onImportVideos,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImportOptionTile(
                        icon: Icons.perm_media_outlined,
                        label: 'All Media',
                        color: Colors.purple,
                        onTap: onImportMedia,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Camera section
                _buildSectionHeader('From Camera'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ImportOptionTile(
                        icon: Icons.camera_alt_outlined,
                        label: 'Take Photo',
                        color: Colors.teal,
                        onTap: onCapturePhoto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImportOptionTile(
                        icon: Icons.videocam_outlined,
                        label: 'Record Video',
                        color: Colors.orange,
                        onTap: onRecordVideo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()), // Placeholder
                  ],
                ),

                const SizedBox(height: 24),

                // Documents section
                _buildSectionHeader('From File Manager'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ImportOptionTile(
                        icon: Icons.description_outlined,
                        label: 'Documents',
                        color: Colors.green,
                        onTap: onImportDocuments,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImportOptionTile(
                        icon: Icons.folder_open_outlined,
                        label: 'Any File',
                        color: Colors.blueGrey,
                        onTap: onImportAnyFiles,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()), // Placeholder
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextTertiary,
        fontFamily: 'ProductSans',
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ImportOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImportOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'ProductSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
