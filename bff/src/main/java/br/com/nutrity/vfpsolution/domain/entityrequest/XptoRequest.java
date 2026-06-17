package br.com.nutrity.vfpsolution.domain.entityrequest;

import org.hibernate.validator.constraints.br.CPF;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
@Data
public class XptoRequest {
   
    @NotNull(message = "Name cannot be null")
    @Size(max = 255, message = "Name cannot exceed 255 characters")
    private String name;

    @CPF
    private String cpf;
}
