import 'package:flutter/foundation.dart';

import '../../data/models/peat_profile.dart';
import '../../data/services/preferences_service.dart';

/// P.E.A.T 프로필 상태 관리 Provider
class PeatProfileProvider with ChangeNotifier {
  final PreferencesService _prefsService;
  
  PeatProfile? _profile;
  bool _isLoading = false;

  PeatProfileProvider(this._prefsService) {
    _loadProfile();
  }

  /// 현재 프로필
  PeatProfile? get profile => _profile;

  /// 로딩 상태
  bool get isLoading => _isLoading;

  /// 프로필 존재 여부
  bool get hasProfile => _profile != null;

  /// 프로필 로드
  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = _prefsService.getPeatProfile();
    } catch (e) {
      debugPrint('Failed to load PEAT profile: $e');
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 프로필 저장
  Future<bool> saveProfile(PeatProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _prefsService.savePeatProfile(profile);
      if (success) {
        _profile = profile;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Failed to save PEAT profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 설문 결과로 프로필 생성 및 저장
  Future<bool> createProfileFromSurvey({
    required double priceScore,
    required double energyScore,
    required double authorityScore,
    required double tasteScore,
  }) async {
    final profile = PeatProfile(
      priceScore: priceScore,
      energyScore: energyScore,
      authorityScore: authorityScore,
      tasteScore: tasteScore,
      createdAt: DateTime.now(),
    );

    return await saveProfile(profile);
  }

  /// 프로필 업데이트 (재측정)
  Future<bool> updateProfile({
    double? priceScore,
    double? energyScore,
    double? authorityScore,
    double? tasteScore,
  }) async {
    if (_profile == null) return false;

    final updatedProfile = _profile!.copyWith(
      priceScore: priceScore,
      energyScore: energyScore,
      authorityScore: authorityScore,
      tasteScore: tasteScore,
      updatedAt: DateTime.now(),
    );

    return await saveProfile(updatedProfile);
  }

  /// 프로필 삭제 (재측정 시작)
  Future<bool> clearProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _prefsService.clearPeatProfile();
      if (success) {
        _profile = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Failed to clear PEAT profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 프로필 새로고침
  Future<void> refresh() async {
    await _loadProfile();
  }
}
