import 'package:flutter/material.dart';

import '../../data/models/food_preference.dart';
import '../../data/services/preferences_service.dart';

class FoodPreferenceProvider with ChangeNotifier {
  final PreferencesService _prefsService;

  FoodPreference? _percentage;
  bool _isLoading = false;

  FoodPreferenceProvider(this._prefsService) {
    _loadPreference();
  }

  FoodPreference? get preference => _percentage;
  bool get isLoading => _isLoading;
  bool get hasPreference => _percentage != null;

  Future<void> _loadPreference() async {
    _isLoading = true;
    notifyListeners();

    try {
      _percentage = _prefsService.getFoodPreference();
    } catch (e) {
      debugPrint('Error loading food preference: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePreference({
    required List<String> preferredCuisines,
    required int spicyLevel,
    required List<String> dislikedIngredients,
    required String characterType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newPreference = FoodPreference(
        preferredCuisines: preferredCuisines,
        spicyLevel: spicyLevel,
        dislikedIngredients: dislikedIngredients,
        characterType: characterType,
      );

      final result = await _prefsService.saveFoodPreference(newPreference);
      if (result) {
        _percentage = newPreference;
      }
      return result;
    } catch (e) {
      debugPrint('Error saving food preference: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
