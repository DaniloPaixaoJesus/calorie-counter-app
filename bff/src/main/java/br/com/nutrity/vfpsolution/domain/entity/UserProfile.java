package br.com.nutrity.vfpsolution.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDate;
import java.time.OffsetDateTime;

@Entity
@Table(name = "nutrity_users")
public class UserProfile {

    @Id
    @Column(length = 24)
    private String id;

    @Column(nullable = false, unique = true, length = 254)
    private String email;

    @Column(nullable = false, length = 160)
    private String name;

    @Column(length = 600)
    private String photoUrl;

    private LocalDate birthDate;

    @Column(length = 32)
    private String gender;

    @Column(nullable = false)
    private Integer dailyCalorieGoal;

    @Column(nullable = false, length = 12)
    private String locale;

    @Column(nullable = false)
    private Boolean premium;

    @Column(nullable = false)
    private OffsetDateTime createdAt;

    @Column(nullable = false)
    private OffsetDateTime updatedAt;

    protected UserProfile() {
    }

    public UserProfile(
            String id,
            String email,
            String name,
            String photoUrl,
            LocalDate birthDate,
            String gender,
            Integer dailyCalorieGoal,
            String locale,
            Boolean premium,
            OffsetDateTime createdAt,
            OffsetDateTime updatedAt
    ) {
        this.id = id;
        this.email = email;
        this.name = name;
        this.photoUrl = photoUrl;
        this.birthDate = birthDate;
        this.gender = gender;
        this.dailyCalorieGoal = dailyCalorieGoal;
        this.locale = locale;
        this.premium = premium;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public String getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getName() {
        return name;
    }

    public String getPhotoUrl() {
        return photoUrl;
    }

    public LocalDate getBirthDate() {
        return birthDate;
    }

    public String getGender() {
        return gender;
    }

    public Integer getDailyCalorieGoal() {
        return dailyCalorieGoal;
    }

    public String getLocale() {
        return locale;
    }

    public Boolean getPremium() {
        return premium;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void updateFromGoogle(String name, String photoUrl, String locale, OffsetDateTime updatedAt) {
        this.name = name;
        this.photoUrl = photoUrl;
        this.locale = locale;
        this.premium = true;
        this.updatedAt = updatedAt;
    }

    public void updateProfile(String name, LocalDate birthDate, String gender, Integer dailyCalorieGoal, String locale) {
        this.name = name;
        this.birthDate = birthDate;
        this.gender = gender;
        this.dailyCalorieGoal = dailyCalorieGoal;
        this.locale = locale;
        this.updatedAt = OffsetDateTime.now();
    }
}
