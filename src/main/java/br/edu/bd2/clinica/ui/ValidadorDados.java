package br.edu.bd2.clinica.ui;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.Query;

import br.edu.bd2.clinica.modelo.StatusAtendimento;
import br.edu.bd2.clinica.util.JPAUtil;

public class ValidadorDados {
    private static final long META_PACIENTES = 200;
    private static final long META_PROCEDIMENTOS = 100;
    private static final long META_UNIDADES = 5;
    private static final long META_ATENDIMENTOS = 2000;
    private static final long MIN_DIAS_PERIODO = 730;

    private int problemas = 0;
    private int avisos = 0;

    public void executar() {
        problemas = 0;
        avisos = 0;
        EntityManager em = JPAUtil.getEntityManager();
        try {
            System.out.println("\n=== VALIDAÇÃO DOS DADOS GERADOS ===");

            System.out.println("\n-- Quantidades (metas do enunciado) --");
            conferirQuantidade(em, "Paciente", META_PACIENTES);
            conferirQuantidade(em, "Procedimento", META_PROCEDIMENTOS);
            conferirQuantidade(em, "Unidade", META_UNIDADES);
            conferirQuantidade(em, "Atendimento", META_ATENDIMENTOS);

            System.out.println("\n-- Demais tabelas (informativo) --");
            for (String e : new String[] {"Medico", "Especialidade", "CategoriaProcedimento",
                    "Convenio", "Prontuario", "ItemAtendimento"}) {
                System.out.printf("%-26s %d%n", e, contar(em, "SELECT COUNT(e) FROM " + e + " e"));
            }

            conferirPeriodo(em);

            System.out.println("\n-- Integridade e qualidade --");
            Object[] hoje = {"hoje", java.time.LocalDate.now()};
            conferirZero(em, "Pacientes sem nome ou CPF", true,
                    "SELECT COUNT(p) FROM Paciente p WHERE p.nome IS NULL OR p.cpf IS NULL");
            conferirZero(em, "Pacientes com nascimento nulo ou futuro", true,
                    "SELECT COUNT(p) FROM Paciente p WHERE p.dataNascimento IS NULL OR p.dataNascimento > :hoje",
                    hoje);
            conferirZero(em, "Pacientes sem cidade no endereço", false,
                    "SELECT COUNT(p) FROM Paciente p WHERE p.endereco.cidade IS NULL");
            conferirZero(em, "Pacientes sem prontuário", false,
                    "SELECT COUNT(p) FROM Paciente p WHERE NOT EXISTS "
                    + "(SELECT r FROM Prontuario r WHERE r.paciente = p)");
            conferirZero(em, "Pacientes sem nenhum atendimento", false,
                    "SELECT COUNT(p) FROM Paciente p WHERE NOT EXISTS "
                    + "(SELECT a FROM Atendimento a WHERE a.paciente = p)");
            conferirZero(em, "Médicos sem especialidade", true,
                    "SELECT COUNT(m) FROM Medico m WHERE m.especialidades IS EMPTY");
            conferirZero(em, "Procedimentos com valor base nulo ou <= 0", true,
                    "SELECT COUNT(p) FROM Procedimento p WHERE p.valorBase IS NULL OR p.valorBase <= 0");
            conferirZero(em, "Convênios com desconto fora de 0 a 100", true,
                    "SELECT COUNT(c) FROM Convenio c WHERE c.percentualDesconto < 0 OR c.percentualDesconto > 100");
            conferirZero(em, "Atendimentos sem nenhum item", true,
                    "SELECT COUNT(a) FROM Atendimento a WHERE a.listaItens IS EMPTY");
            conferirZero(em, "Itens com quantidade <= 0 ou valor unitário nulo/<= 0", true,
                    "SELECT COUNT(i) FROM ItemAtendimento i WHERE i.quantidade <= 0 "
                    + "OR i.valorUnitario IS NULL OR i.valorUnitario <= 0");
            conferirZero(em, "Itens com desconto nulo (atrapalha somas no DW)", false,
                    "SELECT COUNT(i) FROM ItemAtendimento i WHERE i.desconto IS NULL");
            conferirZero(em, "Itens com desconto negativo ou maior que o valor do item", true,
                    "SELECT COUNT(i) FROM ItemAtendimento i WHERE i.desconto < 0 "
                    + "OR i.desconto > i.valorUnitario * i.quantidade");

            LocalDateTime agora = LocalDateTime.now();
            conferirZero(em, "Atendimentos REALIZADOS com data no futuro", false,
                    "SELECT COUNT(a) FROM Atendimento a WHERE a.statusAtendimento = :s AND a.dataHora > :agora",
                    new Object[] {"s", StatusAtendimento.REALIZADO}, new Object[] {"agora", agora});
            conferirZero(em, "Atendimentos AGENDADOS com data no passado", false,
                    "SELECT COUNT(a) FROM Atendimento a WHERE a.statusAtendimento = :s AND a.dataHora < :agora",
                    new Object[] {"s", StatusAtendimento.AGENDADO}, new Object[] {"agora", agora});

            List<?> dup = em.createQuery("SELECT p.cpf FROM Pessoa p WHERE p.cpf IS NOT NULL "
                    + "GROUP BY p.cpf HAVING COUNT(p) > 1").getResultList();
            imprimirResultado("CPFs duplicados (pacientes + médicos)", dup.size(), true);

            System.out.println("\n-- Distribuição dos atendimentos (confira se está equilibrada) --");
            agrupado(em, "Por ano",
                    "SELECT YEAR(a.dataHora), COUNT(a) FROM Atendimento a "
                    + "GROUP BY YEAR(a.dataHora) ORDER BY YEAR(a.dataHora)");
            agrupado(em, "Por status",
                    "SELECT a.statusAtendimento, COUNT(a) FROM Atendimento a "
                    + "GROUP BY a.statusAtendimento ORDER BY COUNT(a) DESC");
            agrupado(em, "Por tipo",
                    "SELECT a.tipoAtendimento, COUNT(a) FROM Atendimento a "
                    + "GROUP BY a.tipoAtendimento ORDER BY COUNT(a) DESC");
            agrupado(em, "Por unidade",
                    "SELECT a.unidade.nome, COUNT(a) FROM Atendimento a "
                    + "GROUP BY a.unidade.nome ORDER BY COUNT(a) DESC");
            agrupado(em, "Por categoria de procedimento (itens)",
                    "SELECT i.procedimento.categoria.nome, COUNT(i) FROM ItemAtendimento i "
                    + "GROUP BY i.procedimento.categoria.nome ORDER BY COUNT(i) DESC");

            System.out.println("\n=== RESUMO: " + problemas + " problema(s), " + avisos + " aviso(s) ===");
            if (problemas == 0 && avisos == 0) {
                System.out.println("Dados consistentes e prontos para a Entrega 2 (Data Warehouse).");
            }
        } finally {
            em.close();
        }
    }

