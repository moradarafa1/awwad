import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

/// Audio-session setup for every player in the app (Qur'an, hadith radio,
/// and any future listening wird).
///
/// WHY THIS EXISTS: `audio_session` was a dependency for months without a
/// single call site. With no session configured the app never requests audio
/// FOCUS, which on a real device means playback can come out quieter than the
/// user expects, other apps keep playing over it, and a phone call or a
/// notification does not duck or pause it. The owner reported exactly that
/// symptom ("الصوت منخفض جداً") on 2026-07-20.
///
/// The session is configured for SPEECH-style media playback: Qur'an recitation
/// and hadith are speech, and `usage: media` + `contentType: speech` is what
/// tells Android to route it as media (loud, on the music stream, respecting
/// the media volume slider) rather than as a notification blip.
///
/// FAIL-OPEN: every call is wrapped. A device that refuses the configuration
/// must still play audio, just without focus handling. Never let this throw
/// into a player.
class AwwadAudioSession {
  AwwadAudioSession._();

  static bool _configured = false;

  /// Configure once per process. Safe to call before every play.
  static Future<void> ensureConfigured() async {
    if (_configured || kIsWeb) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        // Keeps playing when the phone's physical silent switch is on, which
        // is what a user expects from a recitation they deliberately started.
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
          flags: AndroidAudioFlags.none,
        ),
        // Take focus properly: other players PAUSE rather than mixing, so the
        // recitation is heard on its own instead of competing.
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
      _configured = true;
    } catch (e) {
      debugPrint('awwad audio: session configure failed: $e');
    }
  }

  /// Take audio focus before starting playback. Returns false when the system
  /// refused, in which case the caller should still play: a refused focus
  /// request is not a reason to deny the user their wird.
  static Future<bool> requestFocus() async {
    if (kIsWeb) return true;
    try {
      await ensureConfigured();
      final session = await AudioSession.instance;
      return await session.setActive(true);
    } catch (e) {
      debugPrint('awwad audio: focus request failed: $e');
      return true;
    }
  }

  /// Release focus so other apps resume. Call when playback stops for good,
  /// NOT on a pause the user is likely to undo in a second.
  static Future<void> releaseFocus() async {
    if (kIsWeb) return;
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      debugPrint('awwad audio: focus release failed: $e');
    }
  }
}
