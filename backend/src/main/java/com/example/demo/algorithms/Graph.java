package com.example.demo.algorithms;

import com.example.demo.model.Edge;
import com.example.demo.model.Node;
import com.example.demo.model.RouteResponse;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

public class Graph {

    private final Map<String, Node> nodes = new HashMap<>();
    private final Map<String, List<Edge>> adjacencyList = new HashMap<>();

    public void addNode(Node node) {
        nodes.put(node.getId(), node);
        adjacencyList.putIfAbsent(node.getId(), new ArrayList<>());
    }

    public void addEdge(String fromId, String toId, double weight, String roadName) {
        // Ensure nodes exist or register placeholder
        if (!nodes.containsKey(fromId)) {
            addNode(new Node(fromId, fromId, "ROAD_NODE", 0.0, 0.0));
        }
        if (!nodes.containsKey(toId)) {
            addNode(new Node(toId, toId, "ROAD_NODE", 0.0, 0.0));
        }

        Edge edge1 = new Edge(fromId, toId, weight, roadName);
        Edge edge2 = new Edge(toId, fromId, weight, roadName); // Undirected graph for roads

        adjacencyList.get(fromId).add(edge1);
        adjacencyList.get(toId).add(edge2);
    }

    public Node getNode(String id) {
        return nodes.get(id);
    }

    public Collection<Node> getAllNodes() {
        return nodes.values();
    }

    public List<Edge> getNeighbors(String nodeId) {
        return adjacencyList.getOrDefault(nodeId, new ArrayList<>());
    }

    // Class to assist in priority queue operations
    private static class NodeDistance implements Comparable<NodeDistance> {
        String nodeId;
        double distance;

        NodeDistance(String nodeId, double distance) {
            this.nodeId = nodeId;
            this.distance = distance;
        }

        @Override
        public int compareTo(NodeDistance other) {
            return Double.compare(this.distance, other.distance);
        }
    }

    public RouteResponse findShortestPath(String startId, String endId) {
        return findShortestPathIgnoringEdges(startId, endId, null);
    }

    public RouteResponse findShortestPathIgnoringEdges(String startId, String endId, Set<String> ignoredEdges) {
        if (!nodes.containsKey(startId) || !nodes.containsKey(endId)) {
            return null;
        }

        Map<String, Double> distances = new HashMap<>();
        Map<String, String> parentNodes = new HashMap<>();
        Map<String, String> edgeNames = new HashMap<>(); // FromNodeId + "_" + ToNodeId -> RoadName
        
        PriorityQueue<NodeDistance> pq = new PriorityQueue<>();

        // Initialize distances
        for (String nodeId : nodes.keySet()) {
            distances.put(nodeId, Double.MAX_VALUE);
        }
        distances.put(startId, 0.0);
        pq.add(new NodeDistance(startId, 0.0));

        while (!pq.isEmpty()) {
            NodeDistance current = pq.poll();
            String u = current.nodeId;

            // If we reached target, we can terminate early
            if (u.equals(endId)) break;

            if (current.distance > distances.get(u)) continue;

            for (Edge edge : adjacencyList.getOrDefault(u, new ArrayList<>())) {
                String v = edge.getToNodeId();
                
                // Skip if edge is ignored
                if (ignoredEdges != null && (ignoredEdges.contains(u + "_" + v) || ignoredEdges.contains(v + "_" + u))) {
                    continue;
                }
                
                double weight = edge.getWeight();
                double newDist = distances.get(u) + weight;

                if (newDist < distances.get(v)) {
                    distances.put(v, newDist);
                    parentNodes.put(v, u);
                    edgeNames.put(u + "_" + v, edge.getRoadName());
                    pq.add(new NodeDistance(v, newDist));
                }
            }
        }

        // Reconstruct shortest path
        double totalDistance = distances.get(endId);
        if (totalDistance == Double.MAX_VALUE) {
            return null; // Route unreachable
        }

        List<Node> route = new ArrayList<>();
        List<String> directions = new ArrayList<>();
        
        String step = endId;
        while (step != null) {
            route.add(0, nodes.get(step));
            step = parentNodes.get(step);
        }

        // Generate directions step by step (e.g. Block A -> Road X -> Block B)
        for (int i = 0; i < route.size() - 1; i++) {
            String u = route.get(i).getId();
            String v = route.get(i + 1).getId();
            String road = edgeNames.get(u + "_" + v);
            if (road == null) road = edgeNames.get(v + "_" + u); // Fallback
            if (road == null || road.trim().isEmpty()) {
                road = "Walkway";
            }
            directions.add(route.get(i).getName() + " -> " + road + " -> " + route.get(i+1).getName());
        }

        int walkingTime = (int) Math.max(1, Math.round(totalDistance / 83.3));
        int cyclingTime = (int) Math.max(1, Math.round(totalDistance / 250.0));
        int shuttleTime = (int) Math.max(1, Math.round(totalDistance / 333.3));

        LocalTime etaTime = LocalTime.now().plusMinutes(walkingTime);
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("h:mm a");
        String etaStr = etaTime.format(formatter);

        double distKm = Math.round((totalDistance / 1000.0) * 10) / 10.0;
        if (distKm == 0) {
            distKm = 0.1;
        }

        return new RouteResponse(
                route,
                directions,
                distKm,
                walkingTime,
                cyclingTime,
                shuttleTime,
                etaStr
        );
    }

