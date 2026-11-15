package br.edu.bd2.clinica.carga;

import br.edu.bd2.clinica.modelo.Atendimento;
import br.edu.bd2.clinica.modelo.CategoriaProcedimento;
import br.edu.bd2.clinica.modelo.Convenio;
import br.edu.bd2.clinica.modelo.Endereco;
import br.edu.bd2.clinica.modelo.Especialidade;
import br.edu.bd2.clinica.modelo.ItemAtendimento;
import br.edu.bd2.clinica.modelo.Medico;
import br.edu.bd2.clinica.modelo.Paciente;
import br.edu.bd2.clinica.modelo.Procedimento;
import br.edu.bd2.clinica.modelo.Prontuario;
import br.edu.bd2.clinica.modelo.StatusAtendimento;
import br.edu.bd2.clinica.modelo.TipoAtendimento;
import br.edu.bd2.clinica.modelo.TipoSanguineo;
import br.edu.bd2.clinica.modelo.Unidade;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.EntityTransaction;
import javax.persistence.Persistence;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

/**
 * Gera a massa de dados de teste da Entrega 1:
 * 200 pacientes, 100 procedimentos, 5 unidades e 2.000 atendimentos
 * distribuídos em pouco mais de 2 anos (nov/2024 a dez/2026).
 *
 * Tudo roda numa única transação: ou a carga entra inteira, ou nada entra.
 * A semente do Random é fixa, então a carga sai igual em qualquer máquina.
 */
public class GeradorDados {

    private static final long SEMENTE = 42L;
    private static final int TAMANHO_LOTE = 50;

    private static final int QTD_UNIDADES = 5;
    private static final int QTD_MEDICOS = 20;
    private static final int QTD_PACIENTES = 200;
    private static final int QTD_ATENDIMENTOS = 2000;

    /** Percentual de pacientes que têm convênio (o restante é particular). */
    private static final int PERCENTUAL_COM_CONVENIO = 80;

    private static final LocalDate INICIO_ATENDIMENTOS = LocalDate.of(2024, 11, 1);
    private static final LocalDate FIM_ATENDIMENTOS = LocalDate.of(2026, 12, 31);

    /**
     * Data fixa (e não LocalDate.now()) para a carga ser reproduzível:
     * atendimentos depois dela ficam AGENDADO, os anteriores REALIZADO/CANCELADO.
     */
    private static final LocalDateTime DATA_REFERENCIA = LocalDateTime.of(2026, 11, 13, 0, 0);

    // Nomes das categorias (usados como chave para sortear procedimentos por tipo de atendimento)
    private static final String CAT_CONSULTAS = "Consultas";
    private static final String CAT_LABORATORIAIS = "Exames laboratoriais";
    private static final String CAT_IMAGEM = "Exames de imagem";
    private static final String CAT_GRAFICOS = "Exames gráficos e endoscópicos";
    private static final String CAT_PEQUENOS = "Pequenos procedimentos";
    private static final String CAT_TERAPIAS = "Terapias";
    private static final String CAT_VACINAS = "Vacinas";

    private static final String[] ESPECIALIDADES = {
            "Clínica Geral", "Cardiologia", "Dermatologia", "Pediatria", "Ortopedia",
            "Ginecologia", "Neurologia", "Endocrinologia", "Oftalmologia", "Otorrinolaringologia"
    };

    private static final String[] NOMES = {
            "Ana", "Bruno", "Carla", "Daniel", "Eduarda", "Felipe", "Gabriela", "Henrique",
            "Isabela", "João", "Larissa", "Lucas", "Mariana", "Mateus", "Natália", "Otávio",
            "Patrícia", "Pedro", "Rafaela", "Rodrigo", "Sofia", "Thiago", "Vanessa", "Vinícius",
            "Beatriz", "Caio", "Fernanda", "Gustavo", "Juliana", "Marcelo", "Letícia", "Leonardo"
    };

