package br.edu.bd2.clinica.ui;

import java.time.LocalDate;
import java.util.List;

import javax.persistence.EntityManager;

import br.edu.bd2.clinica.dao.GenericDAO;
import br.edu.bd2.clinica.modelo.Endereco;
import br.edu.bd2.clinica.modelo.Paciente;
import br.edu.bd2.clinica.modelo.Prontuario;
import br.edu.bd2.clinica.modelo.TipoSanguineo;
import br.edu.bd2.clinica.util.JPAUtil;

public class MenuPaciente {
    private static final int TAM_PAGINA = 15;

    private final GenericDAO<Paciente, Long> dao = new GenericDAO<>(Paciente.class);

    public void executar() {
        int op;
        do {
            System.out.println("\n=== PACIENTES ===");
            System.out.println("1 - Cadastrar");
            System.out.println("2 - Listar (paginado)");
            System.out.println("3 - Consultar por ID");
            System.out.println("4 - Buscar por nome");
            System.out.println("5 - Atualizar");
            System.out.println("6 - Excluir");
            System.out.println("0 - Voltar");
            op = ConsoleUtil.lerInt("Opção");
            try {
                switch (op) {
                    case 1: cadastrar(); break;
                    case 2: listar(); break;
                    case 3: consultarPorId(); break;
                    case 4: buscarPorNome(); break;
                    case 5: atualizar(); break;
                    case 6: excluir(); break;
                    case 0: break;
                    default: System.out.println("Opção inválida.");
                }
            } catch (RuntimeException e) {
                System.out.println("Erro na operação: " + ConsoleUtil.mensagemErro(e));
            }
        } while (op != 0);
    }

    private void cadastrar() {
        String nome = ConsoleUtil.lerTexto("Nome");
        String cpf = ConsoleUtil.lerCpf("CPF");
        if (cpfJaExiste(cpf)) {
            System.out.println("Já existe uma pessoa cadastrada com esse CPF.");
            return;
        }
        String email = ConsoleUtil.lerTextoOpcional("E-mail");
        String telefone = ConsoleUtil.lerTextoOpcional("Telefone");
        LocalDate nascimento = ConsoleUtil.lerDataPassada("Data de nascimento");

        System.out.println("Endereço:");
        String rua = ConsoleUtil.lerTexto("  Rua");
        String numero = ConsoleUtil.lerTexto("  Número");
        String bairro = ConsoleUtil.lerTexto("  Bairro");
        String cidade = ConsoleUtil.lerTexto("  Cidade");
        String uf = ConsoleUtil.lerTexto("  UF").toUpperCase();
        String cep = ConsoleUtil.lerTexto("  CEP");

        Endereco endereco = new Endereco(numero, bairro, cidade, cep, uf, rua);
        Paciente paciente = new Paciente(nome, email, cpf, telefone, nascimento,
                endereco, LocalDate.now());

        if (ConsoleUtil.confirmar("Abrir prontuário agora?")) {
            TipoSanguineo tipo = ConsoleUtil.lerEnum("Tipo sanguíneo", TipoSanguineo.class);
            String alergias = ConsoleUtil.lerTextoOpcional("Alergias");
            Prontuario prontuario = new Prontuario(LocalDate.now(), tipo, alergias, null, paciente);
            paciente.setProntuario(prontuario);
        }

        dao.salvar(paciente);
        System.out.println("Paciente cadastrado com ID " + paciente.getId());
    }

