package com.example.demo.controller;

import com.example.demo.algorithms.Trie;
import com.example.demo.model.Node;
import com.example.demo.model.RouteResponse;
import com.example.demo.model.UserProfile;
import com.example.demo.service.NavigationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*") // Allow frontend integration from any origin (e.g. Flutter Web)
public class NavigationController {

    private final NavigationService navigationService;

    @Autowired
    public NavigationController(NavigationService navigationService) {
        this.navigationService = navigationService;
    }

    /**
     * UMS Login API
     */
    @PostMapping("/auth/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> request) {
        String regNo = request.get("registrationNumber");
        String password = request.get("password");
        String name = request.get("name"); // Dynamically input name

        if (regNo == null || password == null) {
            Map<String, String> err = new HashMap<>();
            err.put("error", "Registration number and password are required.");
            return ResponseEntity.badRequest().body(err);
        }

        UserProfile profile = navigationService.login(regNo, password, name);
        if (profile != null) {
            return ResponseEntity.ok(profile);
        } else {
            Map<String, String> err = new HashMap<>();
            err.put("error", "Invalid registration number or password.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(err);
        }
    }

    /**
     * Search Autocomplete Suggestions API
     */
    @GetMapping("/navigation/search")
    public ResponseEntity<List<Trie.Suggestion>> search(@RequestParam("q") String query) {
        return ResponseEntity.ok(navigationService.autocomplete(query));
    }

    /**
     * Shortest Path Routing API (Dijkstra)
     */
    @GetMapping("/navigation/route")
    public ResponseEntity<?> getRoute(@RequestParam("from") String from, @RequestParam("to") String to) {
        List<RouteResponse> routes = navigationService.getAlternativeRoutes(from, to);
        if (routes != null && !routes.isEmpty()) {
            return ResponseEntity.ok(routes);
        } else {
            Map<String, String> err = new HashMap<>();
            err.put("error", "No route found between selected points.");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(err);
        }
    }

    /**
     * BFS Path Routing API (for validation)
     */
    @GetMapping("/navigation/route/bfs")
    public ResponseEntity<List<Node>> getBFSRoute(@RequestParam("from") String from, @RequestParam("to") String to) {
        return ResponseEntity.ok(navigationService.getBFSPath(from, to));
    }

    /**
     * DFS Path Routing API (for validation)
     */
    @GetMapping("/navigation/route/dfs")
    public ResponseEntity<List<Node>> getDFSRoute(@RequestParam("from") String from, @RequestParam("to") String to) {
        return ResponseEntity.ok(navigationService.getDFSPath(from, to));
    }

    /**
     * Nearest Facility Lookup API (Washroom, ATM, etc.)
     */
    @GetMapping("/navigation/nearby")
    public ResponseEntity<?> getNearby(@RequestParam("from") String from, @RequestParam("type") String type) {
        Node nearest = navigationService.findNearestFacility(from, type);
        if (nearest != null) {
            return ResponseEntity.ok(nearest);
        } else {
            Map<String, String> err = new HashMap<>();
            err.put("error", "No facility of type " + type + " found nearby.");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(err);
        }
    }

    /**
     * Retrieve all map nodes (for custom Flutter canvas)
     */
    @GetMapping("/navigation/nodes")
    public ResponseEntity<Collection<Node>> getAllNodes() {
        return ResponseEntity.ok(navigationService.getAllNodes());
    }
}
