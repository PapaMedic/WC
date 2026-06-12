import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildland_companion_v2/features/personnel/models/personnel.dart';

class PersonnelRepository {
  static const String _storageKey = 'personnel_list';

  Future<List<Personnel>> getAllPersonnel() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_storageKey);

    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawJson) as List<dynamic>;

    return decoded
        .map((item) => Personnel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAllPersonnel(List<Personnel> personnelList) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      personnelList.map((personnel) => personnel.toJson()).toList(),
    );

    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addPersonnel(Personnel personnel) async {
    final personnelList = await getAllPersonnel();
    personnelList.add(personnel);
    await saveAllPersonnel(personnelList);
  }

  Future<void> updatePersonnel(Personnel updatedPersonnel) async {
    final personnelList = await getAllPersonnel();

    final updatedList = personnelList.map((personnel) {
      if (personnel.id == updatedPersonnel.id) {
        return updatedPersonnel;
      }
      return personnel;
    }).toList();

    await saveAllPersonnel(updatedList);
  }

  Future<void> deletePersonnel(String id) async {
    final personnelList = await getAllPersonnel();

    final updatedList =
        personnelList.where((personnel) => personnel.id != id).toList();

    await saveAllPersonnel(updatedList);
  }

  Future<void> toggleAssigned(String id) async {
    final personnelList = await getAllPersonnel();

    final updatedList = personnelList.map((personnel) {
      if (personnel.id == id) {
        return personnel.copyWith(
          isAssigned: !personnel.isAssigned,
        );
      }
      return personnel;
    }).toList();

    await saveAllPersonnel(updatedList);
  }

  Future<List<Personnel>> getAssignedPersonnel() async {
    final personnelList = await getAllPersonnel();

    return personnelList
        .where((personnel) => personnel.isAssigned)
        .toList();
  }

  Future<void> clearAssignedPersonnel() async {
    final personnelList = await getAllPersonnel();

    final updatedList = personnelList.map((personnel) {
      return personnel.copyWith(isAssigned: false);
    }).toList();

    await saveAllPersonnel(updatedList);
  }
}
