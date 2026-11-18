# Sistema de Clínica Médica - BD2

Trabalho da 2ª unidade de Banco de Dados II. Equipe 6 - tema: clínica médica (atendimentos e procedimentos).

> **Uso de IA:** Usamos o Claude como apoio na resolução de erros de configuração, na escrita deste README e na organização das tarefas das entregas. Tudo foi testado e revisado pela equipe.

O trabalho tem duas etapas. Na primeira, fizemos o sistema OLTP em Java com JPA 2.1 + Hibernate 5.2.10 e PostgreSQL. Na segunda, os dados desse sistema vão para um Data Warehouse por meio de um processo de ETL, e depois são analisados com consultas OLAP e mineração de dados.

**Situação atual:** Entrega 1 concluída. Estamos na Entrega 2 (Data Warehouse e ETL), que vai até **21/11**.

## Equipe

| Integrante | Papel |
|---|---|
| 1 - Matheus | Líder / Gerente do projeto |
| 2 - Edson | Arquiteto de dados |
| 3 - Danton | Desenvolvedor ORM |
| 4 - André | Engenheiro de ETL |
| 5 - Jade | Analista de BI e mineração |

## O que precisa ter instalado

- **JDK 8** (o Hibernate 5.2 precisa do Java 8)
  https://adoptium.net/temurin/releases/?version=8
  Escolher Windows, x64, JDK, versão 8 e baixar o .msi. Na instalação marcar "Set JAVA_HOME" e "Add to PATH".

- **Eclipse Neon** (Eclipse IDE for Java EE Developers), que é o que o professor pediu
  https://www.eclipse.org/downloads/packages/file/49873
  Não tem instalador, é só descompactar e abrir o eclipse.exe.
  Obs: dá pra usar um Eclipse mais novo também, desde que o projeto esteja usando o JDK 8.

- **PostgreSQL**
  https://www.postgresql.org/download/windows/
  Qualquer versão a partir da 12 serve. Eu testei com a 15.

- **Git**
  https://git-scm.com/downloads

## Configurando na sua máquina

1. Criar o banco no pgAdmin com o nome `clinica` (botão direito em Databases > Create > Database).

2. Clonar o repositório:
   ```
   git clone https://github.com/bd2-equipe6/clinica-medica.git
   ```

3. No Eclipse: File > Import > Maven > Existing Maven Projects, e escolher a pasta `clinica-medica`.

4. Esperar ele baixar as dependências. Depois clicar com o botão direito no projeto > Maven > Update Project.

5. Se a senha do seu postgres não for `postgres`, ou se o seu PostgreSQL não estiver na porta 5432, muda no arquivo `src/main/resources/META-INF/persistence.xml`. **Essa alteração é só na sua máquina, não faz commit dela.**

6. Rodar o `TesteConexao` (pacote `br.edu.bd2.clinica.util`): botão direito > Run As > Java Application.
   Se no Console aparecer `Conexão OK!` e a versão do PostgreSQL, tá tudo certo.

## Problemas que já aconteceram

- **Aparece "Failed while installing JPA 2.1" quando importa o projeto**
  É o Eclipse tentando configurar o JPA sozinho, não é problema do projeto. Pode clicar em OK. Pra não aparecer mais: Window > Preferences > Maven > Java EE Integration e desmarcar "Enable JPA Configuration".

- **Erro "O tipo de autenticação 10 não é suportado"**
  O driver do PostgreSQL estava antigo (42.1.4, que tava no exemplo do professor). Já trocamos pra 42.7.4 no pom.xml. Se aparecer, confere a versão e roda Maven > Update Project.

- **"password authentication failed"**
  Senha errada no persistence.xml.

- **"database clinica does not exist"**
  Falta criar o banco.

- **Tem dois PostgreSQL instalados**
  Cada um fica numa porta. Vê no pgAdmin (botão direito no servidor > Properties > Connection) qual tá na 5432 e cria o banco nele.

- **Acentos aparecendo errado no Console**
  Window > Preferences > General > Workspace > Text file encoding > UTF-8.

## Organização das pastas

```
clinica-medica/
├── pom.xml
├── docs/
│   ├── Diagramas/          UML, modelo relacional, estrela e floco de neve
│   ├── analise_dw.md       o que queremos analisar no DW
│   └── acompanhamento.md   prazos, commits e PRs de cada um
├── sql/                    (ver sql/README.md)
│   ├── dw/                 DDL do modelo estrela e do floco de neve
│   ├── etl/                staging, cargas, carga incremental e SCD 2
│   ├── validacao/          conferência da carga e teste do fluxo completo
│   └── olap/               consultas OLAP (Entrega 3)
└── src/main/
    ├── resources/META-INF/persistence.xml
    └── java/br/edu/bd2/clinica/
        ├── modelo/     entidades
        ├── dao/        GenericDAO e DAOs
        ├── consulta/   consultas JPQL e Criteria
        ├── carga/      gerador de dados
        ├── ui/         interface do CRUD
        └── util/       JPAUtil e TesteConexao
```

Pra pegar o EntityManager é só usar `JPAUtil.getEntityManager()`.

## Entrega 1 - concluída

Sistema OLTP funcionando: projeto Maven, entidades JPA, GenericDAO, 10 consultas JPQL, 3 Criteria, gerador de dados e interface com CRUD.

## Entrega 2 - Data Warehouse e ETL (até 21/11)

### Prazos internos

O ETL depende do DDL, e a validação depende do ETL. Se alguém atrasar, avisa no grupo na hora, pra gente reorganizar.

