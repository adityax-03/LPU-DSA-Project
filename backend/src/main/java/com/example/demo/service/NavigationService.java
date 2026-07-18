package com.example.demo.service;

import com.example.demo.algorithms.Graph;
import com.example.demo.algorithms.Trie;
import com.example.demo.model.Node;
import com.example.demo.model.RouteResponse;
import com.example.demo.model.UserProfile;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.util.*;

@Service
public class NavigationService {

    private final Graph campusGraph = new Graph();
    private final Trie searchTrie = new Trie();
    private final Map<String, UserProfile> userDatabase = new HashMap<>();

    @PostConstruct
    public void init() {
        seedUsers();
        seedCampusGraph();
        seedSearchTrie();
    }

    private void seedUsers() {
        // Sample user profiles simulating UMS logins
        userDatabase.put("12345678", new UserProfile("12345678", "Geeta Wadhwa", "password123", "girl"));
        userDatabase.put("11903421", new UserProfile("11903421", "Aman Sharma", "aman@2026", "boy"));
        userDatabase.put("22004523", new UserProfile("22004523", "Pooja Patel", "pooja@lpu", "girl"));
    }

    private void seedCampusGraph() {
        // 1. Add Campus Nodes matching LPU Site Plan Legend
        campusGraph.addNode(new Node("GATE_MAIN", "Main Gate 1", "GATE", 31.2510, 75.7010));
        campusGraph.addNode(new Node("SECURITY_OFFICE", "Security Office", "SECURITY", 31.2512, 75.7012));
        campusGraph.addNode(new Node("BUS_TERMINUS", "Campus Bus Terminus", "BUS_STOP", 31.2515, 75.7015));
        campusGraph.addNode(new Node("BUS_STOP", "LPU Bus Stop", "BUS_STOP", 31.2518, 75.7018));
        campusGraph.addNode(new Node("PARKING", "Main Parking Area", "PARKING", 31.2516, 75.7024));
        campusGraph.addNode(new Node("ADMIN_BLOCK", "Administrative Block", "BLOCK", 31.2520, 75.7035));
        
        // Medical & Academic Block
        campusGraph.addNode(new Node("PRIMARY_HEALTH", "Primary Health Center", "HOSPITAL", 31.2530, 75.7042));
        campusGraph.addNode(new Node("HEALTH_CENTRE", "Health Centre (Hospital)", "HOSPITAL", 31.2535, 75.7040));
        campusGraph.addNode(new Node("LIBRARY", "Central Library", "LIBRARY", 31.2545, 75.7050));
        campusGraph.addNode(new Node("BLOCK_34", "Block 34 (CS/IT)", "BLOCK", 31.2555, 75.7060));
        campusGraph.addNode(new Node("BLOCK_38", "Block 38 (Engineering)", "BLOCK", 31.2565, 75.7070));
        campusGraph.addNode(new Node("AMPHITHEATRE", "Amphitheatre", "AMPHITHEATRE", 31.2570, 75.7075));
        
        // Hostels (Boys & Girls)
        campusGraph.addNode(new Node("BH_1", "BH-1 Boys Hostel", "HOSTEL", 31.2568, 75.7008));
        campusGraph.addNode(new Node("BH_2", "BH-2 Boys Hostel", "HOSTEL", 31.2572, 75.7012));
        campusGraph.addNode(new Node("BH_3", "BH-3 Boys Hostel", "HOSTEL", 31.2576, 75.7016));
        campusGraph.addNode(new Node("BH_4", "BH-4 Boys Hostel", "HOSTEL", 31.2580, 75.7020));
        campusGraph.addNode(new Node("GH_1", "GH-1 Girls Hostel", "HOSTEL", 31.2590, 75.7050));
        campusGraph.addNode(new Node("GH_2", "GH-2 Girls Hostel", "HOSTEL", 31.2592, 75.7060));
        
        // Mall & Food Centers
        campusGraph.addNode(new Node("UNI_MALL", "Uni Mall (Shopping)", "MALL", 31.2520, 75.7080));
        campusGraph.addNode(new Node("FOOD_COURT", "Food Court", "CAFETERIA", 31.2525, 75.7082));
        campusGraph.addNode(new Node("FOOD_STREET", "Food Street Plaza", "CAFETERIA", 31.2528, 75.7085));
        
        // Sports & Grounds
        campusGraph.addNode(new Node("SPORTS_COMPLEX", "Sports Complex", "SPORTS", 31.2530, 75.7010));
        campusGraph.addNode(new Node("CRICKET_GROUND", "Cricket Ground", "SPORTS", 31.2536, 75.7012));
        campusGraph.addNode(new Node("FOOTBALL_GROUND", "Football Ground", "SPORTS", 31.2542, 75.7014));
        
        // Natural & Utilities
        campusGraph.addNode(new Node("WATER_BODY", "Campus Water Body", "LAKE", 31.2550, 75.7090));
        campusGraph.addNode(new Node("NURSERY", "Nursery & Green House", "PARK", 31.2560, 75.7095));
        
        // Banking & ATMs
        campusGraph.addNode(new Node("ATM", "ATM (SBI)", "ATM", 31.2522, 75.7078));
        campusGraph.addNode(new Node("ATM_BANK", "ATM Bank Center", "ATM", 31.2521, 75.7075));
        
        // Schools
        campusGraph.addNode(new Node("HOTEL_MGT", "Hotel Management Block", "BLOCK", 31.2538, 75.7025));
        campusGraph.addNode(new Node("LAW_SCHOOL", "School of Law Block", "BLOCK", 31.2544, 75.7030));
        campusGraph.addNode(new Node("AGRICULTURE", "School of Agriculture", "BLOCK", 31.2550, 75.7035));
        
        // Residences
        campusGraph.addNode(new Node("VC_RES", "VC Residence", "RESIDENCE", 31.2585, 75.7080));
        campusGraph.addNode(new Node("FACULTY_RES", "Faculty Residences", "RESIDENCE", 31.2575, 75.7085));

        // 2. Add Edges (Connecting Campus Map Roads & Pathways)
        campusGraph.addEdge("GATE_MAIN", "SECURITY_OFFICE", 30, "Gate Avenue");
        campusGraph.addEdge("SECURITY_OFFICE", "BUS_TERMINUS", 50, "Gate Avenue");
        campusGraph.addEdge("BUS_TERMINUS", "BUS_STOP", 40, "Gate Avenue");
        campusGraph.addEdge("BUS_STOP", "PARKING", 60, "Gate Avenue");
        campusGraph.addEdge("PARKING", "ADMIN_BLOCK", 150, "Campus Boulevard");
        campusGraph.addEdge("ADMIN_BLOCK", "PRIMARY_HEALTH", 120, "Campus Boulevard");
        campusGraph.addEdge("PRIMARY_HEALTH", "HEALTH_CENTRE", 60, "Campus Boulevard");
        campusGraph.addEdge("HEALTH_CENTRE", "LIBRARY", 140, "Academic Street");
        
        campusGraph.addEdge("LIBRARY", "BLOCK_34", 120, "Academic Street");
        campusGraph.addEdge("BLOCK_34", "BLOCK_38", 120, "Academic Street");
        campusGraph.addEdge("BLOCK_38", "AMPHITHEATRE", 70, "Amphitheatre Walkway");
        
        // Hostels connection
        campusGraph.addEdge("BH_1", "BH_2", 70, "Hostel Lane");
        campusGraph.addEdge("BH_2", "BH_3", 70, "Hostel Lane");
        campusGraph.addEdge("BH_3", "BH_4", 70, "Hostel Lane");
        campusGraph.addEdge("BH_4", "HEALTH_CENTRE", 450, "Hostel Avenue");
        campusGraph.addEdge("GH_1", "BLOCK_38", 300, "Girls Hostel Walkway");
        campusGraph.addEdge("GH_1", "GH_2", 120, "North Ring Road");
        
        // Sports Complex & Grounds
        campusGraph.addEdge("BH_1", "SPORTS_COMPLEX", 380, "Sports Arena Lane");
        campusGraph.addEdge("SPORTS_COMPLEX", "CRICKET_GROUND", 80, "Cricket Arena Walk");
        campusGraph.addEdge("CRICKET_GROUND", "FOOTBALL_GROUND", 90, "Football Arena Walk");
        campusGraph.addEdge("FOOTBALL_GROUND", "BH_4", 420, "West Ring Road");
        
        // Mall & Food Court
        campusGraph.addEdge("BLOCK_34", "UNI_MALL", 380, "East Avenue");
        campusGraph.addEdge("UNI_MALL", "FOOD_COURT", 50, "Mall Plaza");
        campusGraph.addEdge("FOOD_COURT", "FOOD_STREET", 60, "Food Street Link");
        campusGraph.addEdge("UNI_MALL", "ATM", 30, "Mall Plaza");
        campusGraph.addEdge("ATM", "ATM_BANK", 20, "Mall Plaza");
        
        // Academic connections
        campusGraph.addEdge("HEALTH_CENTRE", "HOTEL_MGT", 150, "Academic Loop");
        campusGraph.addEdge("HOTEL_MGT", "LAW_SCHOOL", 90, "Academic Loop");
        campusGraph.addEdge("LAW_SCHOOL", "AGRICULTURE", 90, "Academic Loop");
        campusGraph.addEdge("AGRICULTURE", "BLOCK_34", 110, "Academic Loop");
        
        // Residences & Lake
        campusGraph.addEdge("BLOCK_38", "WATER_BODY", 250, "Lake View Walk");
        campusGraph.addEdge("GH_2", "VC_RES", 220, "Residence Pathway");
        campusGraph.addEdge("VC_RES", "FACULTY_RES", 110, "Residence Road");
        campusGraph.addEdge("FACULTY_RES", "WATER_BODY", 200, "Lake Pathway");
        campusGraph.addEdge("WATER_BODY", "NURSERY", 80, "Nursery Path");
    }

