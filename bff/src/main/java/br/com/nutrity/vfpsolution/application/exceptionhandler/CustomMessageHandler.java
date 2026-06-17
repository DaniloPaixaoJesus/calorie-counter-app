package br.com.nutrity.vfpsolution.application.exceptionhandler;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
@Getter
@Builder
public class CustomMessageHandler {

    @Schema(example = "400")
    private Integer status;
    @Schema(example = "2023-05-04T11:23:14.683-03:00")
    private OffsetDateTime dataHora;
    @Schema(example = "Dados inválidos")
    private String titulo;
    @Schema(example = "Um ou mais campos inválidos.")
    private String detalhe;
    @Schema(example = "Um ou mais campos inválidos.")
    private String mensagem;
    @Schema(description = "Lista de campos com erros")
    private List<Object> objects;

    @Getter
    @Builder
    @Schema(name = "ProblemObject")
    public static class Object {
        @Schema(example = "nome-campo")
        private String nome;

        @Schema(example = "é requerido")
        private String mensagem;
    }
}
