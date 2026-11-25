import 'package:material_ui/material_ui.dart';

import '../../data/app_services.dart';
import '../../data/cities.dart';
import '../../data/location/device_location.dart';
import '../../data/location/location_service.dart';
import '../../data/worship/prayer_method.dart';
import '../../data/worship/coordinate_input.dart';
import '../../data/worship/prayer_settings.dart';
import '../../data/worship/timezone_bootstrap.dart';
import '../../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.location,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final LocationService location;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _mode = widget.themeMode;
  late final AppServices _services = AppServices.current;
  late PrayerSettings _settings = _services.prayerSettings.value;
  late final TextEditingController _latitude = TextEditingController(
    text: _settings.latitude.toStringAsFixed(4),
  );
  late final TextEditingController _longitude = TextEditingController(
    text: _settings.longitude.toStringAsFixed(4),
  );
  late String? _cityId = _settings.cityId;
  late String _timezone = _settings.timezone;
  late PrayerMethod _method = _settings.method;
  late PrayerMadhab _madhab = _settings.madhab;
  late PrayerHighLatitude _highLatitude = _settings.highLatitude;
  late int _hijriAdjustment = _settings.hijriAdjustment;
  late String? _locationSource = _settings.locationSource;
  bool _saving = false;
  bool _locating = false;

  late final List<String> _timezones = _buildTimezones();

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  List<String> _buildTimezones() {
    final values = allTimezoneNames();
    if (!values.contains(_timezone)) values.add(_timezone);
    return values..sort();
  }

  void _pickCity(String? value) {
    if (value == null || value == 'custom') {
      setState(() {
        _cityId = null;
        _locationSource = 'manual';
      });
      return;
    }
    final city = cityById(value);
    if (city == null) return;
    setState(() {
      _cityId = city.id;
      _timezone = city.timezone;
      _latitude.text = city.latitude.toStringAsFixed(4);
      _longitude.text = city.longitude.toStringAsFixed(4);
      _locationSource = 'city';
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final result = await widget.location.currentLocation();
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() => _locating = false);
      _showLocationError(result.failure!);
      return;
    }
    final fix = result.location!;
    setState(() {
      _locating = false;
      _cityId = null;
      _locationSource = 'device';
      _latitude.text = fix.latitude.toStringAsFixed(4);
      _longitude.text = fix.longitude.toStringAsFixed(4);
      _timezone = fix.timezone ?? _timezone;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.locationSaved)),
    );
  }

  void _showLocationError(LocationFailure failure) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (failure) {
      LocationFailure.denied => l10n.locationDenied,
      LocationFailure.deniedForever => l10n.locationDeniedForever,
      LocationFailure.timeout ||
      LocationFailure.unavailable => l10n.locationUnavailable,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: failure == LocationFailure.deniedForever
            ? SnackBarAction(
                label: l10n.locationOpenSettings,
                onPressed: widget.location.openAppSettings,
              )
            : null,
      ),
    );
  }

  Future<void> _save() async {
    final latitude = parseCoordinate(_latitude.text);
    final longitude = parseCoordinate(_longitude.text);
    if (latitude == null ||
        longitude == null ||
        !isValidLatitude(latitude) ||
        !isValidLongitude(longitude)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.prayerInvalidCoordinates),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final updated = _settings
        .copyWith(
          latitude: latitude,
          longitude: longitude,
          timezone: _timezone,
          method: _method,
          madhab: _madhab,
          highLatitude: _highLatitude,
          hijriAdjustment: _hijriAdjustment,
          configured: true,
          cityId: _cityId,
          clearCity: _cityId == null,
          locationSource: _locationSource,
        )
        .sanitized();
    try {
      await _services.updatePrayerSettings(updated);
      if (!mounted) return;
      setState(() {
        _settings = updated;
        _latitude.text = updated.latitude.toStringAsFixed(4);
        _longitude.text = updated.longitude.toStringAsFixed(4);
        _timezone = updated.timezone;
        _locationSource = updated.locationSource;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settingsSaveFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _SectionCard(
            title: l10n.prayerSettings,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_locationSource == 'device')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          l10n.locationSourceDevice,
                          style: TextStyle(fontSize: 10, color: scheme.primary),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _locating ? null : _useCurrentLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(l10n.settingsLocationUse),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('city-${_cityId ?? 'custom'}'),
                  initialValue: _cityId ?? 'custom',
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.cityLabel),
                  items: [
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text(l10n.customLocation),
                    ),
                    for (final city in cities)
                      DropdownMenuItem(
                        value: city.id,
                        child: Text(
                          isArabic
                              ? '${city.name} - ${city.country}'
                              : '${city.nameEn} - ${city.countryEn}',
                        ),
                      ),
                  ],
                  onChanged: _pickCity,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.latitudeLabel,
                        ),
                        onChanged: (_) => setState(() {
                          _cityId = null;
                          _locationSource = 'manual';
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _longitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.longitudeLabel,
                        ),
                        onChanged: (_) => setState(() {
                          _cityId = null;
                          _locationSource = 'manual';
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownMenu<String>(
                  initialSelection: _timezone,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  expandedInsets: EdgeInsets.zero,
                  menuHeight: 360,
                  label: Text(l10n.timezoneLabel),
                  dropdownMenuEntries: [
                    for (final zone in _timezones)
                      DropdownMenuEntry(value: zone, label: zone),
                  ],
                  onSelected: (value) {
                    if (value != null) {
                      setState(() {
                        _timezone = value;
                        _cityId = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PrayerMethod>(
                  initialValue: _method,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.methodLabel),
                  items: [
                    for (final method in PrayerMethod.values)
                      DropdownMenuItem(
                        value: method,
                        child: Text(method.arabicName),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _method = value);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.madhabLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<PrayerMadhab>(
                  segments: [
                    ButtonSegment(
                      value: PrayerMadhab.shafi,
                      label: Text(l10n.shafi),
                    ),
                    ButtonSegment(
                      value: PrayerMadhab.hanafi,
                      label: Text(l10n.hanafi),
                    ),
                  ],
                  selected: {_madhab},
                  onSelectionChanged: (selection) =>
                      setState(() => _madhab = selection.first),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PrayerHighLatitude>(
                  initialValue: _highLatitude,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.highLatitudeLabel,
                  ),
                  items: [
                    for (final rule in PrayerHighLatitude.values)
                      DropdownMenuItem(
                        value: rule,
                        child: Text(rule.arabicName),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _highLatitude = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.hijriAdjustmentLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.prayerClear,
                      onPressed: _hijriAdjustment <= -3
                          ? null
                          : () => setState(() => _hijriAdjustment--),
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Text(
                      _hijriAdjustment == 0
                          ? '0'
                          : '${_hijriAdjustment > 0 ? '+' : '-'}${_hijriAdjustment.abs()}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      tooltip: l10n.hijriAdjustmentLabel,
                      onPressed: _hijriAdjustment >= 3
                          ? null
                          : () => setState(() => _hijriAdjustment++),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.themeSection,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(l10n.themeDark),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(l10n.themeLight),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                final mode = selection.first;
                setState(() => _mode = mode);
                widget.onThemeChanged(mode);
              },
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              l10n.versionLine('0.1.0'),
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