    private long contar(EntityManager em, String jpql, Object[]... params) {
        Query q = em.createQuery(jpql);
        for (Object[] p : params) {
            q.setParameter((String) p[0], p[1]);
        }
        return (Long) q.getSingleResult();
    }

    private void conferirQuantidade(EntityManager em, String entidade, long esperado) {
        long real = contar(em, "SELECT COUNT(e) FROM " + entidade + " e");
        boolean ok = real == esperado;
        if (!ok) {
            problemas++;
        }
        System.out.printf("%-26s esperado=%-6d encontrado=%-6d %s%n",
                entidade, esperado, real, ok ? "OK" : "PROBLEMA");
    }

    private void conferirPeriodo(EntityManager em) {
        Object[] r = (Object[]) em.createQuery(
                "SELECT MIN(a.dataHora), MAX(a.dataHora) FROM Atendimento a").getSingleResult();
        System.out.println();
        if (r[0] == null) {
            problemas++;
            System.out.println("Período dos atendimentos: nenhum atendimento encontrado  PROBLEMA");
            return;
        }
        LocalDateTime min = (LocalDateTime) r[0];
        LocalDateTime max = (LocalDateTime) r[1];
        long dias = ChronoUnit.DAYS.between(min, max);
        boolean ok = dias >= MIN_DIAS_PERIODO;
        if (!ok) {
            problemas++;
        }
        System.out.printf("Período dos atendimentos: %s até %s (%d dias, mínimo %d) %s%n",
                min.toLocalDate(), max.toLocalDate(), dias, MIN_DIAS_PERIODO, ok ? "OK" : "PROBLEMA");
    }

    private void conferirZero(EntityManager em, String descricao, boolean critico,
            String jpql, Object[]... params) {
        imprimirResultado(descricao, contar(em, jpql, params), critico);
    }

    private void imprimirResultado(String descricao, long qtd, boolean critico) {
        String status = "OK";
        if (qtd > 0) {
            status = critico ? "PROBLEMA" : "AVISO";
            if (critico) {
                problemas++;
            } else {
                avisos++;
            }
        }
        System.out.printf("%-62s %6d  %s%n", descricao, qtd, status);
    }

    private void agrupado(EntityManager em, String titulo, String jpql) {
        System.out.println(titulo + ":");
        List<?> linhas = em.createQuery(jpql).getResultList();
        for (Object o : linhas) {
            Object[] l = (Object[]) o;
            System.out.printf("   %-35s %s%n", l[0], l[1]);
        }
    }
}