    private static final String[] SOBRENOMES = {
            "Silva", "Santos", "Oliveira", "Souza", "Rodrigues", "Ferreira", "Alves", "Pereira",
            "Lima", "Gomes", "Costa", "Ribeiro", "Martins", "Carvalho", "Almeida", "Lopes",
            "Soares", "Fernandes", "Vieira", "Barbosa", "Rocha", "Dias", "Nascimento", "Moreira"
    };

    private static final String[] RUAS = {
            "Rua das Flores", "Avenida Brasil", "Rua São Paulo", "Rua XV de Novembro",
            "Avenida Goiás", "Rua Sete de Setembro", "Rua Tiradentes", "Avenida Independência",
            "Rua Santos Dumont", "Rua Rui Barbosa"
    };

    private static final String[] BAIRROS = {
            "Centro", "Jardim América", "Setor Bueno", "Vila Nova", "Setor Oeste",
            "Jardim Goiás", "Setor Marista", "Vila Redenção"
    };

    /** {cidade, UF, prefixo do CEP} */
    private static final String[][] CIDADES = {
            {"Goiânia", "GO", "74"}, {"Aparecida de Goiânia", "GO", "74"},
            {"Anápolis", "GO", "75"}, {"Brasília", "DF", "70"}, {"Rio Verde", "GO", "75"}
    };

    /** {nome do convênio, percentual de desconto} */
    private static final String[][] OPERADORAS = {
            {"Unimed", "20.00"}, {"Amil", "15.00"}, {"Bradesco Saúde", "25.00"},
            {"SulAmérica", "20.00"}, {"Hapvida", "10.00"}
    };

    private final Random random = new Random(SEMENTE);
    private final EntityManager em;
    private int contadorPersist = 0;
    private int contadorCpf = 0;

    public GeradorDados(EntityManager em) {
        this.em = em;
    }

    public static void main(String[] args) {
        // EMF próprio só para desligar o show_sql: com ele ligado, os ~8 mil INSERTs
        // inundam o console e deixam a carga bem mais lenta. O JPAUtil continua igual.
        Map<String, String> sobrescritas = new HashMap<>();
        sobrescritas.put("hibernate.show_sql", "false");
        sobrescritas.put("hibernate.format_sql", "false");
        EntityManagerFactory emf = Persistence.createEntityManagerFactory("clinicaPU", sobrescritas);
        EntityManager em = emf.createEntityManager();

        try {
            if (bancoJaTemDados(em)) {
                System.out.println("O banco já tem pessoas cadastradas. A carga NÃO foi executada,");
                System.out.println("porque rodar de novo duplicaria CPF/CRM/códigos (campos unique).");
                System.out.println("Para recarregar, apague e recrie o banco 'clinica' no pgAdmin.");
                return;
            }

            long inicio = System.currentTimeMillis();
            EntityTransaction tx = em.getTransaction();
            try {
                tx.begin();
                new GeradorDados(em).gerarTudo();
                tx.commit();
            } catch (RuntimeException e) {
                if (tx.isActive()) {
                    tx.rollback();
                }
                System.out.println("Erro na carga, nada foi gravado (rollback).");
                throw e;
            }

            System.out.printf("%nCarga concluída em %.1f s.%n", (System.currentTimeMillis() - inicio) / 1000.0);
            imprimirResumo(em);
        } finally {
            em.close();
            emf.close();
        }
    }

    public void gerarTudo() {
        Map<String, CategoriaProcedimento> categorias = gerarCategorias();
        List<Especialidade> especialidades = gerarEspecialidades();
        List<Unidade> unidades = gerarUnidades();
        List<Medico> medicos = gerarMedicos(especialidades);
        List<Paciente> pacientes = gerarPacientes();
        Map<String, List<Procedimento>> procedimentos = gerarProcedimentos(categorias);
        gerarAtendimentos(pacientes, medicos, unidades, procedimentos);
    }

    // ------------------------------------------------------------------ tabelas base

    private Map<String, CategoriaProcedimento> gerarCategorias() {
        String[] nomes = {CAT_CONSULTAS, CAT_LABORATORIAIS, CAT_IMAGEM, CAT_GRAFICOS,
                CAT_PEQUENOS, CAT_TERAPIAS, CAT_VACINAS};
        Map<String, CategoriaProcedimento> categorias = new LinkedHashMap<>();
        for (String nome : nomes) {
            CategoriaProcedimento c = new CategoriaProcedimento(nome);
            persistir(c);
            categorias.put(nome, c);
        }
        System.out.println("Categorias: " + categorias.size());
        return categorias;
    }