    private void seedSearchTrie() {
        // Insert all nodes into the Trie for autocompletion
        for (Node node : campusGraph.getAllNodes()) {
            if (!node.getType().equals("ROAD_NODE")) {
                searchTrie.insert(node.getName(), node.getId());
            }
        }

        // Add classroom search mappings (e.g. 38-402, 13-102)
        searchTrie.insert("Building 38 Room 402", "ROOM_38_402");
        searchTrie.insert("38-402", "ROOM_38_402");
        searchTrie.insert("Building 13 Room 102", "ROOM_13_102");
        searchTrie.insert("13-102", "ROOM_13_102");
        searchTrie.insert("Building 15 Room 204", "ROOM_15_204");
        searchTrie.insert("15-204", "ROOM_15_204");
        searchTrie.insert("Building 33 Room 301", "ROOM_33_301");
        searchTrie.insert("33-301", "ROOM_33_301");
    }

    /**
     * Helper to recognize user gender dynamically based on name
     */
    public static String determineGenderFromName(String name) {
        if (name == null || name.trim().isEmpty()) {
            return "boy";
        }
        String cleanName = name.trim().toLowerCase();
        // Split to get the first name
        String firstName = cleanName.split("\\s+")[0];

        // Known seed female names or subparts
        if (cleanName.contains("geeta") || cleanName.contains("pooja") || cleanName.contains("neha") || 
            cleanName.contains("priya") || cleanName.contains("ananya") || cleanName.contains("isha")) {
            return "girl";
        }
        // Known seed male names
        if (cleanName.contains("aman") || cleanName.contains("rahul") || cleanName.contains("sanjay") || 
            cleanName.contains("amit") || cleanName.contains("rohit")) {
            return "boy";
        }

        // Common Indian/general female name suffixes or endings
        String[] femaleEndings = {"a", "i", "ee", "preet", "meet", "jeet", "deep", "ta", "ka", "ha", "na", "ma", "ya", "ra", "la", "da", "sha"};
        for (String ending : femaleEndings) {
            if (firstName.endsWith(ending)) {
                return "girl";
            }
        }
        return "boy";
    }

