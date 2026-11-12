package br.edu.bd2.clinica.consulta;

import java.time.LocalDateTime;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.TypedQuery;

import br.edu.bd2.clinica.modelo.Atendimento;
import br.edu.bd2.clinica.modelo.Medico;
import br.edu.bd2.clinica.modelo.Paciente;
import br.edu.bd2.clinica.modelo.Procedimento;
import br.edu.bd2.clinica.modelo.StatusAtendimento;
import br.edu.bd2.clinica.util.JPAUtil;

public class ConsultasJPQL {

    public List<Atendimento> buscarAtendimentosPorMedico(Long medicoId) {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            TypedQuery<Atendimento> query = em.createQuery(
                    "SELECT a FROM Atendimento a " +
                            "JOIN a.medico m " +
                            "WHERE m.id = :medicoId",
                    Atendimento.class
            );

            query.setParameter("medicoId", medicoId);

            return query.getResultList();

        } finally {
            em.close();
        }
    }

    public List<Atendimento> buscarAtendimentosComItens() {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            TypedQuery<Atendimento> query = em.createQuery(
                    "SELECT DISTINCT a FROM Atendimento a " +
                            "JOIN FETCH a.listaItens i " +
                            "JOIN FETCH i.procedimento",
                    Atendimento.class
            );

            return query.getResultList();

        } finally {
            em.close();
        }
    }

    public List<Object[]> contarAtendimentosPorMedico() {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            return em.createQuery(
                    "SELECT a.medico.nome, COUNT(a) " +
                            "FROM Atendimento a " +
                            "GROUP BY a.medico.id, a.medico.nome",
                    Object[].class
            ).getResultList();

        } finally {
            em.close();
        }
    }

    public List<Object[]> buscarMedicosComMaisAtendimentos(Long quantidade) {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            TypedQuery<Object[]> query = em.createQuery(
                    "SELECT a.medico.id, a.medico.nome, COUNT(a) " +
                            "FROM Atendimento a " +
                            "GROUP BY a.medico.id, a.medico.nome " +
                            "HAVING COUNT(a) > :quantidade",
                    Object[].class
            );

            query.setParameter("quantidade", quantidade);

            return query.getResultList();

        } finally {
            em.close();
        }
    }

    public List<Paciente> buscarPacientesComAtendimentosRealizados() {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            TypedQuery<Paciente> query = em.createQuery(
                    "SELECT p FROM Paciente p " +
                            "WHERE EXISTS (" +
                            "SELECT a.id FROM Atendimento a " +
                            "WHERE a.paciente = p " +
                            "AND a.statusAtendimento = :status" +
                            ")",
                    Paciente.class
            );

            query.setParameter("status", StatusAtendimento.REALIZADO);

            return query.getResultList();

        } finally {
            em.close();
        }
    }

    public List<Procedimento> buscarProcedimentosPorCategoria(Long categoriaId) {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            TypedQuery<Procedimento> query = em.createQuery(
                    "SELECT p FROM Procedimento p " +
                            "JOIN p.categoria c " +
                            "WHERE c.id = :categoriaId",
                    Procedimento.class
            );

            query.setParameter("categoriaId", categoriaId);

            return query.getResultList();

        } finally {
            em.close();
        }
    }

    public List<Atendimento> buscarAtendimentosPorPeriodo(
            LocalDateTime inicio, LocalDateTime fim) {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            TypedQuery<Atendimento> query = em.createQuery(
                    "SELECT a FROM Atendimento a " +
                            "WHERE a.dataHora BETWEEN :inicio AND :fim " +
                            "ORDER BY a.dataHora",
                    Atendimento.class
            );

            query.setParameter("inicio", inicio);
            query.setParameter("fim", fim);

            return query.getResultList();

        } finally {
            em.close();
        }
    }

    public List<Paciente> listarPacientesPaginados(int pagina, int tamanho) {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            TypedQuery<Paciente> query = em.createQuery(
                    "SELECT p FROM Paciente p ORDER BY p.nome",
                    Paciente.class
            );

            query.setFirstResult(pagina * tamanho);
            query.setMaxResults(tamanho);

            return query.getResultList();

        } finally {
            em.close();
        }
    }
}