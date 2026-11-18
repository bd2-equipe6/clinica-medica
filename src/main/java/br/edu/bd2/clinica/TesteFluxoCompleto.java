package br.edu.bd2.clinica;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;

import javax.persistence.EntityManager;
import javax.persistence.EntityTransaction;

import br.edu.bd2.clinica.modelo.Atendimento;
import br.edu.bd2.clinica.modelo.Convenio;
import br.edu.bd2.clinica.modelo.ItemAtendimento;
import br.edu.bd2.clinica.modelo.Medico;
import br.edu.bd2.clinica.modelo.Paciente;
import br.edu.bd2.clinica.modelo.Procedimento;
import br.edu.bd2.clinica.modelo.StatusAtendimento;
import br.edu.bd2.clinica.modelo.TipoAtendimento;
import br.edu.bd2.clinica.modelo.Unidade;
import br.edu.bd2.clinica.util.JPAUtil;

/**
 * Teste do fluxo completo OLTP -> DW (passo 1 de 3).
 *
 * 1. Rodar esta classe: ela cadastra um atendimento novo pela aplicação.
 * 2. Rodar o ETL (scripts de sql/etl/).
 * 3. Rodar sql/validacao/teste_fluxo_completo.sql e conferir se o atendimento chegou no DW.
 */
public class TesteFluxoCompleto {

    public static void main(String[] args) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();

        try {
            Paciente paciente = primeiro(em, Paciente.class);
            Medico medico = primeiro(em, Medico.class);
            Unidade unidade = primeiro(em, Unidade.class);
            Procedimento procedimento = primeiro(em, Procedimento.class);

            if (paciente == null || medico == null || unidade == null || procedimento == null) {
                System.out.println("O banco está sem dados. Rode o GeradorDados antes deste teste.");
                return;
            }

            int quantidade = 2;
            BigDecimal valorUnitario = procedimento.getValorBase();
            BigDecimal valorBruto = valorUnitario.multiply(BigDecimal.valueOf(quantidade));
            BigDecimal desconto = calcularDesconto(valorBruto, paciente.getConvenio());

            Atendimento atendimento = new Atendimento(
                    LocalDateTime.now(),
                    TipoAtendimento.CONSULTA,
                    StatusAtendimento.REALIZADO,
                    paciente, medico, unidade);

            ItemAtendimento item = new ItemAtendimento(
                    quantidade, valorUnitario, desconto, procedimento, atendimento);
            atendimento.getListaItens().add(item);

            tx.begin();
            em.persist(atendimento);
            tx.commit();

            System.out.println();
            System.out.println("===== Atendimento de teste cadastrado no OLTP =====");
            System.out.println("Atendimento id ....... " + atendimento.getId());
            System.out.println("Item id .............. " + item.getId());
            System.out.println("Data/hora ............ " + atendimento.getDataHora());
            System.out.println("Paciente ............. " + paciente.getNome());
            System.out.println("Médico ............... " + medico.getNome());
            System.out.println("Unidade .............. " + unidade.getNome());
            System.out.println("Procedimento ......... " + procedimento.getNome());
            System.out.println("Quantidade ........... " + quantidade);
            System.out.println("Valor bruto esperado . " + valorBruto);
            System.out.println("Desconto esperado .... " + desconto);
            System.out.println("Valor líquido esperado " + valorBruto.subtract(desconto));
            System.out.println();
            System.out.println("Agora rode o ETL e depois sql/validacao/teste_fluxo_completo.sql.");

        } catch (RuntimeException e) {
            if (tx.isActive()) {
                tx.rollback();
            }
            throw e;
        } finally {
            em.close();
            JPAUtil.fechar();
        }
    }

    private static <T> T primeiro(EntityManager em, Class<T> classe) {
        return em.createQuery("SELECT e FROM " + classe.getSimpleName() + " e ORDER BY e.id", classe)
                .setMaxResults(1)
                .getResultList()
                .stream()
                .findFirst()
                .orElse(null);
    }

    private static BigDecimal calcularDesconto(BigDecimal valorBruto, Convenio convenio) {
        if (convenio == null || convenio.getPercentualDesconto() == null) {
            return BigDecimal.ZERO.setScale(2);
        }
        return valorBruto.multiply(convenio.getPercentualDesconto())
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }
}
