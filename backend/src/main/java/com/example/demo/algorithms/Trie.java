package com.example.demo.algorithms;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Trie {

    private static class TrieNode {
        Map<Character, TrieNode> children = new HashMap<>();
        boolean isEndOfWord = false;
        String locationId; // Storing matching node ID if applicable
        String fullName;   // Storing canonical display name
    }

    private final TrieNode root;

    public Trie() {
        this.root = new TrieNode();
    }

    /**
     * Inserts a location name and its metadata into the Trie.
     */
    public void insert(String name, String id) {
        if (name == null || name.trim().isEmpty()) return;
        
        String key = name.toLowerCase().trim();
        TrieNode current = root;
        
        for (int i = 0; i < key.length(); i++) {
            char ch = key.charAt(i);
            current.children.putIfAbsent(ch, new TrieNode());
            current = current.children.get(ch);
        }
        current.isEndOfWord = true;
        current.locationId = id;
        current.fullName = name;
    }

    /**
     * Finds suggestions for the given prefix.
     */
    public List<Suggestion> getSuggestions(String prefix) {
        List<Suggestion> suggestions = new ArrayList<>();
        if (prefix == null || prefix.trim().isEmpty()) return suggestions;

        String key = prefix.toLowerCase().trim();
        TrieNode current = root;

        // Traverse to the end of the prefix
        for (int i = 0; i < key.length(); i++) {
            char ch = key.charAt(i);
            if (!current.children.containsKey(ch)) {
                return suggestions; // No suggestions found
            }
            current = current.children.get(ch);
        }

        // Perform DFS from the current node to collect all words
        collectAllWords(current, suggestions);
        return suggestions;
    }

    private void collectAllWords(TrieNode node, List<Suggestion> suggestions) {
        if (node == null) return;
        if (node.isEndOfWord) {
            suggestions.add(new Suggestion(node.fullName, node.locationId));
        }

        for (TrieNode child : node.children.values()) {
            collectAllWords(child, suggestions);
        }
    }

    public static class Suggestion {
        private String name;
        private String id;

        public Suggestion(String name, String id) {
            this.name = name;
            this.id = id;
        }

        public String getName() {
            return name;
        }

        public String getId() {
            return id;
        }
    }
}
