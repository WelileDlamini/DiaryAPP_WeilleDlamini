

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ImagePicker _picker = ImagePicker();
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecorderInitialized = false;
  AudioPlayer? _audioPlayer;
  String? _currentPlayingAudio;

  /// Get the directory where app images will be stored
  Future<Directory> get _imageDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(path.join(appDir.path, 'mydiary_images'));

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    return imageDir;
  }

  /// Get the directory where app audio files will be stored
  Future<Directory> get _audioDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(path.join(appDir.path, 'mydiary_audios'));

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    return audioDir;
  }

  // ==================================================
  // IMAGE METHODS
  // ==================================================

  /// Pick an image from the device gallery
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85, // Compress to save space
      );

      if (image != null) {
        return await _saveImageToLocalDirectory(image);
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
    }
    return null;
  }

  /// Take a photo using the device camera
  Future<String?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImageToLocalDirectory(image);
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
    return null;
  }

  /// Save an image to the app's local directory
  Future<String> _saveImageToLocalDirectory(XFile image) async {
    final imageDir = await _imageDirectory;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final localPath = path.join(imageDir.path, fileName);

    final File localImage = await File(image.path).copy(localPath);
    return localImage.path;
  }

  /// Check if an image exists at the given path
  Future<bool> imageExists(String imagePath) async {
    return await File(imagePath).exists();
  }

  /// Delete an image from local storage
  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
    return false;
  }

  /// Get the size of an image in bytes
  Future<int> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('Error getting image size: $e');
    }
    return 0;
  }

  /// Clean up orphaned images (not referenced in any entry)
  Future<void> cleanOrphanedImages(List<String> referencedImagePaths) async {
    try {
      final imageDir = await _imageDirectory;
      final List<FileSystemEntity> files = imageDir.listSync();

      for (final file in files) {
        if (file is File) {
          if (!referencedImagePaths.contains(file.path)) {
            await file.delete();
            print('Deleted orphaned image: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('Error cleaning orphaned images: $e');
    }
  }

  /// Get storage information for images
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final imageDir = await _imageDirectory;
      final List<FileSystemEntity> files = imageDir.listSync();

      int totalSize = 0;
      int imageCount = 0;

      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
          imageCount++;
        }
      }

      return {
        'imageCount': imageCount,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return {
        'imageCount': 0,
        'totalSizeBytes': 0,
        'totalSizeMB': '0.00',
      };
    }
  }

 

  /// Initialize the audio recorder
  Future<bool> _initializeRecorder() async {
    try {
      _audioRecorder ??= FlutterSoundRecorder();

      if (!_isRecorderInitialized) {
        await _audioRecorder!.openRecorder();
        _isRecorderInitialized = true;
      }
      return true;
    } catch (e) {
      print('Error initializing recorder: $e');
      return false;
    }
  }

  /// Check microphone permission status
  Future<bool> checkMicrophonePermission() async {
    try {
      // Check if we already have permission
      PermissionStatus status = await Permission.microphone.status;

      if (status.isGranted) {
        return true;
      }

      // If not, request it
      status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      print('Error checking microphone permission: $e');
      return false;
    }
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      if (!await _initializeRecorder()) {
        return false;
      }

      final audioDir = await _audioDirectory;
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      final filePath = path.join(audioDir.path, fileName);

      await _audioRecorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      if (_audioRecorder != null && _audioRecorder!.isRecording) {
        return await _audioRecorder!.stopRecorder();
      }
      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  /// Check if currently recording
  Future<bool> isRecording() async {
    try {
      return _audioRecorder?.isRecording ?? false;
    } catch (e) {
      print('Error checking recording state: $e');
      return false;
    }
  }

  /// Dispose recorder resources
  Future<void> disposeRecorder() async {
    try {
      if (_audioRecorder != null) {
        await _audioRecorder!.closeRecorder();
        _audioRecorder = null;
        _isRecorderInitialized = false;
      }
    } catch (e) {
      print('Error disposing recorder: $e');
    }
  }

  /// Delete an audio file from local storage
  Future<bool> deleteAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting audio: $e');
    }
    return false;
  }



  /// Get duration of an audio file
  Future<Duration?> getAudioDuration(String audioPath) async {
    try {
      _audioPlayer ??= AudioPlayer();

      await _audioPlayer!.setFilePath(audioPath);
      final duration = _audioPlayer!.duration;
      return duration;
    } catch (e) {
      print('Error getting audio duration: $e');
      return null;
    }
  }

  /// Play an audio file
  Future<bool> playAudio(String audioPath) async {
    try {
      _audioPlayer ??= AudioPlayer();

      // Stop current audio if playing
      if (_audioPlayer!.playing) {
        await _audioPlayer!.stop();
      }

      await _audioPlayer!.setFilePath(audioPath);
      await _audioPlayer!.play();
      _currentPlayingAudio = audioPath;
      return true;
    } catch (e) {
      print('Error playing audio: $e');
      return false;
    }
  }

  /// Pause audio playback
  Future<void> pauseAudio() async {
    try {
      if (_audioPlayer != null && _audioPlayer!.playing) {
        await _audioPlayer!.pause();
      }
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  /// Stop audio playback
  Future<void> stopAudio() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        _currentPlayingAudio = null;
      }
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  /// Check if audio is currently playing
  bool get isPlaying => _audioPlayer?.playing ?? false;

  /// Get the currently playing audio path
  String? get currentPlayingAudio => _currentPlayingAudio;

  /// Get current playback position
  Duration get currentPosition => _audioPlayer?.position ?? Duration.zero;

  /// Dispose player resources
  Future<void> disposePlayer() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.dispose();
        _audioPlayer = null;
        _currentPlayingAudio = null;
      }
    } catch (e) {
      print('Error disposing player: $e');
    }
  }

  /// Format duration to a readable string
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }
}