    private List<Especialidade> gerarEspecialidades() {
        List<Especialidade> lista = new ArrayList<>();
        for (String nome : ESPECIALIDADES) {
            Especialidade e = new Especialidade(nome);
            persistir(e);
            lista.add(e);
        }
        System.out.println("Especialidades: " + lista.size());
        return lista;
    }

    private List<Unidade> gerarUnidades() {
        List<Unidade> lista = new ArrayList<>();
        for (int i = 0; i < QTD_UNIDADES; i++) {
            String[] cidade = CIDADES[i % CIDADES.length];
            Unidade u = new Unidade("Clínica Vida - " + cidade[0], gerarTelefone(false), gerarEndereco(cidade));
            persistir(u);
            lista.add(u);
        }
        System.out.println("Unidades: " + lista.size());
        return lista;
    }

    // ------------------------------------------------------------------ pessoas

    private List<Medico> gerarMedicos(List<Especialidade> especialidades) {
        List<Medico> lista = new ArrayList<>();
        for (int i = 0; i < QTD_MEDICOS; i++) {
            String nome = "Dr(a). " + gerarNomeCompleto();
            LocalDate nascimento = dataAleatoria(LocalDate.of(1960, 1, 1), LocalDate.of(1995, 12, 31));
            String[] cidade = CIDADES[random.nextInt(CIDADES.length)];
            String crm = "CRM-" + cidade[1] + " " + (10000 + i);

            Medico m = new Medico(nome, gerarEmail(nome), gerarCpf(), gerarTelefone(true),
                    nascimento, gerarEndereco(cidade), crm);

            // Garante que toda especialidade tenha pelo menos um médico (i % 10)
            // e dá uma segunda especialidade para cerca de 1/3 deles.
            m.getEspecialidades().add(especialidades.get(i % especialidades.size()));
            if (random.nextInt(3) == 0) {
                Especialidade extra = sortear(especialidades);
                if (!m.getEspecialidades().contains(extra)) {
                    m.getEspecialidades().add(extra);
                }
            }
            persistir(m);
            lista.add(m);
        }
        System.out.println("Médicos: " + lista.size());
        return lista;
    }

    private List<Paciente> gerarPacientes() {
        List<Paciente> lista = new ArrayList<>();
        TipoSanguineo[] tipos = TipoSanguineo.values();
        int comConvenio = 0;

        for (int i = 0; i < QTD_PACIENTES; i++) {
            String nome = gerarNomeCompleto();
            LocalDate nascimento = dataAleatoria(LocalDate.of(1940, 1, 1), LocalDate.of(2022, 12, 31));
            // Cadastro sempre antes do primeiro atendimento possível
            LocalDate cadastro = dataAleatoria(LocalDate.of(2023, 1, 1), INICIO_ATENDIMENTOS.minusDays(1));
            String[] cidade = CIDADES[random.nextInt(CIDADES.length)];

            Paciente p = new Paciente(nome, gerarEmail(nome), gerarCpf(), gerarTelefone(true),
                    nascimento, gerarEndereco(cidade), cadastro);

            // Opção (a): como Paciente-Convenio é @OneToOne com convenio_id unique,
            // cada paciente com plano recebe a SUA linha de convênio.
            // O nome da operadora se repete entre linhas (nome não é unique).
            if (random.nextInt(100) < PERCENTUAL_COM_CONVENIO) {
                String[] op = OPERADORAS[random.nextInt(OPERADORAS.length)];
                Convenio c = new Convenio(op[0], new BigDecimal(op[1]));
                persistir(c);
                p.setConvenio(c);
                c.setPaciente(p);
                comConvenio++;
            }

            // Prontuário: os dois lados da relação são preenchidos;
            // o cascade ALL de Paciente.prontuario faz o INSERT junto.
            Prontuario pr = new Prontuario(cadastro, tipos[random.nextInt(tipos.length)],
                    gerarAlergias(), null, p);
            p.setProntuario(pr);

            persistir(p);
            lista.add(p);
        }
        System.out.println("Pacientes: " + lista.size() + " (" + comConvenio + " com convênio)");
        return lista;
    }

