package br.com.nutrity.vfpsolution.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.OffsetDateTime;

@Entity
@Table(name = "nutrity_meals")
public class UserMeal {

    @Id
    @Column(length = 80)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserProfile user;

    @Column(nullable = false, length = 1000)
    private String descricao;

    @Column(nullable = false)
    private Integer calorias;

    @Column(nullable = false)
    private OffsetDateTime timestamp;

    @Column(nullable = false, length = 24)
    private String origem;

    private Double aiConfidence;

    @Column(length = 2000)
    private String nota;

    @Column(nullable = false, length = 40)
    private String iconKey;

    @Column(nullable = false)
    private Integer proteinGrams;

    @Column(nullable = false)
    private Integer carbohydrateGrams;

    @Column(nullable = false)
    private Integer fatGrams;

    protected UserMeal() {
    }

    public UserMeal(
            String id,
            UserProfile user,
            String descricao,
            Integer calorias,
            OffsetDateTime timestamp,
            String origem,
            Double aiConfidence,
            String nota,
            String iconKey,
            Integer proteinGrams,
            Integer carbohydrateGrams,
            Integer fatGrams
    ) {
        this.id = id;
        this.user = user;
        this.descricao = descricao;
        this.calorias = calorias;
        this.timestamp = timestamp;
        this.origem = origem;
        this.aiConfidence = aiConfidence;
        this.nota = nota;
        this.iconKey = iconKey;
        this.proteinGrams = proteinGrams;
        this.carbohydrateGrams = carbohydrateGrams;
        this.fatGrams = fatGrams;
    }

    public String getId() {
        return id;
    }

    public UserProfile getUser() {
        return user;
    }

    public String getDescricao() {
        return descricao;
    }

    public Integer getCalorias() {
        return calorias;
    }

    public OffsetDateTime getTimestamp() {
        return timestamp;
    }

    public String getOrigem() {
        return origem;
    }

    public Double getAiConfidence() {
        return aiConfidence;
    }

    public String getNota() {
        return nota;
    }

    public String getIconKey() {
        return iconKey;
    }

    public Integer getProteinGrams() {
        return proteinGrams;
    }

    public Integer getCarbohydrateGrams() {
        return carbohydrateGrams;
    }

    public Integer getFatGrams() {
        return fatGrams;
    }
}
