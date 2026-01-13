import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/video_creation_options.dart';
import '../../../../core/api/video_service.dart';

/// Video Creation State
class VideoCreationState {
  final int currentStep;
  final VideoCreationOptions options;
  final bool isSubmitting;
  final String? error;

  const VideoCreationState({
    this.currentStep = 1,
    this.options = const VideoCreationOptions(),
    this.isSubmitting = false,
    this.error,
  });

  VideoCreationState copyWith({
    int? currentStep,
    VideoCreationOptions? options,
    bool? isSubmitting,
    String? error,
  }) {
    return VideoCreationState(
      currentStep: currentStep ?? this.currentStep,
      options: options ?? this.options,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }

  /// Step 1 validation: URL must be valid YouTube
  bool get isStep1Valid => options.youtubeVideoId != null;

  /// Step 2 validation: always valid (optional settings)
  bool get isStep2Valid => true;

  /// Step 3 validation: always valid (optional settings)
  bool get isStep3Valid => true;

  /// Can submit
  bool get canSubmit => isStep1Valid && isStep2Valid && isStep3Valid;
}

/// Video Creation Notifier
class VideoCreationNotifier extends StateNotifier<VideoCreationState> {
  final VideoService _videoService;

  VideoCreationNotifier(this._videoService) : super(const VideoCreationState());

  // Navigation
  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setStep(int step) {
    if (step >= 1 && step <= 3) {
      state = state.copyWith(currentStep: step);
    }
  }

  // Source URL
  void setSourceUrl(String url) {
    state = state.copyWith(
      options: state.options.copyWith(sourceUrl: url),
    );
  }

  // Voice
  void setVoiceId(String voiceId) {
    state = state.copyWith(
      options: state.options.copyWith(voiceId: voiceId),
    );
  }

  // Language
  void setLanguage(String language) {
    state = state.copyWith(
      options: state.options.copyWith(language: language),
    );
  }

  // Aspect Ratio
  void setAspectRatio(String aspectRatio) {
    state = state.copyWith(
      options: state.options.copyWith(aspectRatio: aspectRatio),
    );
  }

  // Copyright Options
  void updateCopyrightOptions(CopyrightOptions copyrightOptions) {
    state = state.copyWith(
      options: state.options.copyWith(copyrightOptions: copyrightOptions),
    );
  }

  void toggleColorAdjust() {
    final current = state.options.copyrightOptions;
    updateCopyrightOptions(current.copyWith(colorAdjust: !current.colorAdjust));
  }

  void toggleHorizontalFlip() {
    final current = state.options.copyrightOptions;
    updateCopyrightOptions(current.copyWith(horizontalFlip: !current.horizontalFlip));
  }

  void toggleSlightZoom() {
    final current = state.options.copyrightOptions;
    updateCopyrightOptions(current.copyWith(slightZoom: !current.slightZoom));
  }

  void toggleAudioPitchShift() {
    final current = state.options.copyrightOptions;
    updateCopyrightOptions(current.copyWith(audioPitchShift: !current.audioPitchShift));
  }

  void setPitchValue(double value) {
    final current = state.options.copyrightOptions;
    updateCopyrightOptions(current.copyWith(pitchValue: value));
  }

  // Subtitle Options
  void updateSubtitleOptions(SubtitleOptions subtitleOptions) {
    state = state.copyWith(
      options: state.options.copyWith(subtitleOptions: subtitleOptions),
    );
  }

  void toggleSubtitles() {
    final current = state.options.subtitleOptions;
    updateSubtitleOptions(current.copyWith(enabled: !current.enabled));
  }

  // Logo Options
  void updateLogoOptions(LogoOptions logoOptions) {
    state = state.copyWith(
      options: state.options.copyWith(logoOptions: logoOptions),
    );
  }

  void toggleLogo() {
    final current = state.options.logoOptions;
    updateLogoOptions(current.copyWith(enabled: !current.enabled));
  }

  void setLogoPath(String path) {
    final current = state.options.logoOptions;
    // Enable logo when a file is picked
    updateLogoOptions(current.copyWith(localFilePath: path, enabled: true));
  }

  // Outro Options
  void updateOutroOptions(OutroOptions outroOptions) {
    state = state.copyWith(
      options: state.options.copyWith(outroOptions: outroOptions),
    );
  }

  void toggleOutro() {
    final current = state.options.outroOptions;
    updateOutroOptions(current.copyWith(enabled: !current.enabled));
  }

  // Blur Regions
  void addBlurRegion() {
    final regions = List<BlurRegion>.from(state.options.blurRegions);
    regions.add(BlurRegion(id: DateTime.now().millisecondsSinceEpoch.toString()));
    state = state.copyWith(
      options: state.options.copyWith(blurRegions: regions),
    );
  }

  void removeBlurRegion(String id) {
    final regions = state.options.blurRegions.where((r) => r.id != id).toList();
    state = state.copyWith(
      options: state.options.copyWith(blurRegions: regions),
    );
  }

  void updateBlurRegion(String id, {double? x, double? y, double? width, double? height}) {
    final regions = state.options.blurRegions.map((r) {
      if (r.id == id) {
        return r.copyWith(x: x, y: y, width: width, height: height);
      }
      return r;
    }).toList();
    state = state.copyWith(
      options: state.options.copyWith(blurRegions: regions),
    );
  }

  // Reset
  void reset() {
    state = const VideoCreationState();
  }

  // Submit - Connected to API
  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final options = state.options;
      await _videoService.createVideo(CreateVideoRequest(
        sourceUrl: options.sourceUrl,
        voiceId: options.voiceId,
        language: options.language,
        aspectRatio: options.aspectRatio,
        copyrightOptions: {
          'color_adjust': options.copyrightOptions.colorAdjust,
          'horizontal_flip': options.copyrightOptions.horizontalFlip,
          'slight_zoom': options.copyrightOptions.slightZoom,
          'audio_pitch_shift': options.copyrightOptions.audioPitchShift,
          'pitch_value': options.copyrightOptions.pitchValue,
        },
        subtitleOptions: {
          'enabled': options.subtitleOptions.enabled,
          'position': options.subtitleOptions.position,
          'size': options.subtitleOptions.size,
          'background': options.subtitleOptions.background,
        },
        logoOptions: options.logoOptions.enabled ? {
          'enabled': true,
          'position': options.logoOptions.position,
          'size': options.logoOptions.size,
          'opacity': options.logoOptions.opacity,
          'file_path': options.logoOptions.localFilePath, // Pass path to service
        } : null,
        outroOptions: options.outroOptions.enabled ? {
          'enabled': true,
          'platform': options.outroOptions.platform,
          'channel_name': options.outroOptions.channelName,
          'duration': options.outroOptions.durationSeconds,
        } : null,
      ));
      
      // Success - reset form
      reset();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isSubmitting: false);
      return false;
    }
  }
}

/// Provider - Connected to VideoService
final videoCreationProvider =
    StateNotifierProvider<VideoCreationNotifier, VideoCreationState>((ref) {
  return VideoCreationNotifier(ref.watch(videoServiceProvider));
});