    // ------------------------------------------------------------------ catálogo

    private Map<String, List<Procedimento>> gerarProcedimentos(Map<String, CategoriaProcedimento> categorias) {
        Map<String, String[]> nomesPorCategoria = new LinkedHashMap<>();

        String[] consultas = new String[ESPECIALIDADES.length];
        for (int i = 0; i < ESPECIALIDADES.length; i++) {
            consultas[i] = "Consulta em " + ESPECIALIDADES[i];
        }
        nomesPorCategoria.put(CAT_CONSULTAS, consultas);

        nomesPorCategoria.put(CAT_LABORATORIAIS, new String[]{
                "Hemograma completo", "Glicemia de jejum", "Hemoglobina glicada", "Colesterol total e frações",
                "Triglicerídeos", "Ureia", "Creatinina", "TGO", "TGP", "TSH", "T4 livre", "PSA total",
                "Vitamina D", "Vitamina B12", "Ferritina", "Ácido úrico", "Urina tipo 1", "Urocultura",
                "Parasitológico de fezes", "Beta-HCG", "Proteína C reativa", "VHS", "Coagulograma",
                "Sódio e potássio"});

        String[] exames = {"Raio-X", "Ultrassonografia", "Tomografia", "Ressonância magnética"};
        String[] regioes = {"de crânio", "de tórax", "de abdome", "de coluna lombar", "de joelho", "de ombro"};
        List<String> imagem = new ArrayList<>();
        for (String exame : exames) {
            for (String regiao : regioes) {
                imagem.add(exame + " " + regiao);
            }
        }
        nomesPorCategoria.put(CAT_IMAGEM, imagem.toArray(new String[0]));

        nomesPorCategoria.put(CAT_GRAFICOS, new String[]{
                "Eletrocardiograma", "Ecocardiograma", "Teste ergométrico", "Holter 24h", "MAPA 24h",
                "Eletroencefalograma", "Espirometria", "Audiometria", "Endoscopia digestiva alta",
                "Colonoscopia"});

        nomesPorCategoria.put(CAT_PEQUENOS, new String[]{
                "Sutura simples", "Retirada de pontos", "Drenagem de abscesso", "Exérese de lesão de pele",
                "Cauterização", "Curativo simples", "Curativo complexo", "Infiltração articular",
                "Retirada de corpo estranho", "Lavagem otológica", "Imobilização gessada",
                "Retirada de unha encravada", "Biópsia de pele", "Aplicação de medicação intramuscular",
                "Aplicação de medicação endovenosa", "Nebulização"});

        nomesPorCategoria.put(CAT_TERAPIAS, new String[]{
                "Sessão de fisioterapia motora", "Sessão de fisioterapia respiratória", "Sessão de acupuntura",
                "Sessão de psicoterapia", "Sessão de fonoaudiologia", "Consulta nutricional",
                "Sessão de terapia ocupacional", "Sessão de RPG"});

        nomesPorCategoria.put(CAT_VACINAS, new String[]{
                "Vacina contra gripe", "Vacina contra hepatite B", "Vacina contra febre amarela",
                "Vacina tríplice viral", "Vacina dTpa", "Vacina HPV", "Vacina pneumocócica 23",
                "Vacina meningocócica ACWY"});

        // {valor mínimo, valor máximo} por categoria
        Map<String, int[]> faixaValor = new HashMap<>();
        faixaValor.put(CAT_CONSULTAS, new int[]{150, 400});
        faixaValor.put(CAT_LABORATORIAIS, new int[]{15, 120});
        faixaValor.put(CAT_IMAGEM, new int[]{80, 1200});
        faixaValor.put(CAT_GRAFICOS, new int[]{60, 900});
        faixaValor.put(CAT_PEQUENOS, new int[]{40, 450});
        faixaValor.put(CAT_TERAPIAS, new int[]{80, 200});
        faixaValor.put(CAT_VACINAS, new int[]{50, 350});

        Map<String, List<Procedimento>> resultado = new LinkedHashMap<>();
        int sequencia = 1;
        for (Map.Entry<String, String[]> entrada : nomesPorCategoria.entrySet()) {
            String categoria = entrada.getKey();
            int[] faixa = faixaValor.get(categoria);
            List<Procedimento> daCategoria = new ArrayList<>();
            for (String nome : entrada.getValue()) {
                String codigo = String.format("PROC-%03d", sequencia++);
                BigDecimal valor = valorAleatorio(faixa[0], faixa[1]);
                Procedimento p = new Procedimento(codigo, nome, valor, categorias.get(categoria));
                persistir(p);
                daCategoria.add(p);
            }
            resultado.put(categoria, daCategoria);
        }

        int total = sequencia - 1;
        if (total != 100) {
            throw new IllegalStateException("Esperava 100 procedimentos, gerou " + total);
        }
        System.out.println("Procedimentos: " + total);
        return resultado;
    }

