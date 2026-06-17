package br.com.nutrity.vfpsolution.application.api;

import br.com.nutrity.vfpsolution.domain.dto.XptoDto;
import br.com.nutrity.vfpsolution.domain.entity.Xpto;
import br.com.nutrity.vfpsolution.domain.entityrequest.XptoRequest;
import br.com.nutrity.vfpsolution.domain.service.XptoService;
import lombok.AllArgsConstructor;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@AllArgsConstructor
@RequestMapping("/xpto")
@Tag(name = "Xpto", description = "Operações relacionadas ao gerenciamento de xpto")
public class XptoController {

    private XptoService service;

    @Operation(summary = "Cria um novo Xpto", description = "Recebe os dados de um novo Xpto e o salva no banco de dados")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Xpto criado com sucesso",
                    content = { @Content(mediaType = "application/json", schema = @Schema(implementation = Xpto.class)) })
    })
    @PostMapping
    public ResponseEntity<XptoDto> criar(@Valid @RequestBody XptoRequest xptoRequest) {
        var xptoDto = service.create(xptoRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(xptoDto);
    }
}
