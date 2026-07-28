package br.com.nutrity.vfpsolution.infrastructure.persistence.sync;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name="nutrition_goals", uniqueConstraints=@UniqueConstraint(name="uk_goal_user_entity",columnNames={"user_id","entity_id"}))
public class NutritionGoalEntity {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @Column(name="user_id",nullable=false,length=24) private String userId;
    @Column(name="entity_id",nullable=false,length=80) private String entityId;
    @Column(name="modified_at",nullable=false) private OffsetDateTime modifiedAt;
    @Column(name="deleted_at") private OffsetDateTime deletedAt;
    @Column(name="payload_json", columnDefinition="TEXT") private String payloadJson;
    protected NutritionGoalEntity(){}
}
