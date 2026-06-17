package br.com.nutrity.vfpsolution.application.exceptionhandler;

import br.com.nutrity.vfpsolution.domain.exception.BusinessException;
import com.fasterxml.jackson.databind.exc.InvalidFormatException;
import com.fasterxml.jackson.databind.exc.PropertyBindingException;
import com.fasterxml.jackson.databind.JsonMappingException.Reference;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.ConstraintDeclarationException;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.slf4j.MDC;
import org.springframework.beans.TypeMismatchException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotAcceptableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.nio.file.AccessDeniedException;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@ControllerAdvice
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    public static final String END_USER_GENERAL_ERROR_MSG
            = "Ocorreu um erro inesperado. " +
            "Tente novamente e se o problema persistir entre em contato com o administrador de sistemas.";

    @Autowired
    private MessageSource messageSource;

    @Override
    protected ResponseEntity<Object> handleHttpMediaTypeNotAcceptable(
            HttpMediaTypeNotAcceptableException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {
        return ResponseEntity.status(status).headers(headers).build();
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        return handleValidationInternal(ex, headers, status, request, ex.getBindingResult());
    }

    @Override
    protected ResponseEntity<Object> handleNoHandlerFoundException(
            NoHandlerFoundException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request
    ) {
        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.RESOURCE_NOT_FUND;
        String detail = String.format("The resource %s you tried to access does not exist",
                ex.getRequestURL());

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(END_USER_GENERAL_ERROR_MSG)
                .build();

        return handleExceptionInternal(ex, customMessageHandler, headers, status, request);
    }

    @Override
    protected ResponseEntity<Object> handleTypeMismatch(
            TypeMismatchException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        if (ex instanceof MethodArgumentTypeMismatchException) {
            return handleMethodArgumentTypeMismatch((MethodArgumentTypeMismatchException) ex, headers, status, request);
        }

        return super.handleTypeMismatch(ex, headers, status, request);
    }

    @Override
    protected ResponseEntity<Object> handleHttpMessageNotReadable(
            HttpMessageNotReadableException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        Throwable rootCause = ExceptionUtils.getRootCause(ex);

        if (rootCause instanceof InvalidFormatException) {
            return handleInvalidFormat((InvalidFormatException) rootCause, headers, status, request);

        } else if (rootCause instanceof PropertyBindingException) {
            return handlePropertyBinding((PropertyBindingException) rootCause, headers, status, request);
        }

        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.MESSAGE_INCOMPREHENSIBLE;
        String detail = "The request body is invalid. Check syntax error.";

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(END_USER_GENERAL_ERROR_MSG)
                .build();

        return handleExceptionInternal(ex, customMessageHandler, headers, status, request);
    }

    @Override
    protected ResponseEntity<Object> handleExceptionInternal(
            Exception ex,
            Object body,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {
        MDC.put("stacktrace", ExceptionUtils.getStackTrace(ex));
        if (body == null) {
            body = CustomMessageHandler.builder()
                    .dataHora(OffsetDateTime.now())
                    .titulo(HttpStatus.resolve(status.value()).getReasonPhrase())
                    .status(status.value())
                    .mensagem(END_USER_GENERAL_ERROR_MSG)
                    .build();

        } else if (body instanceof String) {
            body = CustomMessageHandler.builder()
                    .dataHora(OffsetDateTime.now())
                    .titulo((String) body)
                    .status(status.value())
                    .mensagem(END_USER_GENERAL_ERROR_MSG)
                    .build();
        }
        return super.handleExceptionInternal(ex, body, headers, status, request);
    }

    @ExceptionHandler(ConstraintDeclarationException.class)
    public ResponseEntity<Object> handleConstraintDeclaration(ConstraintDeclarationException ex, WebRequest request) {
        HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR;
        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.SYSTEM_ERROR;
        String detail = END_USER_GENERAL_ERROR_MSG;

        log.error(ex.getMessage(), ex);

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(detail)
                .build();

        return handleExceptionInternal(ex, customMessageHandler, new HttpHeaders(), status, request);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Object> handleUncaught(Exception ex, WebRequest request) {
        HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR;
        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.SYSTEM_ERROR;
        String detail = END_USER_GENERAL_ERROR_MSG;

        log.error(ex.getMessage(), ex);

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(detail)
                .build();

        return handleExceptionInternal(ex, customMessageHandler, new HttpHeaders(), status, request);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<?> handleAccessDenied(AccessDeniedException ex, WebRequest request) {
        HttpStatus status = HttpStatus.FORBIDDEN;
        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.ACCESS_DENIED;
        String detail = ex.getMessage();

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(detail)
                .mensagem("Você não tem permissão para esta operação.")
                .build();

        return handleExceptionInternal(ex, customMessageHandler, new HttpHeaders(), status, request);
    }

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<?> handleEntityNotFound(EntityNotFoundException ex, WebRequest request) {
        HttpStatus status = HttpStatus.NOT_FOUND;
        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.RESOURCE_NOT_FUND;
        String detail = ex.getMessage();

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(detail)
                .build();

        return handleExceptionInternal(ex, customMessageHandler, new HttpHeaders(), status, request);
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<?> handleBusiness(BusinessException ex, WebRequest request) {
        HttpStatus status = HttpStatus.BAD_REQUEST;
        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.BUSINESS_ERROR;
        String detail = ex.getMessage();

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(detail)
                .build();

        return handleExceptionInternal(ex, customMessageHandler, new HttpHeaders(), status, request);
    }

    private ResponseEntity<Object> handleValidationInternal(
            Exception ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request,
            BindingResult bindingResult) {
        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.INVALID_DATA;
        String detail = "Um ou mais campos estão inválidos. Preencha corretamente e tente novamente.";

        List<CustomMessageHandler.Object> problemObjects = bindingResult.getAllErrors().stream()
                .map(objectError -> {
                    String message = messageSource.getMessage(objectError, LocaleContextHolder.getLocale());

                    String name = objectError.getObjectName();

                    if (objectError instanceof FieldError) {
                        name = ((FieldError) objectError).getField();
                    }

                    return CustomMessageHandler.Object.builder()
                            .nome(name)
                            .mensagem(message)
                            .build();
                })
                .collect(Collectors.toList());

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(detail)
                .objects(problemObjects)
                .build();

        return handleExceptionInternal(ex, customMessageHandler, headers, status, request);
    }

    private ResponseEntity<Object> handleMethodArgumentTypeMismatch(
            MethodArgumentTypeMismatchException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.INVALID_PARAMETER;

        String detail = String.format(
                "The URL parameter '%s' received the value '%s', " +
                        "which is of an invalid type. Correct and enter a value compatible with type %s.",
                ex.getName(), ex.getValue(), ex.getRequiredType().getSimpleName());

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(END_USER_GENERAL_ERROR_MSG)
                .build();

        return handleExceptionInternal(ex, customMessageHandler, headers, status, request);
    }

    private ResponseEntity<Object> handlePropertyBinding(
            PropertyBindingException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        String path = joinPath(ex.getPath());

        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.MESSAGE_INCOMPREHENSIBLE;
        String detail = String.format("Property '%s' does not exist. " +
                "Correct or remove this property and try again.", path);

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(END_USER_GENERAL_ERROR_MSG)
                .build();

        return handleExceptionInternal(ex, customMessageHandler, headers, status, request);
    }

    private ResponseEntity<Object> handleInvalidFormat(
            InvalidFormatException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        String path = joinPath(ex.getPath());

        ExceptionHandlerErrorType exceptionHandlerErrorType = ExceptionHandlerErrorType.MESSAGE_INCOMPREHENSIBLE;
        String detail = String.format("Propriedade '%s' valor '%s'com tipo inválido. " +
                        "Informe um valor com tipo compatível.",
                path, ex.getValue(), ex.getTargetType().getSimpleName());

        CustomMessageHandler customMessageHandler = createCustomMessageBuilder(status, exceptionHandlerErrorType, detail)
                .mensagem(END_USER_GENERAL_ERROR_MSG)
                .build();

        return handleExceptionInternal(ex, customMessageHandler, headers, status, request);
    }


    private CustomMessageHandler.CustomMessageHandlerBuilder createCustomMessageBuilder(
            HttpStatusCode status,
            ExceptionHandlerErrorType exceptionHandlerErrorType,
            String detail
    ) {

        return CustomMessageHandler.builder()
                .dataHora(OffsetDateTime.now())
                .status(status.value())
                .titulo(exceptionHandlerErrorType.getTitle())
                .detalhe(detail);
    }

    private String joinPath(List<Reference> references) {
        return references.stream()
                .map(Reference::getFieldName)
                .collect(Collectors.joining("."));
    }
}