| Quando | Quem | O quê |
|---|---|---|
| Qua 18/11 | Edson | Modelo estrela, floco de neve, diagramas e DDLs ✅ |
| Qua 18/11 | Matheus | Organizar a pasta sql/, prazos e README ✅ |
| Qui 19/11, até 12h | Edson | Acrescentar `item_atendimento_id` na tabela fato |
| Qui 19/11, até 18h | Danton | Conferir os dados do OLTP e passar pro André os nomes das tabelas e colunas |
| Qui 19/11, até 23h | André | Staging, dimensão Tempo e cargas das dimensões |
| Sex 20/11, até 18h | André | Carga da fato, carga incremental, SCD tipo 2 e contagens de linhas |
| Sex 20/11, até 22h | Jade | Validação da carga (OLTP x DW) |
| Sex 20/11, até 23h | Matheus | Teste do fluxo completo, revisão e merge dos PRs |
| Sáb 21/11, manhã | Todos | Correções finais e entrega |

### Quem faz o quê

**1. Líder / Gerente do projeto - Matheus**
- Organizar a pasta sql/ do repositório para os scripts do DW e do ETL. ✅
- Definir os prazos internos da entrega. ✅
- Acompanhar os commits de todos (em `docs/acompanhamento.md`).
- Revisar e integrar os Pull Requests.
- Testar o fluxo completo: inserir um atendimento pela aplicação, rodar o ETL e conferir se o dado chegou no DW (`TesteFluxoCompleto` + `sql/validacao/teste_fluxo_completo.sql`).

**2. Arquiteto de dados - Edson**
- Definir a granularidade da tabela fato: um procedimento realizado em um atendimento (`ItemAtendimento`). ✅
- Projetar o modelo estrela, com 1 tabela fato com pelo menos 3 medidas e pelo menos 4 dimensões. ✅
- Garantir a dimensão Tempo, com dia, mês, trimestre, semestre, ano e dia da semana. ✅
- Projetar o modelo floco de neve, normalizando pelo menos 2 dimensões. ✅
- Criar os diagramas dos dois modelos (`docs/Diagramas/`). ✅
- Criar o script DDL de cada modelo, em esquema separado do OLTP (`sql/dw/`). ✅
- **Ajuste:** acrescentar a coluna `item_atendimento_id` na fato dos dois modelos. Cada atendimento pode ter vários procedimentos, então é o id do item que identifica cada linha da fato, e a carga incremental precisa dele pra saber o que já foi carregado.

**3. Desenvolvedor ORM - Danton**
- Conferir se os dados do banco OLTP estão completos e consistentes.
- Passar pro André as tabelas e colunas geradas pelo Hibernate.
- Garantir que a aplicação consegue alterar a cidade de um paciente, para testar o SCD tipo 2.
- Adiantar a parte teórica de ORM do relatório (questões de fixação 1 a 6).

**4. Engenheiro de ETL - André**
- Criar a área de staging (esquema `staging`).
- Implementar o ETL em SQL (procedures) ou em Java (`sql/etl/`).
- Gerar a dimensão Tempo.
- Criar as chaves substitutas (surrogate keys) das dimensões.
- Tratar valores nulos e padronizar os textos.
- Calcular as medidas derivadas (valor bruto = quantidade x valor unitário; valor líquido = valor bruto - desconto).
- Implementar a carga incremental (carregar só os itens novos).
- Implementar o SCD tipo 2 em uma dimensão (mudança de cidade do paciente).
- Registrar as contagens de linhas antes e depois da carga.

**5. Analista de BI e mineração - Jade**
- Validar a carga do DW, comparando os totais do OLTP com os do DW (`sql/validacao/`).
- Conferir se o SCD tipo 2 e a carga incremental funcionaram.
- Adiantar as consultas OLAP da Entrega 3 (2 de cada: roll-up, drill-down, slice, dice e pivot).
- Escolher a técnica de mineração (Apriori, k-means ou árvore de decisão).

### Checklist da Entrega 2

- [x] Granularidade da tabela fato definida
- [x] Diagrama do modelo estrela
- [x] Diagrama do modelo floco de neve
- [x] DDL do modelo estrela (esquema separado do OLTP)
- [x] DDL do modelo floco de neve
- [ ] `item_atendimento_id` na tabela fato
- [ ] Área de staging
- [ ] Dimensão Tempo gerada
- [ ] Chaves substitutas nas dimensões
- [ ] Tratamento de nulos e padronização de textos
- [ ] Medidas derivadas
- [ ] Carga incremental
- [ ] SCD tipo 2 em uma dimensão
- [ ] Contagens de linhas antes e depois da carga
- [ ] Validação OLTP x DW
- [ ] Teste do fluxo completo

## Datas do professor

- 1ª entrega do relatório técnico: 16/11 (concluída)
- 2ª entrega do relatório técnico: **21/11**
- 3ª entrega do relatório técnico: 28/11
- Avaliação da IIª Unidade: 04/12
- 2ª chamada: 09/12
- Prova final: 14/12

## Como usar o Git

O professor olha o histórico de commits pra ver a participação de cada um, então **cada um faz commit do próprio trabalho com a própria conta**.

```
git checkout main
git pull origin main
git checkout -b integrante4-etl
(faz as alterações)
git add .
git commit -m "Cria procedure de carga da dimensão Tempo"
git push origin integrante4-etl
```

Depois abre um Pull Request no GitHub pra main. Eu reviso e faço o merge.

Antes de começar a mexer, sempre dá um `git pull` pra pegar o que os outros já subiram. Commits pequenos, um por etapa, com mensagem dizendo o que foi feito.