    // ------------------------------------------------------------------ movimento

    private void gerarAtendimentos(List<Paciente> pacientes, List<Medico> medicos,
                                   List<Unidade> unidades, Map<String, List<Procedimento>> procedimentos) {
        // "Consulta em X" indexada pela especialidade, para o médico cobrar a consulta da área dele
        Map<String, Procedimento> consultaPorEspecialidade = new HashMap<>();
        for (Procedimento p : procedimentos.get(CAT_CONSULTAS)) {
            consultaPorEspecialidade.put(p.getNome().substring("Consulta em ".length()), p);
        }

        int[] porStatus = new int[StatusAtendimento.values().length];
        int totalItens = 0;

        for (int i = 0; i < QTD_ATENDIMENTOS; i++) {
            TipoAtendimento tipo = sortearTipo();
            Paciente paciente = sortear(pacientes);
            Medico medico = sortear(medicos);
            Unidade unidade = sortear(unidades);
            LocalDateTime dataHora = dataHoraAtendimento(tipo);
            StatusAtendimento status = definirStatus(dataHora);
            porStatus[status.ordinal()]++;

            Atendimento a = new Atendimento(dataHora, tipo, status, paciente, medico, unidade);

            // Atendimento cancelado não gera cobrança, então fica sem itens.
            if (status != StatusAtendimento.CANCELADO) {
                for (Procedimento proc : escolherProcedimentos(tipo, medico, consultaPorEspecialidade, procedimentos)) {
                    int quantidade = proc.getCategoria().getNome().equals(CAT_TERAPIAS) ? 1 + random.nextInt(3) : 1;
                    BigDecimal desconto = calcularDesconto(proc.getValorBase(), quantidade, paciente.getConvenio());
                    ItemAtendimento item = new ItemAtendimento(quantidade, proc.getValorBase(), desconto, proc, a);
                    a.getListaItens().add(item); // lado inverso; o cascade ALL persiste o item
                    totalItens++;
                }
            }
            persistir(a);
        }
        System.out.printf("Atendimentos: %d (REALIZADO=%d, CANCELADO=%d, AGENDADO=%d), itens: %d%n",
                QTD_ATENDIMENTOS,
                porStatus[StatusAtendimento.REALIZADO.ordinal()],
                porStatus[StatusAtendimento.CANCELADO.ordinal()],
                porStatus[StatusAtendimento.AGENDADO.ordinal()],
                totalItens);
    }