    public List<RouteResponse> findAlternativePaths(String startId, String endId) {
        List<RouteResponse> results = new ArrayList<>();
        
        // 1. Primary Route (Shortest)
        RouteResponse r1 = findShortestPath(startId, endId);
        if (r1 == null) {
            return results;
        }
        results.add(r1);
        
        // If route has very few nodes, no alternatives make sense
        List<Node> routeNodes = r1.getRoute();
        if (routeNodes.size() < 3) {
            return results;
        }
        
        // Find candidate edges to remove. Let's look at all edges in Route 1 and sort by length/weight.
        // We will temporarily exclude them one by one to find alternative paths.
        List<String[]> edgesInRoute = new ArrayList<>();
        for (int i = 0; i < routeNodes.size() - 1; i++) {
            String u = routeNodes.get(i).getId();
            String v = routeNodes.get(i + 1).getId();
            
            // Find edge weight
            double weight = 1.0;
            for (Edge edge : adjacencyList.getOrDefault(u, new ArrayList<>())) {
                if (edge.getToNodeId().equals(v)) {
                    weight = edge.getWeight();
                    break;
                }
            }
            edgesInRoute.add(new String[]{u, v, String.valueOf(weight)});
        }
        
        // Sort edges in descending order of weight
        edgesInRoute.sort((a, b) -> Double.compare(Double.parseDouble(b[2]), Double.parseDouble(a[2])));
        
        // Try up to 2 alternative routes by ignoring the longest edges
        int count = 0;
        for (String[] edgeInfo : edgesInRoute) {
            if (count >= 2) break; // Maximum 2 alternative routes (3 routes total)
            
            String u = edgeInfo[0];
            String v = edgeInfo[1];
            
            Set<String> ignored = new HashSet<>();
            ignored.add(u + "_" + v);
            ignored.add(v + "_" + u);
            
            RouteResponse rAlt = findShortestPathIgnoringEdges(startId, endId, ignored);
            if (rAlt != null && !isDuplicateRoute(results, rAlt)) {
                results.add(rAlt);
                count++;
            }
        }
        
        return results;
    }
    
    private boolean isDuplicateRoute(List<RouteResponse> list, RouteResponse newRoute) {
        for (RouteResponse r : list) {
            if (r.getRoute().size() == newRoute.getRoute().size()) {
                boolean match = true;
                for (int i = 0; i < r.getRoute().size(); i++) {
                    if (!r.getRoute().get(i).getId().equals(newRoute.getRoute().get(i).getId())) {
                        match = false;
                        break;
                    }
                }
                if (match) return true;
            }
        }
        return false;
    }

    /**
     * BREADTH-FIRST SEARCH (BFS)
     */
    public List<Node> findBFSPath(String startId, String endId) {
        if (!nodes.containsKey(startId) || !nodes.containsKey(endId)) {
            return new ArrayList<>();
        }

        Queue<String> queue = new LinkedList<>();
        Map<String, String> parentNodes = new HashMap<>();
        Set<String> visited = new HashSet<>();

        queue.add(startId);
        visited.add(startId);

        boolean found = false;
        while (!queue.isEmpty()) {
            String u = queue.poll();
            if (u.equals(endId)) {
                found = true;
                break;
            }

            for (Edge edge : adjacencyList.getOrDefault(u, new ArrayList<>())) {
                String v = edge.getToNodeId();
                if (!visited.contains(v)) {
                    visited.add(v);
                    parentNodes.put(v, u);
                    queue.add(v);
                }
            }
        }

        List<Node> route = new ArrayList<>();
        if (!found) return route;

        String step = endId;
        while (step != null) {
            route.add(0, nodes.get(step));
            step = parentNodes.get(step);
        }
        return route;
    }

    /**
     * DEPTH-FIRST SEARCH (DFS)
     */
    public List<Node> findDFSPath(String startId, String endId) {
        if (!nodes.containsKey(startId) || !nodes.containsKey(endId)) {
            return new ArrayList<>();
        }

        Map<String, String> parentNodes = new HashMap<>();
        Set<String> visited = new HashSet<>();
        
        boolean found = dfsHelper(startId, endId, visited, parentNodes);
        
        List<Node> route = new ArrayList<>();
        if (!found) return route;

        String step = endId;
        while (step != null) {
            route.add(0, nodes.get(step));
            step = parentNodes.get(step);
        }
        return route;
    }

    private boolean dfsHelper(String current, String target, Set<String> visited, Map<String, String> parentNodes) {
        if (current.equals(target)) return true;
        visited.add(current);

        for (Edge edge : adjacencyList.getOrDefault(current, new ArrayList<>())) {
            String neighbor = edge.getToNodeId();
            if (!visited.contains(neighbor)) {
                parentNodes.put(neighbor, current);
                if (dfsHelper(neighbor, target, visited, parentNodes)) {
                    return true;
                }
            }
        }
        return false;
    }
}
