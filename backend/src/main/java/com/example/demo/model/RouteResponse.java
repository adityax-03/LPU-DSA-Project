package com.example.demo.model;

import java.util.List;

public class RouteResponse {
    private List<Node> route;
    private List<String> directions; // step-by-step roads/names
    private double distance; // in meters/kms
    private int walkingTime; // in minutes
    private int cyclingTime; // in minutes
    private int shuttleTime; // in minutes
    private String eta;

    public RouteResponse() {}

    public RouteResponse(List<Node> route, List<String> directions, double distance, int walkingTime, int cyclingTime, int shuttleTime, String eta) {
        this.route = route;
        this.directions = directions;
        this.distance = distance;
        this.walkingTime = walkingTime;
        this.cyclingTime = cyclingTime;
        this.shuttleTime = shuttleTime;
        this.eta = eta;
    }

    public List<Node> getRoute() {
        return route;
    }

    public void setRoute(List<Node> route) {
        this.route = route;
    }

    public List<String> getDirections() {
        return directions;
    }

    public void setDirections(List<String> directions) {
        this.directions = directions;
    }

    public double getDistance() {
        return distance;
    }

    public void setDistance(double distance) {
        this.distance = distance;
    }

    public int getWalkingTime() {
        return walkingTime;
    }

    public void setWalkingTime(int walkingTime) {
        this.walkingTime = walkingTime;
    }

    public int getCyclingTime() {
        return cyclingTime;
    }

    public void setCyclingTime(int cyclingTime) {
        this.cyclingTime = cyclingTime;
    }

    public int getShuttleTime() {
        return shuttleTime;
    }

    public void setShuttleTime(int shuttleTime) {
        this.shuttleTime = shuttleTime;
    }

    public String getEta() {
        return eta;
    }

    public void setEta(String eta) {
        this.eta = eta;
    }
}