    /**
     * Authenticates user against mock UMS database.
     */
    public UserProfile login(String registrationNumber, String password, String name) {
        UserProfile user = userDatabase.get(registrationNumber);
        if (user != null) {
            if (user.getPassword().equals(password)) {
                return user;
            }
        } else {
            // Allow dynamic login for any user registration and password
            String displayName = (name != null && !name.trim().isEmpty()) ? name : "Student " + registrationNumber;
            String userGender = determineGenderFromName(displayName);
            UserProfile newUser = new UserProfile(registrationNumber, displayName, password, userGender);
            userDatabase.put(registrationNumber, newUser);
            return newUser;
        }
        return null;
    }

    /**
     * Autocomplete suggestions using Trie.
     */
    public List<Trie.Suggestion> autocomplete(String query) {
        return searchTrie.getSuggestions(query);
    }

    /**
     * Shortest path routing.
     */
    public RouteResponse getRoute(String fromId, String toId) {
        // Handle classroom destination translation
        String finalToId = toId;
        String classroomDirections = null;
        
        if (toId.startsWith("ROOM_")) {
            // Room format: ROOM_[Block]_[RoomNo]
            // Example: ROOM_38_402 -> Block 38, Room 402
            String[] parts = toId.split("_");
            String blockNum = parts[1];
            String roomNum = parts[2];
            char floorNum = roomNum.charAt(0);
            
            finalToId = "BLOCK_" + blockNum;
            classroomDirections = "Enter Building " + blockNum + ", go to Floor " + floorNum + ", and find Room " + roomNum + ".";
        }
        
        RouteResponse response = campusGraph.findShortestPath(fromId, finalToId);
        if (response != null && classroomDirections != null) {
            // Append the classroom guidance at the end of routing directions
            response.getDirections().add(classroomDirections);
        }
        return response;
    }