    private List<Procedimento> escolherProcedimentos(TipoAtendimento tipo, Medico medico,
                                                     Map<String, Procedimento> consultaPorEspecialidade,
                                                     Map<String, List<Procedimento>> proc) {
        List<Procedimento> escolhidos = new ArrayList<>();
        switch (tipo) {
            case CONSULTA:
            case RETORNO:
                // A consulta da especialidade do médico + às vezes exames pedidos na hora
                String especialidade = medico.getEspecialidades().get(0).getNome();
                escolhidos.add(consultaPorEspecialidade.get(especialidade));
                int extras = random.nextInt(10) < 3 ? 1 + random.nextInt(2) : 0;
                for (int i = 0; i < extras; i++) {
                    adicionarSemRepetir(escolhidos, sortear(juntar(proc, CAT_LABORATORIAIS, CAT_VACINAS, CAT_TERAPIAS)));
                }
                break;
            case EXAME:
                int qtdExames = 1 + random.nextInt(3);
                for (int i = 0; i < qtdExames; i++) {
                    adicionarSemRepetir(escolhidos, sortear(juntar(proc, CAT_LABORATORIAIS, CAT_IMAGEM, CAT_GRAFICOS)));
                }
                break;
            case EMERGENCIA:
            default:
                adicionarSemRepetir(escolhidos, sortear(proc.get(CAT_PEQUENOS)));
                int qtdExtras = random.nextInt(3);
                for (int i = 0; i < qtdExtras; i++) {
                    adicionarSemRepetir(escolhidos, sortear(juntar(proc, CAT_LABORATORIAIS, CAT_IMAGEM, CAT_PEQUENOS)));
                }
                break;
        }
        return escolhidos;
    }

    private TipoAtendimento sortearTipo() {
        int r = random.nextInt(100);
        if (r < 50) return TipoAtendimento.CONSULTA;   // 50%
        if (r < 70) return TipoAtendimento.RETORNO;    // 20%
        if (r < 90) return TipoAtendimento.EXAME;      // 20%
        return TipoAtendimento.EMERGENCIA;             // 10%
    }

    private LocalDateTime dataHoraAtendimento(TipoAtendimento tipo) {
        LocalDate dia = dataAleatoria(INICIO_ATENDIMENTOS, FIM_ATENDIMENTOS);
        if (tipo == TipoAtendimento.EMERGENCIA) {
            // Emergência acontece a qualquer hora
            return dia.atTime(random.nextInt(24), random.nextInt(60));
        }
        // Horário comercial (07h às 17h45), em intervalos de 15 minutos
        return dia.atTime(7 + random.nextInt(11), 15 * random.nextInt(4));
    }

    private StatusAtendimento definirStatus(LocalDateTime dataHora) {
        if (dataHora.isAfter(DATA_REFERENCIA)) {
            return StatusAtendimento.AGENDADO;
        }
        return random.nextInt(100) < 8 ? StatusAtendimento.CANCELADO : StatusAtendimento.REALIZADO;
    }

    private BigDecimal calcularDesconto(BigDecimal valorUnitario, int quantidade, Convenio convenio) {
        if (convenio == null) {
            return BigDecimal.ZERO.setScale(2);
        }
        return valorUnitario
                .multiply(BigDecimal.valueOf(quantidade))
                .multiply(convenio.getPercentualDesconto())
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }

    // ------------------------------------------------------------------ persistência

    /**
     * persist + flush/clear a cada lote. O clear evita que o contexto de persistência
     * acumule milhares de objetos na memória. As entidades já gravadas continuam
     * válidas como referência de FK mesmo depois de "destacadas" (detached).
     */
    private void persistir(Object entidade) {
        em.persist(entidade);
        if (++contadorPersist % TAMANHO_LOTE == 0) {
            em.flush();
            em.clear();
        }
    }

    private static boolean bancoJaTemDados(EntityManager em) {
        Long total = em.createQuery("SELECT COUNT(p) FROM Pessoa p", Long.class).getSingleResult();
        return total > 0;
    }

    private static void imprimirResumo(EntityManager em) {
        String[] entidades = {"Unidade", "Especialidade", "Medico", "Paciente", "Prontuario", "Convenio",
                "CategoriaProcedimento", "Procedimento", "Atendimento", "ItemAtendimento"};
        System.out.println("\nRegistros no banco:");
        for (String entidade : entidades) {
            Long qtd = em.createQuery("SELECT COUNT(e) FROM " + entidade + " e", Long.class).getSingleResult();
            System.out.printf("  %-22s %5d%n", entidade, qtd);
        }
        Object[] periodo = em.createQuery(
                "SELECT MIN(a.dataHora), MAX(a.dataHora) FROM Atendimento a", Object[].class).getSingleResult();
        System.out.println("  Período dos atendimentos: " + periodo[0] + " até " + periodo[1]);
    }

