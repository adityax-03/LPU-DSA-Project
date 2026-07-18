import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/node.dart';

class AppState extends ChangeNotifier {
  final String backendUrl = 'http://localhost:8080/api';

  // Auth State
  Map<String, dynamic>? userProfile;
  bool isAuthenticating = false;

  // Navigation State
  List<CampusNode> allNodes = [];
  List<CampusNode> routeNodes = [];
  List<String> directions = [];
  double routeDistance = 0.0;
  int walkTime = 0;
  int cycleTime = 0;
  int shuttleTime = 0;
  String eta = '';

  // Multiple alternative routes
  List<List<CampusNode>> alternativeRoutes = [];
  List<List<String>> alternativeDirections = [];
  List<double> alternativeDistances = [];
  List<int> alternativeWalkTimes = [];
  List<int> alternativeCycleTimes = [];
  List<int> alternativeShuttleTimes = [];
  List<String> alternativeEtas = [];
  int selectedRouteIndex = 0;
  
  CampusNode? startNode;
  CampusNode? endNode;
  bool isNavigating = false;
  
  // Simulated GPS Location
  bool isInsideCampus = true; // Default inside LPU
  String currentCity = "Jalandhar"; // Outside location representation
  
  // Search state
  List<Map<String, String>> searchSuggestions = [];
  bool isSearching = false;
  
  // Nearby facilities
  CampusNode? nearestFacility;
  String? activeFacilityType;

  // Selected Classroom info
  String? classroomDetails;

  // Track currently focused search field ("from" or "to")
  String activeField = "to";

  void setActiveField(String field) {
    activeField = field;
    notifyListeners();
  }

  AppState() {
    fetchNodes();
  }

  // Set simulated location state
  void setLocationMode(bool inside, {String city = "Jalandhar"}) {
    isInsideCampus = inside;
    currentCity = city;
    if (!inside) {
      isNavigating = false;
    }
    notifyListeners();
  }

  // Set active search node points
  void setStartNode(CampusNode node) {
    startNode = node;
    if (endNode != null && endNode!.id != startNode!.id) {
      calculateRoute(startNode!.id, endNode!.id);
    } else {
      notifyListeners();
    }
  }

  void setEndNode(CampusNode node) {
    endNode = node;
    if (startNode != null && endNode!.id != startNode!.id) {
      calculateRoute(startNode!.id, endNode!.id);
    } else {
      notifyListeners();
    }
  }

