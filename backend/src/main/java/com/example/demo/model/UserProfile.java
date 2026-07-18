package com.example.demo.model;

public class UserProfile {
    private String registrationNumber;
    private String name;
    private String password;
    private String gender; // "boy" or "girl"

    public UserProfile() {}

    public UserProfile(String registrationNumber, String name, String password) {
        this(registrationNumber, name, password, "boy");
    }

    public UserProfile(String registrationNumber, String name, String password, String gender) {
        this.registrationNumber = registrationNumber;
        this.name = name;
        this.password = password;
        this.gender = gender;
    }

    public String getRegistrationNumber() {
        return registrationNumber;
    }

    public void setRegistrationNumber(String registrationNumber) {
        this.registrationNumber = registrationNumber;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }
}