    // ------------------------------------------------------------------ utilitários de geração

    private <T> T sortear(List<T> lista) {
        return lista.get(random.nextInt(lista.size()));
    }

    private static List<Procedimento> juntar(Map<String, List<Procedimento>> proc, String... categorias) {
        List<Procedimento> todos = new ArrayList<>();
        for (String c : categorias) {
            todos.addAll(proc.get(c));
        }
        return todos;
    }

    private static void adicionarSemRepetir(List<Procedimento> lista, Procedimento p) {
        if (!lista.contains(p)) {
            lista.add(p);
        }
    }

    private LocalDate dataAleatoria(LocalDate inicio, LocalDate fim) {
        long dias = ChronoUnit.DAYS.between(inicio, fim);
        return inicio.plusDays((long) (random.nextDouble() * (dias + 1)));
    }

    private BigDecimal valorAleatorio(int minimo, int maximo) {
        // Arredonda para múltiplos de R$ 5, como tabela de preço de verdade
        int valor = minimo + random.nextInt(maximo - minimo + 1);
        valor = Math.round(valor / 5.0f) * 5;
        return new BigDecimal(valor).setScale(2);
    }

    private String gerarNomeCompleto() {
        return NOMES[random.nextInt(NOMES.length)] + " "
                + SOBRENOMES[random.nextInt(SOBRENOMES.length)] + " "
                + SOBRENOMES[random.nextInt(SOBRENOMES.length)];
    }

    private String gerarEmail(String nome) {
        String base = java.text.Normalizer.normalize(nome.replace("Dr(a). ", ""), java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase()
                .replace(' ', '.');
        return base + (contadorCpf + 1) + "@email.com";
    }

    /** CPF válido (com dígitos verificadores) e único, gerado a partir de um contador. */
    private String gerarCpf() {
        contadorCpf++;
        int[] d = new int[11];
        String base = String.format("%09d", 100000000 + contadorCpf * 7919);
        for (int i = 0; i < 9; i++) {
            d[i] = base.charAt(i) - '0';
        }
        d[9] = digitoVerificador(d, 9);
        d[10] = digitoVerificador(d, 10);
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 11; i++) {
            sb.append(d[i]);
            if (i == 2 || i == 5) sb.append('.');
            if (i == 8) sb.append('-');
        }
        return sb.toString();
    }

    private static int digitoVerificador(int[] d, int tamanho) {
        int soma = 0;
        for (int i = 0; i < tamanho; i++) {
            soma += d[i] * (tamanho + 1 - i);
        }
        int resto = soma % 11;
        return resto < 2 ? 0 : 11 - resto;
    }

    private String gerarTelefone(boolean celular) {
        String ddd = random.nextBoolean() ? "62" : "61";
        if (celular) {
            return String.format("(%s) 9%04d-%04d", ddd, random.nextInt(10000), random.nextInt(10000));
        }
        return String.format("(%s) 3%03d-%04d", ddd, random.nextInt(1000), random.nextInt(10000));
    }

    private Endereco gerarEndereco(String[] cidade) {
        String cep = String.format("%s%03d-%03d", cidade[2], random.nextInt(1000), random.nextInt(1000));
        return new Endereco(String.valueOf(1 + random.nextInt(2000)), BAIRROS[random.nextInt(BAIRROS.length)],
                cidade[0], cep, cidade[1], RUAS[random.nextInt(RUAS.length)]);
    }

    private String gerarAlergias() {
        List<String> opcoes = Arrays.asList("Dipirona", "Penicilina", "Lactose", "Frutos do mar",
                "Amendoim", "Ácaros", "Látex", "AAS");
        int r = random.nextInt(100);
        if (r < 65) {
            return "Nenhuma conhecida";
        }
        String primeira = sortear(opcoes);
        if (r < 90) {
            return primeira;
        }
        String segunda = sortear(opcoes);
        return primeira.equals(segunda) ? primeira : primeira + ", " + segunda;
    }
}
