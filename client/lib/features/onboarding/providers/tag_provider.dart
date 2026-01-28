import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../models/occupation_tag.dart';

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
