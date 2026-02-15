import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../models/occupation_tag.dart';
import '../models/allergen_tag.dart';
import '../models/dietary_preference_tag.dart';

final occupationTagsProvider = FutureProvider<List<OccupationTag>>((ref) async {
  final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/tags/occupations'));
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data.map((json) => OccupationTag.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load tags');
  }
});

final selectedTagsProvider = StateProvider<Set<int>>((ref) => {});

final allergenTagsProvider = FutureProvider<List<AllergenTag>>((ref) async {
  final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/tags/allergens'));
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data.map((json) => AllergenTag.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load allergen tags');
  }
});

final dietaryPreferenceTagsProvider = FutureProvider<List<DietaryPreferenceTag>>((ref) async {
  final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/tags/dietary-preferences'));
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data.map((json) => DietaryPreferenceTag.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load dietary preference tags');
  }
});

final selectedAllergenTagsProvider = StateProvider<Set<int>>((ref) => {});
final selectedDietaryPreferenceTagsProvider = StateProvider<Set<int>>((ref) => {});
final customAvoidedIngredientsProvider = StateProvider<List<String>>((ref) => []);
