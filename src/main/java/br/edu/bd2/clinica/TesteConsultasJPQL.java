
package br.edu.bd2.clinica;

import br.edu.bd2.clinica.consulta.ConsultasJPQL;
import br.edu.bd2.clinica.modelo.Atendimento;
import br.edu.bd2.clinica.modelo.Paciente;
import br.edu.bd2.clinica.modelo.StatusAtendimento;
import br.edu.bd2.clinica.util.JPAUtil;

import javax.persistence.EntityManager;
import java.time.LocalDateTime;

public class TesteConsultasJPQL {

    public static void main(String[] args) {

        ConsultasJPQL consultas = new ConsultasJPQL();

        LocalDateTime inicio = LocalDateTime.of(2000, 1, 1, 0, 0);
        LocalDateTime fim = LocalDateTime.of(2100, 12, 31, 23, 59);

        System.out.println("=== TESTE DAS CONSULTAS JPQL ===");

        try {
            System.out.println("1. Atendimentos por médico: "
                    + consultas.buscarAtendimentosPorMedico(1L).size());

            System.out.println("2. Atendimentos com itens: "
                    + consultas.buscarAtendimentosComItens().size());

            System.out.println("3. Contagem por médico: "
                    + consultas.contarAtendimentosPorMedico().size());

            System.out.println("4. Médicos com mais atendimentos: "
                    + consultas.buscarMedicosComMaisAtendimentos(0L).size());

            System.out.println("5. Pacientes com atendimentos realizados: "
                    + consultas.buscarPacientesComAtendimentosRealizados().size());

            System.out.println("6. Procedimentos por categoria: "
                    + consultas.buscarProcedimentosPorCategoria(1L).size());

            System.out.println("7. Atendimentos por período: "
                    + consultas.buscarAtendimentosPorPeriodo(inicio, fim).size());

            System.out.println("8. Pacientes paginados: "
                    + consultas.listarPacientesPaginados(0, 10).size());

            EntityManager em = JPAUtil.getEntityManager();

            try {
                System.out.println("9. NamedQuery de pacientes: "
                        + em.createNamedQuery("Paciente.buscarPorNome", Paciente.class)
                        .setParameter("nome", "%a%")
                        .getResultList().size());

                System.out.println("10. NamedQuery de atendimentos: "
                        + em.createNamedQuery("Atendimento.buscarPorStatus", Atendimento.class)
                        .setParameter("status", StatusAtendimento.AGENDADO)
                        .getResultList().size());

            } finally {
                em.close();
            }

            System.out.println("\nTodas as consultas foram executadas!");

        } catch (Exception e) {
            System.out.println("\nErro durante o teste:");
            e.printStackTrace();
        }
    }
}