    private boolean cpfJaExiste(String cpf) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            Long qtd = em.createQuery("SELECT COUNT(p) FROM Pessoa p WHERE p.cpf = :cpf", Long.class)
                    .setParameter("cpf", cpf)
                    .getSingleResult();
            return qtd > 0;
        } finally {
            em.close();
        }
    }

    private void listar() {
        int pagina = 0;
        while (true) {
            EntityManager em = JPAUtil.getEntityManager();
            long total;
            List<Paciente> lista;
            try {
                total = em.createQuery("SELECT COUNT(p) FROM Paciente p", Long.class).getSingleResult();
                lista = em.createQuery("SELECT p FROM Paciente p ORDER BY p.id", Paciente.class)
                        .setFirstResult(pagina * TAM_PAGINA)
                        .setMaxResults(TAM_PAGINA)
                        .getResultList();
            } finally {
                em.close();
            }

            long totalPaginas = Math.max(1, (total + TAM_PAGINA - 1) / TAM_PAGINA);
            System.out.println("\nPacientes - página " + (pagina + 1) + " de " + totalPaginas
                    + " (total: " + total + ")");
            for (Paciente p : lista) {
                imprimirLinha(p);
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

    private void consultarPorId() {
        mostrarDetalhe(ConsoleUtil.lerLong("ID do paciente"));
    }

    private void mostrarDetalhe(Long id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            List<Paciente> r = em.createQuery(
                    "SELECT p FROM Paciente p LEFT JOIN FETCH p.prontuario WHERE p.id = :id",
                    Paciente.class).setParameter("id", id).getResultList();
            if (r.isEmpty()) {
                System.out.println("Paciente não encontrado.");
                return;
            }
            Paciente p = r.get(0);
            Long atendimentos = em.createQuery(
                    "SELECT COUNT(a) FROM Atendimento a WHERE a.paciente.id = :id", Long.class)
                    .setParameter("id", id).getSingleResult();

            System.out.println("\nID: " + p.getId());
            System.out.println("Nome: " + p.getNome());
            System.out.println("CPF: " + p.getCpf());
            System.out.println("E-mail: " + p.getEmail());
            System.out.println("Telefone: " + p.getTelefone());
            System.out.println("Nascimento: " + ConsoleUtil.formatar(p.getDataNascimento()));
            System.out.println("Cadastro: " + ConsoleUtil.formatar(p.getDataCadastro()));
            Endereco e = p.getEndereco();
            if (e != null) {
                System.out.println("Endereço: " + e.getRua() + ", " + e.getNumero() + " - "
                        + e.getBairro() + ", " + e.getCidade() + "/" + e.getUf() + " - CEP " + e.getCep());
            }

            System.out.println("Convênio: " + (p.getConvenio() == null ? "-" : p.getConvenio().getNome()));
            if (p.getProntuario() == null) {
                System.out.println("Prontuário: não possui");
            } else {
                System.out.println("Prontuário: aberto em "
                        + ConsoleUtil.formatar(p.getProntuario().getDataAbertura())
                        + " | tipo sanguíneo " + p.getProntuario().getTipoSanguineo()
                        + " | alergias: " + p.getProntuario().getAlergias());
            }
            System.out.println("Atendimentos: " + atendimentos);
        } finally {
            em.close();
        }
    }

    private void buscarPorNome() {
        String trecho = ConsoleUtil.lerTexto("Parte do nome");
        EntityManager em = JPAUtil.getEntityManager();
        try {
            List<Paciente> lista = em.createNamedQuery("Paciente.buscarPorNome", Paciente.class)
                    .setParameter("nome", "%" + trecho + "%")
                    .setMaxResults(30)
                    .getResultList();
            System.out.println(lista.size() + " resultado(s) (máx. 30):");
            for (Paciente p : lista) {
                imprimirLinha(p);
            }
        } finally {
            em.close();
        }
    }

    private void atualizar() {
        Paciente p = dao.buscarPorId(ConsoleUtil.lerLong("ID do paciente"));
        if (p == null) {
            System.out.println("Paciente não encontrado.");
            return;
        }
        imprimirLinha(p);
        System.out.println("Enter mantém o valor atual.");
        p.setNome(ConsoleUtil.lerTextoOuManter("Nome", p.getNome()));
        p.setEmail(ConsoleUtil.lerTextoOuManter("E-mail", p.getEmail()));
        p.setTelefone(ConsoleUtil.lerTextoOuManter("Telefone", p.getTelefone()));

        Endereco e = p.getEndereco() != null ? p.getEndereco() : new Endereco();
        e.setCidade(ConsoleUtil.lerTextoOuManter("Cidade", e.getCidade()));
        e.setBairro(ConsoleUtil.lerTextoOuManter("Bairro", e.getBairro()));
        p.setEndereco(e);

        dao.atualizar(p);
        System.out.println("Paciente atualizado.");
    }

    private void excluir() {
        Long id = ConsoleUtil.lerLong("ID do paciente");
        Paciente p = dao.buscarPorId(id);
        if (p == null) {
            System.out.println("Paciente não encontrado.");
            return;
        }
        imprimirLinha(p);
        if (!ConsoleUtil.confirmar("Confirmar exclusão? (o prontuário também será apagado)")) {
            return;
        }
        try {
            dao.remover(id);
            System.out.println("Paciente excluído.");
        } catch (RuntimeException e) {
            if (ConsoleUtil.violouIntegridade(e)) {
                System.out.println("Não foi possível excluir: o paciente possui atendimentos vinculados.");
            } else {
                throw e;
            }
        }
    }

    private void imprimirLinha(Paciente p) {
        String cidade = p.getEndereco() == null ? "-" : p.getEndereco().getCidade();
        System.out.printf("[%d] %s | CPF %s | Nasc. %s | %s%n",
                p.getId(), p.getNome(), p.getCpf(),
                ConsoleUtil.formatar(p.getDataNascimento()), cidade);
    }
}
