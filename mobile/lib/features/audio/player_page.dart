import 'package:material_ui/material_ui.dart';

import '../../data/audio/playback_controller.dart';
import '../../data/models/audio.dart';
import '../../l10n/app_localizations.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key, required this.playback});

  final PlaybackController playback;

  String _time(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.audioNowPlaying)),
      body: ListenableBuilder(
        listenable: playback,
        builder: (context, _) {
          final track = playback.current;
          if (track == null) {
            return Center(child: Text(l10n.audioQueueEmpty));
          }
          final duration = playback.duration;
          final hasDuration = duration > Duration.zero;
          final maxSeconds = hasDuration
              ? duration.inMilliseconds / 1000.0
              : 1.0;
          final seconds = hasDuration
              ? (playback.position.inMilliseconds / 1000.0).clamp(
                  0.0,
                  maxSeconds,
                )
              : 0.0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            children: [
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.12),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 58,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                track.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${track.subtitle} · ${track.reciterName}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              if (playback.error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: scheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.audioPlaybackError,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: scheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          key: const ValueKey('audio-retry'),
                          onPressed: playback.play,
                          child: Text(l10n.retry),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Slider(
                key: const ValueKey('audio-seek'),
                value: seconds,
                max: maxSeconds,
                onChanged: hasDuration
                    ? (value) => playback.seek(
                        Duration(milliseconds: (value * 1000).round()),
                      )
                    : null,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _time(playback.position),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    hasDuration ? _time(duration) : '--:--',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: l10n.audioPrevious,
                    onPressed: playback.current?.ayah == 1
                        ? null
                        : playback.previous,
                    icon: const Icon(Icons.skip_previous_rounded, size: 34),
                  ),
                  const SizedBox(width: 14),
                  IconButton.filled(
                    key: const ValueKey('audio-toggle'),
                    tooltip: playback.playing
                        ? l10n.audioPause
                        : l10n.audioPlay,
                    onPressed: playback.toggle,
                    iconSize: 34,
                    icon: Icon(
                      playback.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    tooltip: l10n.audioNext,
                    onPressed: playback.next,
                    icon: const Icon(Icons.skip_next_rounded, size: 34),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  ActionChip(
                    key: const ValueKey('audio-speed'),
                    avatar: const Icon(Icons.speed_rounded, size: 16),
                    label: Text('${playback.speed}x'),
                    onPressed: playback.cycleSpeed,
                  ),
                  ActionChip(
                    key: const ValueKey('audio-repeat'),
                    avatar: Icon(switch (playback.repeat) {
                      AudioRepeatMode.one => Icons.repeat_one_rounded,
                      _ => Icons.repeat_rounded,
                    }, size: 16),
                    label: Text(switch (playback.repeat) {
                      AudioRepeatMode.off => l10n.audioRepeatOff,
                      AudioRepeatMode.one => l10n.audioRepeatOne,
                      AudioRepeatMode.all => l10n.audioRepeatAll,
                    }),
                    onPressed: playback.cycleRepeat,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
