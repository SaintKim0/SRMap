import 'package:flutter/foundation.dart';

import '../../data/models/user_profile.dart';
import '../../data/services/preferences_service.dart';

/// 사용자 프로필 상태 관리 Provider
class UserProfileProvider with ChangeNotifier {
  final PreferencesService _prefsService;
  
  UserProfile _userProfile;
  bool _isLoading = false;

  UserProfileProvider(this._prefsService) 
      : _userProfile = const UserProfile() {
    _loadProfile();
  }

  /// 현재 사용자 프로필
  UserProfile get userProfile => _userProfile;

  /// 로딩 상태
  bool get isLoading => _isLoading;

  /// 프로필 로드
  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedProfile = _prefsService.getUserProfile();
      if (loadedProfile != null) {
        _userProfile = loadedProfile;
      }
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 프로필 저장/업데이트
  Future<bool> updateProfile({
    String? nickname,
    String? statusMessage,
    String? profileImage,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newProfile = _userProfile.copyWith(
        nickname: nickname,
        statusMessage: statusMessage,
        profileImage: profileImage,
      );

      final success = await _prefsService.saveUserProfile(newProfile);
      if (success) {
        _userProfile = newProfile;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
