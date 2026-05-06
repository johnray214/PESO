import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared, app-wide GPS source.
///
/// - Listens to `geolocator` position stream while the app is in the
///   `resumed` state.
/// - Automatically pauses when the app is backgrounded/paused/detached
///   to save battery.
/// - Caches the last known location in SharedPreferences so the Map tab
///   can show something instantly on next launch.
/// - Supports a "manual exact location" override that takes precedence
///   over the live GPS reading for ranking/distance calculations.
class LocationController with WidgetsBindingObserver {
  LocationController._internal();

  static final LocationController instance = LocationController._internal();

  static const String _prefLatKey = 'last_known_user_latitude';
  static const String _prefLngKey = 'last_known_user_longitude';

  /// Live GPS coordinate (most recent stream value).
  final ValueNotifier<LocationPoint?> liveLocation =
      ValueNotifier<LocationPoint?>(null);

  /// Optional manual override that the user picked on the map.
  /// When non-null, [effectiveLocation] returns this instead of [liveLocation].
  final ValueNotifier<LocationPoint?> manualLocation =
      ValueNotifier<LocationPoint?>(null);

  /// Latest permission status as observed by the controller.
  final ValueNotifier<LocationPermission> permission =
      ValueNotifier<LocationPermission>(LocationPermission.denied);

  /// Whether device location services (GPS) are enabled.
  final ValueNotifier<bool> serviceEnabled = ValueNotifier<bool>(true);

  StreamSubscription<Position>? _positionSub;
  bool _started = false;
  bool _isFetchingInitial = false;

  /// The point that should be used for distance / ranking.
  LocationPoint? get effectiveLocation =>
      manualLocation.value ?? liveLocation.value;

  /// Start the controller. Safe to call multiple times.
  ///
  /// Loads cached last known location, registers lifecycle observer,
  /// and (if permission already granted) begins streaming.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);

    await _loadCachedLocation();

    final perm = await Geolocator.checkPermission();
    permission.value = perm;
    serviceEnabled.value = await Geolocator.isLocationServiceEnabled();

    if (_isPermissionGranted(perm) && serviceEnabled.value) {
      await _startStream();
      unawaited(_fetchInitialPosition());
    }
  }

  /// Ask the user for location permission. Returns the resulting status.
  ///
  /// Also begins streaming + fetches an initial position if granted.
  Future<LocationPermission> requestPermission() async {
    var perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    permission.value = perm;
    serviceEnabled.value = await Geolocator.isLocationServiceEnabled();

    if (_isPermissionGranted(perm) && serviceEnabled.value) {
      await _startStream();
      unawaited(_fetchInitialPosition());
    }
    return perm;
  }

  /// Force a one-shot read of the current GPS position.
  Future<LocationPoint?> getCurrentOnce({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      if (!_isPermissionGranted(permission.value) || !serviceEnabled.value) {
        return liveLocation.value;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );
      final point = LocationPoint(pos.latitude, pos.longitude);
      liveLocation.value = point;
      unawaited(_persistCachedLocation(point));
      return point;
    } catch (_) {
      return liveLocation.value;
    }
  }

  /// Set a manual exact location chosen by the user (e.g. by tapping the map).
  void setManualLocation(LocationPoint point) {
    manualLocation.value = point;
  }

  /// Clear the manual override and revert to live GPS.
  void clearManualLocation() {
    manualLocation.value = null;
  }

  /// Open the OS app settings page (when permission is permanently denied).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Open the OS location services settings page.
  Future<bool> openLocationServiceSettings() =>
      Geolocator.openLocationSettings();

  /// Stop everything and detach lifecycle observer.
  Future<void> dispose() async {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    await _positionSub?.cancel();
    _positionSub = null;
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isPermissionGranted(permission.value) && serviceEnabled.value) {
          unawaited(_startStream());
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_positionSub?.cancel());
        _positionSub = null;
        break;
    }
  }

  // ─── Internals ────────────────────────────────────────────────────────────

  bool _isPermissionGranted(LocationPermission perm) {
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> _startStream() async {
    if (_positionSub != null) return;
    try {
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      );
      _positionSub = Geolocator.getPositionStream(locationSettings: settings)
          .listen(_onPosition, onError: (_) {});
    } catch (_) {
      // If the platform refuses (e.g. service off), silently no-op;
      // we'll retry next time `start()` / `requestPermission()` runs.
    }
  }

  Future<void> _fetchInitialPosition() async {
    if (_isFetchingInitial) return;
    _isFetchingInitial = true;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final point = LocationPoint(pos.latitude, pos.longitude);
      liveLocation.value = point;
      unawaited(_persistCachedLocation(point));
    } catch (_) {
      // Ignored — stream will eventually deliver a position.
    } finally {
      _isFetchingInitial = false;
    }
  }

  void _onPosition(Position pos) {
    final point = LocationPoint(pos.latitude, pos.longitude);
    liveLocation.value = point;
    unawaited(_persistCachedLocation(point));
  }

  Future<void> _loadCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_prefLatKey);
      final lng = prefs.getDouble(_prefLngKey);
      if (lat != null && lng != null) {
        liveLocation.value = LocationPoint(lat, lng);
      }
    } catch (_) {}
  }

  Future<void> _persistCachedLocation(LocationPoint point) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefLatKey, point.latitude);
      await prefs.setDouble(_prefLngKey, point.longitude);
    } catch (_) {}
  }
}

/// Lightweight lat/lng pair so this controller does not depend on `latlong2`
/// or `flutter_map`.
@immutable
class LocationPoint {
  final double latitude;
  final double longitude;

  const LocationPoint(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      other is LocationPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'LocationPoint($latitude, $longitude)';
}
