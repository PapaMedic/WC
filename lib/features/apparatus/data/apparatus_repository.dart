import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildland_companion_v2/features/apparatus/models/apparatus.dart';

class ApparatusRepository {
  static const String _storageKey = 'apparatus_list';

  Future<List<Apparatus>> getAllApparatus() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_storageKey);

    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawJson) as List<dynamic>;

    return decoded
        .map((item) => Apparatus.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAllApparatus(List<Apparatus> apparatusList) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      apparatusList.map((apparatus) => apparatus.toJson()).toList(),
    );

    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addApparatus(Apparatus apparatus) async {
    final apparatusList = await getAllApparatus();
    apparatusList.add(apparatus);
    await saveAllApparatus(apparatusList);
  }

  Future<void> updateApparatus(Apparatus updatedApparatus) async {
    final apparatusList = await getAllApparatus();

    final updatedList = apparatusList.map((apparatus) {
      if (apparatus.id == updatedApparatus.id) {
        return updatedApparatus;
      }
      return apparatus;
    }).toList();

    await saveAllApparatus(updatedList);
  }

  Future<void> deleteApparatus(String id) async {
    final apparatusList = await getAllApparatus();

    final updatedList = apparatusList
        .where((apparatus) => apparatus.id != id)
        .toList();

    await saveAllApparatus(updatedList);
  }

  Future<void> selectApparatus(String id) async {
    final apparatusList = await getAllApparatus();

    final updatedList = apparatusList.map((apparatus) {
      return apparatus.copyWith(
        isSelected: apparatus.id == id,
      );
    }).toList();

    await saveAllApparatus(updatedList);
  }

  Future<Apparatus?> getSelectedApparatus() async {
    final apparatusList = await getAllApparatus();

    try {
      return apparatusList.firstWhere((apparatus) => apparatus.isSelected);
    } catch (_) {
      return null;
    }
  }
}