  // Load all map nodes from backend
  Future<void> fetchNodes() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/navigation/nodes'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        allNodes = data.map((json) => CampusNode.fromJson(json)).toList();
        // Set default starting point
        if (allNodes.isNotEmpty) {
          startNode = allNodes.firstWhere((n) => n.id == 'BH_4', orElse: () => allNodes.first);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching nodes: $e');
    }
  }

  // Helper to recognize user gender dynamically based on name
  String determineGenderFromName(String name) {
    final cleanName = name.trim().toLowerCase();
    if (cleanName.isEmpty) return "boy";
    final firstName = cleanName.split(RegExp(r'\s+')).first;
    
    // Custom list of common female name endings or names
    final femaleEndings = ['a', 'i', 'ee', 'preet', 'meet', 'jeet', 'deep', 'ta', 'ka', 'ha', 'na', 'ma', 'ya', 'ra', 'la', 'da', 'sha'];
    
    if (cleanName.contains("geeta") || cleanName.contains("pooja") || cleanName.contains("neha") || cleanName.contains("priya") || cleanName.contains("ananya") || cleanName.contains("isha")) {
      return "girl";
    }
    if (cleanName.contains("aman") || cleanName.contains("rahul") || cleanName.contains("sanjay") || cleanName.contains("amit") || cleanName.contains("rohit")) {
      return "boy";
    }
    
    for (var ending in femaleEndings) {
      if (firstName.endsWith(ending)) {
        return "girl";
      }
    }
    return "boy";
  }

  // Mock login and api login
  Future<bool> login(String regNo, String password, String name) async {
    isAuthenticating = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'registrationNumber': regNo,
          'password': password,
          'name': name,
        }),
      );

      isAuthenticating = false;
      if (response.statusCode == 200) {
        userProfile = json.decode(response.body);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Backend connection failed. Using mock authentication fallback.');
    }

    // Open login fallback: allow any user regNo and password if not authenticated by server
    final String resolvedName = name.trim().isNotEmpty ? name : (regNo == '12345678' ? 'Geeta Wadhwa' : 'Student $regNo');
    final String resolvedGender = determineGenderFromName(resolvedName);
    
    userProfile = {
      'registrationNumber': regNo,
      'name': resolvedName,
      'gender': resolvedGender,
    };
    isAuthenticating = false;
    notifyListeners();
    return true;
  }

  void logout() {
    userProfile = null;
    isNavigating = false;
    routeNodes.clear();
    directions.clear();
    endNode = null;
    notifyListeners();
  }

  // Autocomplete using Trie backend
  Future<void> getSuggestions(String query) async {
    if (query.trim().isEmpty) {
      searchSuggestions = [];
      notifyListeners();
      return;
    }
    
    isSearching = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$backendUrl/navigation/search?q=$query'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        searchSuggestions = data.map<Map<String, String>>((item) {
          return {
            'name': item['name'] as String,
            'id': item['id'] as String,
          };
        }).toList();
      }
    } catch (e) {
      // Local fallback using basic containment matching if backend is not responding
      searchSuggestions = allNodes
          .where((node) => node.name.toLowerCase().contains(query.toLowerCase()) && node.type != 'ROAD_NODE')
          .map<Map<String, String>>((node) => {'name': node.name, 'id': node.id})
          .toList();
      
      // Classroom matches
      if ('38-402'.contains(query) || 'building 38 room 402'.toLowerCase().contains(query.toLowerCase())) {
        searchSuggestions.add({'name': 'Building 38 Room 402', 'id': 'ROOM_38_402'});
      }
      if ('13-102'.contains(query) || 'building 13 room 102'.toLowerCase().contains(query.toLowerCase())) {
        searchSuggestions.add({'name': 'Building 13 Room 102', 'id': 'ROOM_13_102'});
      }
    }

    isSearching = false;
    notifyListeners();
  }

  // Path routing
  Future<void> calculateRoute(String fromId, String toId) async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/navigation/route?from=$fromId&to=$toId'));
      if (response.statusCode == 200) {
        final List<dynamic> dataList = json.decode(response.body);
        
        alternativeRoutes.clear();
        alternativeDirections.clear();
        alternativeDistances.clear();
        alternativeWalkTimes.clear();
        alternativeCycleTimes.clear();
        alternativeShuttleTimes.clear();
        alternativeEtas.clear();
        
        for (final data in dataList) {
          final List<dynamic> routeData = data['route'];
          final nodes = routeData.map((json) => CampusNode.fromJson(json)).toList();
          
          alternativeRoutes.add(nodes);
          alternativeDirections.add(List<String>.from(data['directions']));
          alternativeDistances.add((data['distance'] as num).toDouble());
          alternativeWalkTimes.add(data['walkingTime'] as int);
          alternativeCycleTimes.add(data['cyclingTime'] as int);
          alternativeShuttleTimes.add(data['shuttleTime'] as int);
          alternativeEtas.add(data['eta'] as String);
        }
        
        selectedRouteIndex = 0;
        _applySelectedRoute();
        
        startNode = allNodes.firstWhere((n) => n.id == fromId);
        
        // Handle classroom specific destination displaying
        if (toId.startsWith('ROOM_')) {
          final parts = toId.split('_');
          classroomDetails = 'Building ${parts[1]}, Floor ${parts[2].substring(0,1)}, Room ${parts[2]}';
          endNode = allNodes.firstWhere((n) => n.id == 'BLOCK_${parts[1]}');
        } else {
          classroomDetails = null;
          endNode = allNodes.firstWhere((n) => n.id == toId);
        }

        isNavigating = true;
        nearestFacility = null;
        activeFacilityType = null;
        notifyListeners();
      }
    } catch (e) {
      print('Routing error: $e');
      mockLocalDijkstra(fromId, toId);
    }
  }

  void _applySelectedRoute() {
    if (alternativeRoutes.isEmpty) return;
    final idx = selectedRouteIndex.clamp(0, alternativeRoutes.length - 1);
    routeNodes = alternativeRoutes[idx];
    directions = alternativeDirections[idx];
    routeDistance = alternativeDistances[idx];
    walkTime = alternativeWalkTimes[idx];
    cycleTime = alternativeCycleTimes[idx];
    shuttleTime = alternativeShuttleTimes[idx];
    eta = alternativeEtas[idx];
  }

  void selectRoute(int index) {
    selectedRouteIndex = index;
    _applySelectedRoute();
    notifyListeners();
  }

  void mockLocalDijkstra(String fromId, String toId) {
    final start = allNodes.firstWhere((n) => n.id == fromId, orElse: () => allNodes.first);
    CampusNode target;
    if (toId.startsWith('ROOM_')) {
      final parts = toId.split('_');
      classroomDetails = 'Building ${parts[1]}, Floor ${parts[2].substring(0,1)}, Room ${parts[2]}';
      target = allNodes.firstWhere((n) => n.id == 'BLOCK_${parts[1]}', orElse: () => allNodes.first);
    } else {
      classroomDetails = null;
      target = allNodes.firstWhere((n) => n.id == toId, orElse: () => allNodes.first);
    }

    startNode = start;
    endNode = target;
    
    alternativeRoutes.clear();
    alternativeDirections.clear();
    alternativeDistances.clear();
    alternativeWalkTimes.clear();
    alternativeCycleTimes.clear();
    alternativeShuttleTimes.clear();
    alternativeEtas.clear();
    
    // Route 1 (Shortest)
    alternativeRoutes.add([start, target]);
    alternativeDirections.add(['${start.name} -> Walkway -> ${target.name}']);
    alternativeDistances.add(0.5);
    alternativeWalkTimes.add(6);
    alternativeCycleTimes.add(2);
    alternativeShuttleTimes.add(1);
    alternativeEtas.add('4:45 PM');
    
    selectedRouteIndex = 0;
    _applySelectedRoute();

    isNavigating = true;
    nearestFacility = null;
    activeFacilityType = null;
    notifyListeners();
  }

  // Find nearest facility using backend
  Future<void> findNearby(String facilityType) async {
    if (startNode == null) return;
    activeFacilityType = facilityType;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/navigation/nearby?from=${startNode!.id}&type=$facilityType')
      );
      if (response.statusCode == 200) {
        nearestFacility = CampusNode.fromJson(json.decode(response.body));
        await calculateRoute(startNode!.id, nearestFacility!.id);
      }
    } catch (e) {
      try {
        nearestFacility = allNodes.firstWhere((node) => node.type.toUpperCase() == facilityType.toUpperCase());
        await calculateRoute(startNode!.id, nearestFacility!.id);
      } catch (ex) {
        print('No facility found: $facilityType');
      }
    }
  }

  void clearNavigation() {
    isNavigating = false;
    routeNodes.clear();
    directions.clear();
    alternativeRoutes.clear();
    alternativeDirections.clear();
    alternativeDistances.clear();
    alternativeWalkTimes.clear();
    alternativeCycleTimes.clear();
    alternativeShuttleTimes.clear();
    alternativeEtas.clear();
    selectedRouteIndex = 0;
    endNode = null;
    nearestFacility = null;
    activeFacilityType = null;
    classroomDetails = null;
    notifyListeners();
  }
}