    public List<RouteResponse> getAlternativeRoutes(String fromId, String toId) {
        String finalToId = toId;
        String classroomDirections = null;
        
        if (toId.startsWith("ROOM_")) {
            String[] parts = toId.split("_");
            String blockNum = parts[1];
            String roomNum = parts[2];
            char floorNum = roomNum.charAt(0);
            
            finalToId = "BLOCK_" + blockNum;
            classroomDirections = "Enter Building " + blockNum + ", go to Floor " + floorNum + ", and find Room " + roomNum + ".";
        }
        
        List<RouteResponse> responses = campusGraph.findAlternativePaths(fromId, finalToId);
        if (classroomDirections != null) {
            for (RouteResponse response : responses) {
                response.getDirections().add(classroomDirections);
            }
        }
        return responses;
    }

    /**
     * BFS Path routing (demonstration).
     */
    public List<Node> getBFSPath(String fromId, String toId) {
        return campusGraph.findBFSPath(fromId, toId);
    }

    /**
     * DFS Path routing (demonstration).
     */
    public List<Node> getDFSPath(String fromId, String toId) {
        return campusGraph.findDFSPath(fromId, toId);
    }

    /**
     * Finds nearest facility (e.g. Washroom, ATM, Parking) using Dijkstra.
     */
    public Node findNearestFacility(String fromNodeId, String facilityType) {
        if (!campusGraph.getAllNodes().stream().anyMatch(n -> n.getId().equals(fromNodeId))) {
            return null;
        }

        Node nearestNode = null;
        double minDistance = Double.MAX_VALUE;

        for (Node node : campusGraph.getAllNodes()) {
            if (node.getType().equalsIgnoreCase(facilityType)) {
                RouteResponse route = campusGraph.findShortestPath(fromNodeId, node.getId());
                if (route != null && route.getDistance() < minDistance) {
                    minDistance = route.getDistance();
                    nearestNode = node;
                }
            }
        }
        return nearestNode;
    }

    public Collection<Node> getAllNodes() {
        return campusGraph.getAllNodes();
    }
}
