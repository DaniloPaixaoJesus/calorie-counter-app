package br.com.nutrity.vfpsolution.application.exceptionhandler;

import lombok.Getter;

@Getter
public enum ExceptionHandlerErrorType {

    INVALID_DATA("Dado inválido"),
    ACCESS_DENIED("Acesso negado"),
    SYSTEM_ERROR("Erro de sistema"),
    INVALID_PARAMETER("Parametro inválido"),
    MESSAGE_INCOMPREHENSIBLE("Mensagem não reconhecida"),
    RESOURCE_NOT_FUND("Recurso não encontrado"),
    ENTITY_IN_USE("Entidade em uso"),
    BUSINESS_ERROR("Regra de negócio violada");

    private String title;

    ExceptionHandlerErrorType(String title) {
        this.title = title;
    }
}
