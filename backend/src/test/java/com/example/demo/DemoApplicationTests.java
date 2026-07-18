package com.example.demo;

import com.example.demo.algorithms.Graph;
import com.example.demo.algorithms.Trie;
import com.example.demo.model.Node;
import com.example.demo.model.RouteResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class DemoApplicationTests {

    private Graph graph;
    private Trie trie;

    @BeforeEach
    void setUp() {
        // Set up fresh instances for test runs
        graph = new Graph();
        trie = new Trie();

        // Populate Graph
        graph.addNode(new Node("A", "Building A", "BLOCK", 31.0, 75.0));
        graph.addNode(new Node("B", "Building B Room", "BLOCK", 31.1, 75.1));
        graph.addNode(new Node("C", "Cafeteria C", "CAFETERIA", 31.2, 75.2));
        graph.addNode(new Node("D", "Dormitory D", "HOSTEL", 31.3, 75.3));

        // Connect A - B (100m), B - C (150m), A - C (300m), C - D (50m)
        graph.addEdge("A", "B", 100.0, "Road 1");
        graph.addEdge("B", "C", 150.0, "Road 2");
        graph.addEdge("A", "C", 300.0, "Road 3");
        graph.addEdge("C", "D", 50.0, "Road 4");

        // Populate Trie
        trie.insert("Building A", "A");
        trie.insert("Building B Room", "B");
        trie.insert("Cafeteria C", "C");
        trie.insert("Dormitory D", "D");
    }

    @Test
    void contextLoads() {
        // Basic context boot test
    }

    @Test
    void testTrieAutocomplete() {
        // Test exact matches and prefixes
        List<Trie.Suggestion> suggestions = trie.getSuggestions("Buil");
        assertEquals(2, suggestions.size()); // Building A and Building B Room
        assertEquals("Building A", suggestions.get(0).getName());
        assertEquals("A", suggestions.get(0).getId());

        // Test case insensitivity
        List<Trie.Suggestion> suggestionsLower = trie.getSuggestions("building");
        assertEquals(2, suggestionsLower.size());

        // Test non-matching prefix
        List<Trie.Suggestion> suggestionsNone = trie.getSuggestions("XYZ");
        assertTrue(suggestionsNone.isEmpty());
    }

    @Test
    void testDijkstraShortestPath() {
        // Shortest path A -> D should be A -> B -> C -> D (100 + 150 + 50 = 300m)
        // rather than A -> C -> D (300 + 50 = 350m)
        RouteResponse response = graph.findShortestPath("A", "D");
        assertNotNull(response);
        assertEquals(0.3, response.getDistance()); // 300m is 0.3 km
        
        List<Node> route = response.getRoute();
        assertEquals(4, route.size());
        assertEquals("A", route.get(0).getId());
        assertEquals("B", route.get(1).getId());
        assertEquals("C", route.get(2).getId());
        assertEquals("D", route.get(3).getId());

        // Check walking/cycling metrics
        assertTrue(response.getWalkingTime() > 0);
        assertTrue(response.getCyclingTime() > 0);
        assertNotNull(response.getEta());
    }

    @Test
    void testBFSPath() {
        // BFS path between A and D
        List<Node> path = graph.findBFSPath("A", "D");
        assertFalse(path.isEmpty());
        assertEquals("A", path.get(0).getId());
        assertEquals("D", path.get(path.size() - 1).getId());
    }

    @Test
    void testDFSPath() {
        // DFS path between A and D
        List<Node> path = graph.findDFSPath("A", "D");
        assertFalse(path.isEmpty());
        assertEquals("A", path.get(0).getId());
        assertEquals("D", path.get(path.size() - 1).getId());
    }
}
