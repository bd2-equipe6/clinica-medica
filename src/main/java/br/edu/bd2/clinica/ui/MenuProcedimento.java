package br.edu.bd2.clinica.ui;

import java.math.BigDecimal;
import java.util.List;

import javax.persistence.EntityManager;

import br.edu.bd2.clinica.dao.GenericDAO;
import br.edu.bd2.clinica.modelo.CategoriaProcedimento;
import br.edu.bd2.clinica.modelo.Procedimento;
import br.edu.bd2.clinica.util.JPAUtil;

public class MenuProcedimento {
    private static final int TAM_PAGINA = 15;

    private final GenericDAO<Procedimento, Long> dao = new GenericDAO<>(Procedimento.class);
    private final GenericDAO<CategoriaProcedimento, Long> categoriaDao =
            new GenericDAO<>(CategoriaProcedimento.class);

    public void executar() {
        int op;
        do {
            System.out.println("\n=== PROCEDIMENTOS ===");
            System.out.println("1 - Cadastrar");
            System.out.println("2 - Listar (paginado)");
            System.out.println("3 - Consultar por ID");
            System.out.println("4 - Atualizar");
            System.out.println("5 - Excluir");
            System.out.println("0 - Voltar");
            op = ConsoleUtil.lerInt("Opção");
            try {
                switch (op) {
                    case 1: cadastrar(); break;
                    case 2: listar(); break;
                    case 3: consultarPorId(); break;
                    case 4: atualizar(); break;
                    case 5: excluir(); break;
                    case 0: break;
                    default: System.out.println("Opção inválida.");
                }
            } catch (RuntimeException e) {
                System.out.println("Erro na operação: " + ConsoleUtil.mensagemErro(e));
            }
        } while (op != 0);
    }

    private void cadastrar() {
        String codigo = ConsoleUtil.lerTexto("Código (único)");
        if (codigoJaExiste(codigo)) {
            System.out.println("Já existe um procedimento com esse código.");
            return;
        }
        String nome = ConsoleUtil.lerTexto("Nome");
        BigDecimal valor = ConsoleUtil.lerDecimal("Valor base (R$)");
        CategoriaProcedimento categoria = escolherCategoria();

        Procedimento p = new Procedimento(codigo, nome, valor, categoria);
        dao.salvar(p);
        System.out.println("Procedimento cadastrado com ID " + p.getId());
    }

    private boolean codigoJaExiste(String codigo) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            Long qtd = em.createQuery("SELECT COUNT(p) FROM Procedimento p WHERE p.codigo = :c", Long.class)
                    .setParameter("c", codigo).getSingleResult();
            return qtd > 0;
        } finally {
            em.close();
        }
    }

    private CategoriaProcedimento escolherCategoria() {
        while (true) {
            List<CategoriaProcedimento> categorias = categoriaDao.listarTodos();
            if (categorias.isEmpty()) {
                System.out.println("Nenhuma categoria cadastrada. Vamos criar a primeira.");
                return criarCategoria();
            }
            System.out.println("Categorias:");
            for (CategoriaProcedimento c : categorias) {
                System.out.println("  " + c.getId() + " - " + c.getNome());
            }
            Long id = ConsoleUtil.lerLong("ID da categoria (0 para criar nova)");
            if (id == 0) {
                return criarCategoria();
            }
            CategoriaProcedimento escolhida = categoriaDao.buscarPorId(id);
            if (escolhida != null) {
                return escolhida;
            }
            System.out.println("Categoria não encontrada.");
        }
    }

    private CategoriaProcedimento criarCategoria() {
        while (true) {
            String nome = ConsoleUtil.lerTexto("Nome da nova categoria");
            try {
                CategoriaProcedimento c = categoriaDao.salvar(new CategoriaProcedimento(nome));
                System.out.println("Categoria criada com ID " + c.getId());
                return c;
            } catch (RuntimeException e) {
                System.out.println("Não foi possível criar a categoria (nome já existe?): "
                        + ConsoleUtil.mensagemErro(e));
            }
        }
    }

    private void listar() {
        int pagina = 0;
        while (true) {
            EntityManager em = JPAUtil.getEntityManager();
            long total;
            List<Procedimento> lista;
            try {
                total = em.createQuery("SELECT COUNT(p) FROM Procedimento p", Long.class).getSingleResult();
                lista = em.createQuery(
                        "SELECT p FROM Procedimento p JOIN FETCH p.categoria ORDER BY p.id",
                        Procedimento.class)
                        .setFirstResult(pagina * TAM_PAGINA)
                        .setMaxResults(TAM_PAGINA)
                        .getResultList();
            } finally {
                em.close();
            }

            long totalPaginas = Math.max(1, (total + TAM_PAGINA - 1) / TAM_PAGINA);
            System.out.println("\nProcedimentos - página " + (pagina + 1) + " de " + totalPaginas
                    + " (total: " + total + ")");
            for (Procedimento p : lista) {
                imprimir(p);
            }

            String cmd = ConsoleUtil.lerComando("[P]róxima, [A]nterior ou [S]air");
            if (cmd.equals("p") && pagina + 1 < totalPaginas) {
                pagina++;
            } else if (cmd.equals("a") && pagina > 0) {
                pagina--;
            } else if (cmd.equals("s")) {
                return;
            }
        }
    }

    private Procedimento buscarComCategoria(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            List<Procedimento> r = em.createQuery(
                    "SELECT p FROM Procedimento p JOIN FETCH p.categoria WHERE p.id = :id",
                    Procedimento.class).setParameter("id", id).getResultList();
            return r.isEmpty() ? null : r.get(0);
        } finally {
            em.close();
        }
    }

    private void consultarPorId() {
        Procedimento p = buscarComCategoria(ConsoleUtil.lerLong("ID do procedimento"));
        if (p == null) {
            System.out.println("Procedimento não encontrado.");
        } else {
            imprimir(p);
        }
    }

    private void atualizar() {
        Procedimento p = buscarComCategoria(ConsoleUtil.lerLong("ID do procedimento"));
        if (p == null) {
            System.out.println("Procedimento não encontrado.");
            return;
        }
        imprimir(p);
        System.out.println("Enter mantém o valor atual.");
        p.setNome(ConsoleUtil.lerTextoOuManter("Nome", p.getNome()));
        p.setValorBase(ConsoleUtil.lerDecimalOuManter("Valor base (R$)", p.getValorBase()));

        if (ConsoleUtil.confirmar("Trocar a categoria?")) {
            p.setCategoria(escolherCategoria());
        }
        dao.atualizar(p);
        System.out.println("Procedimento atualizado.");
    }

    private void excluir() {
        Long id = ConsoleUtil.lerLong("ID do procedimento");
        Procedimento p = buscarComCategoria(id);
        if (p == null) {
            System.out.println("Procedimento não encontrado.");
            return;
        }
        imprimir(p);
        if (!ConsoleUtil.confirmar("Confirmar exclusão?")) {
            return;
        }
        try {
            dao.remover(id);
            System.out.println("Procedimento excluído.");
        } catch (RuntimeException e) {
            if (ConsoleUtil.violouIntegridade(e)) {
                System.out.println("Não foi possível excluir: o procedimento já foi usado em atendimentos.");
            } else {
                throw e;
            }
        }
    }

    private void imprimir(Procedimento p) {
        System.out.printf("[%d] %s | %s | R$ %s | Categoria: %s%n",
                p.getId(), p.getCodigo(), p.getNome(), p.getValorBase(),
                p.getCategoria().getNome());
    }
}
