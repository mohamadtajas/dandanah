import 'package:material_ui/material_ui.dart';

import '../../data/location/device_location.dart';
import '../../data/location/location_service.dart';
import '../../data/worship/prayer_settings.dart';
import '../../l10n/app_localizations.dart';

class LocationOnboardingSheet extends StatefulWidget {
  const LocationOnboardingSheet({
    super.key,
    required this.location,
    required this.settings,
    required this.onSave,
    required this.onDismiss,
  });

  final LocationService location;
  final PrayerSettings settings;
  final Future<void> Function(PrayerSettings settings) onSave;
  final Future<void> Function() onDismiss;

  @override
  State<LocationOnboardingSheet> createState() =>
      _LocationOnboardingSheetState();
}

class _LocationOnboardingSheetState extends State<LocationOnboardingSheet> {
  bool _busy = false;
  bool _deniedForever = false;
  LocationFailure? _failure;

  Future<void> _useLocation() async {
    setState(() {
      _busy = true;
      _failure = null;
      _deniedForever = false;
    });
    final result = await widget.location.currentLocation();
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() {
        _busy = false;
        _failure = result.failure;
        _deniedForever = result.failure == LocationFailure.deniedForever;
      });
      return;
    }
    final fix = result.location!;
    final updated = widget.settings.copyWith(
      latitude: fix.latitude,
      longitude: fix.longitude,
      timezone: fix.timezone ?? widget.settings.timezone,
      configured: true,
      clearCity: true,
      locationSource: 'device',
    );
    try {
      await widget.onSave(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = LocationFailure.unavailable;
      });
      return;
    }
    if (mounted) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    }
  }

  Future<void> _chooseCity() async {
    await widget.onDismiss();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  String _errorText(AppLocalizations l10n) => switch (_failure) {
    LocationFailure.denied => l10n.locationDenied,
    LocationFailure.deniedForever => l10n.locationDeniedForever,
    LocationFailure.timeout ||
    LocationFailure.unavailable => l10n.locationUnavailable,
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.my_location_rounded, size: 34, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              l10n.locationTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.locationBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (_failure != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText(l10n),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: scheme.error),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 8),
              Text(
                l10n.locationFetching,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _useLocation,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(l10n.locationUse),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _chooseCity,
              child: Text(l10n.locationChooseCity),
            ),
            if (_deniedForever)
              TextButton(
                onPressed: () => widget.location.openAppSettings(),
                child: Text(l10n.locationOpenSettings),
              ),
          ],
        ),
      ),
    );
  }
}
