import 'package:just_audio/just_audio.dart';

/// One place that builds the audio player for STREAMED content (the Qur'an
/// recitations from mp3quran and the live hadith stations).
///
/// WHY THE BIGGER BUFFER: both sources stream over the network, and the target
/// audience is largely on mobile data where throughput dips for seconds at a
/// time. just_audio's defaults are tuned for short local media; on a dipping
/// connection they run the buffer dry and the recitation stutters. The values
/// below trade a slightly slower first note for playback that survives a bad
/// minute, which is the right trade for a wird someone listens to for five
/// minutes or more.
///
/// NOTE ON THE EMULATOR: stuttering there is usually NOT this. The Android
/// emulator's audio HAL reports inconsistent timestamps, which surfaces in the
/// log as `DefaultAudioSink: Spurious audio timestamp (frame position
/// mismatch)` and is audible as choppiness no buffer size can fix. Confirm on
/// real hardware before chasing a buffering bug that is not there.
AudioPlayer buildStreamPlayer() => AudioPlayer(
      audioLoadConfiguration: const AudioLoadConfiguration(
        androidLoadControl: AndroidLoadControl(
          // Start playing once this much is buffered, and after a stall wait
          // for rather more before resuming, so one dip does not become a
          // stutter every few seconds.
          bufferForPlaybackDuration: Duration(seconds: 3),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 8),
          // Keep buffering well ahead when the connection allows it. A minute
          // of audio is a few hundred KB at speech bitrates, which is cheap
          // next to re-buffering in the middle of a recitation.
          minBufferDuration: Duration(seconds: 30),
          maxBufferDuration: Duration(seconds: 90),
        ),
        darwinLoadControl: DarwinLoadControl(
          preferredForwardBufferDuration: Duration(seconds: 30),
        ),
      ),
    );
