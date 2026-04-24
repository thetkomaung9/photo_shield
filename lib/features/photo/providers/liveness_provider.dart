import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/liveness_check.dart';

class LivenessNotifier extends StateNotifier<LivenessCheck> {
  LivenessNotifier() : super(const LivenessCheck());

  static const List<String> _challenges = [
    'livenessPromptBlink',
    'livenessPromptTurnLeft',
    'livenessPromptSmile',
  ];

  Future<String?> runCheck(ImagePicker picker) async {
    final challengeKey =
        _challenges[DateTime.now().millisecondsSinceEpoch % _challenges.length];
    state = state.copyWith(
      isChecking: true,
      challengeKey: challengeKey,
      clearError: true,
    );

    final capture = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );

    if (capture == null) {
      state = state.copyWith(
        isChecking: false,
        isVerified: false,
        error: 'Live camera check was cancelled.',
      );
      return state.error;
    }

    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      isChecking: false,
      isVerified: true,
      capturePath: capture.path,
      verifiedAt: DateTime.now(),
      clearError: true,
    );
    return null;
  }

  void reset() {
    state = const LivenessCheck();
  }
}

final livenessProvider = StateNotifierProvider<LivenessNotifier, LivenessCheck>(
  (ref) => LivenessNotifier(),
);
