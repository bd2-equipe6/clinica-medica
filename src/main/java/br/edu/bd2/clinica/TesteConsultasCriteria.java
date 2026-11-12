package br.edu.bd2.clinica;

import br.edu.bd2.clinica.consulta.ConsultasCriteria;
import br.edu.bd2.clinica.modelo.StatusAtendimento;

import java.time.LocalDateTime;

public class TesteConsultasCriteria {

    public static void main(String[] args) {

        ConsultasCriteria consultas = new ConsultasCriteria();

        System.out.println("=== TESTE DAS CONSULTAS CRITERIA ===");

        System.out.println("\n1. Pacientes encontrados por nome: "
                + consultas.buscarPacientesPorNome("a").size());

        System.out.println("2. Atendimentos por status: "
                + consultas.buscarAtendimentosPorStatus(
                StatusAtendimento.AGENDADO
        ).size());

        System.out.println("3. Atendimentos com filtros: "
                + consultas.buscarAtendimentosComFiltros(
                1L,
                1L,
                StatusAtendimento.AGENDADO,
                LocalDateTime.of(2000, 1, 1, 0, 0),
                LocalDateTime.of(2100, 12, 31, 23, 59)
        ).size());

        System.out.println("\nTodas as consultas Criteria foram executadas!");
    }
}