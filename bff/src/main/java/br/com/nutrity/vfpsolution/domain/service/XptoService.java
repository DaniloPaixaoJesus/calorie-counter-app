package br.com.nutrity.vfpsolution.domain.service;

import br.com.nutrity.vfpsolution.domain.dto.XptoDto;
import br.com.nutrity.vfpsolution.domain.entityrequest.XptoRequest;
import br.com.nutrity.vfpsolution.domain.repository.XptoRepository;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@AllArgsConstructor
public class XptoService {

    private final XptoRepository xptoRepository;

    public XptoDto create(XptoRequest xptoRequest) {
        return null;
    }
}
