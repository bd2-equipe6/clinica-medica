package br.edu.bd2.clinica.consulta;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.criteria.CriteriaBuilder;
import javax.persistence.criteria.CriteriaQuery;
import javax.persistence.criteria.Predicate;
import javax.persistence.criteria.Root;

import br.edu.bd2.clinica.modelo.Atendimento;
import br.edu.bd2.clinica.modelo.Paciente;
import br.edu.bd2.clinica.modelo.StatusAtendimento;
import br.edu.bd2.clinica.util.JPAUtil;

public class ConsultasCriteria {

    public List<Paciente> buscarPacientesPorNome(String nome) {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            CriteriaBuilder cb = em.getCriteriaBuilder();

            CriteriaQuery<Paciente> cq = cb.createQuery(Paciente.class);

            Root<Paciente> root = cq.from(Paciente.class);

            cq.select(root);

            cq.where(
                    cb.like(
                            cb.lower(root.<String>get("nome")),
                            "%" + nome.toLowerCase() + "%"
                    )
            );

            cq.orderBy(cb.asc(root.get("nome")));

            return em.createQuery(cq).getResultList();

        } finally {
            em.close();
        }
    }

    public List<Atendimento> buscarAtendimentosPorStatus(
            StatusAtendimento status) {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            CriteriaBuilder cb = em.getCriteriaBuilder();

            CriteriaQuery<Atendimento> cq =
                    cb.createQuery(Atendimento.class);

            Root<Atendimento> root = cq.from(Atendimento.class);

            cq.select(root);

            cq.where(
                    cb.equal(root.get("statusAtendimento"), status)
            );

            cq.orderBy(cb.asc(root.get("dataHora")));

            return em.createQuery(cq).getResultList();

        } finally {
            em.close();
        }
    }

    public List<Atendimento> buscarAtendimentosComFiltros(
            Long medicoId,
            Long pacienteId,
            StatusAtendimento status,
            LocalDateTime inicio,
            LocalDateTime fim) {

        EntityManager em = JPAUtil.getEntityManager();

        try {
            CriteriaBuilder cb = em.getCriteriaBuilder();

            CriteriaQuery<Atendimento> cq =
                    cb.createQuery(Atendimento.class);

            Root<Atendimento> root = cq.from(Atendimento.class);

            List<Predicate> filtros = new ArrayList<>();

            if (medicoId != null) {
                filtros.add(
                        cb.equal(root.get("medico").get("id"), medicoId)
                );
            }

            if (pacienteId != null) {
                filtros.add(
                        cb.equal(root.get("paciente").get("id"), pacienteId)
                );
            }

            if (status != null) {
                filtros.add(
                        cb.equal(root.get("statusAtendimento"), status)
                );
            }

            if (inicio != null) {
                filtros.add(
                        cb.greaterThanOrEqualTo(
                                root.<LocalDateTime>get("dataHora"), inicio
                        )
                );
            }

            if (fim != null) {
                filtros.add(
                        cb.lessThanOrEqualTo(
                                root.<LocalDateTime>get("dataHora"), fim
                        )
                );
            }

            cq.select(root);

            cq.where(filtros.toArray(new Predicate[0]));

            cq.orderBy(cb.asc(root.get("dataHora")));

            return em.createQuery(cq).getResultList();

        } finally {
            em.close();
        }
    }
}