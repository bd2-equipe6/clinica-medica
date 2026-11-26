# Sistema de Clínica Médica - BD2

Trabalho da 2ª unidade de Banco de Dados II. Equipe 6 - tema: clínica médica (atendimentos e procedimentos).

> **Uso de IA:** Usamos o Claude como apoio na resolução de erros de configuração, na escrita deste README e na organização das tarefas das entregas. Tudo foi testado e revisado pela equipe.

O trabalho tem duas etapas. Na primeira, fizemos o sistema OLTP em Java com JPA 2.1 + Hibernate 5.2.10 e PostgreSQL. Na segunda, os dados desse sistema vão para um Data Warehouse por meio de um processo de ETL, e depois são analisados com consultas OLAP e mineração de dados.

**Situação atual:** Entregas 1 e 2 concluídas. Estamos na Entrega 3 (relatório técnico final), que vai até **28/11**.

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
│   ├── mineracao.md        técnica de mineração (Apriori) e como aplicar
│   └── acompanhamento.md   prazos, commits e PRs de cada um
├── sql/                    (ver sql/README.md)
│   ├── oltp/               DDL do banco do sistema (OLTP)
│   ├── dw/                 DDL do modelo estrela e do floco de neve
│   ├── etl/                staging, cargas, carga incremental e SCD 2
│   ├── validacao/          conferência da carga e teste do fluxo completo
│   └── olap/               consultas OLAP
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

## Entrega 2 - concluída

Data Warehouse carregado: modelos estrela e floco de neve, diagramas, DDLs, ETL com staging, dimensão Tempo, chaves substitutas, carga incremental, SCD tipo 2 no paciente, contagens antes e depois e scripts de validação.

## Entrega 3 - Relatório técnico (até 28/11)

Relatório em PDF, nas normas ABNT, com 12 a 20 páginas, no mínimo 6 referências (pelo menos 2 livros ou artigos) e as 13 questões de fixação respondidas. Cada conceito precisa de um exemplo tirado do nosso sistema.

### Prazos internos

| Quando | O quê |
|---|---|
| Qua 25/11 | Consultas OLAP prontas |
| Qui 26/11, até 22h | Cada integrante manda sua parte do relatório e suas questões para o líder |
| Sex 27/11 | O líder junta e revisa, e todos leem o relatório inteiro |
| Sáb 28/11 | Entrega do PDF |

### Quem faz o quê

**1. Líder / Gerente do projeto**
- Juntar todas as partes num relatório só, nas normas ABNT.
- Escrever a introdução, a conclusão e a seção de divisão de tarefas.
- Montar as referências.
- Escrever a declaração de uso de IA, indicando em quais partes foi usada.
- Revisar o relatório inteiro e gerar o PDF final.
- Montar os slides e o roteiro da demonstração ao vivo (inserção pela aplicação chegando ao DW depois do ETL).
- Preparar a ata de participação para os 5 assinarem.
- Entregar no AVA.

Dependência: precisa das partes dos integrantes 2, 3, 4 e 5.

**2. Arquiteto de dados**
- Relatório 2a: conceito de DW e Data Mart, Inmon e Kimball.
- Relatório 2b: fato, dimensão, medida, granularidade, chave substituta e SCD tipos 1 e 2.
- Relatório 2c: estrela x floco de neve (estrutura, vantagens, desvantagens e quando usar).
- Questões 7, 8, 9 e 10.
- Colocar no relatório os diagramas UML, relacional, estrela e floco de neve.

**3. Desenvolvedor ORM**
- Relatório 1a a 1d: ORM e impedância, OQL, JPA 2.1 e Hibernate.
- Justificar os fetch e cascade usados nas nossas entidades.
- Questões 1 a 6.
- DDL do OLTP em `sql/oltp/`.

**4. Engenheiro de ETL**
- Relatório 2d: ETL, staging, carga inicial x incremental, mostrando o nosso ETL com as contagens antes e depois e o SCD 2.
- Relatório 2e: OLAP x OLTP, ROLAP, MOLAP e HOLAP.
- Questão 11 (quadro OLTP x OLAP com pelo menos 8 critérios).
- Medir o tempo da mesma consulta no OLTP, no modelo estrela e no floco de neve.

Dependência: precisa de uma consulta OLAP do integrante 5 para a medição de tempo.

**5. Analista de BI e mineração**
- Consultas OLAP: 2 de cada operação (roll-up, drill-down, slice, dice e pivot), em `sql/olap/`.
- Mineração com Apriori: preparação dos dados, parâmetros, resultado e pelo menos 3 conclusões de negócio, com os arquivos no repositório.
- Relatório 2f: KDD, tarefas e algoritmos.
- Questões 12 e 13.

### Situação em 26/11

| Parte | Integrante | Situação |
|---|---|---|
| Relatório 1a a 1d, fetch e cascade, questões 1 a 6 | 3 | Entregue |
| DDL do OLTP | 3 | Entregue (`sql/oltp/DDL_OLTP.sql`) |
| Relatório 2a a 2c, questões 7 a 10 | 2 | Pendente |
| Relatório 2d e 2e, questão 11, comparação de tempo | 4 | Pendente |
| Consultas OLAP (10 consultas) | 5 | Entregue (`sql/olap/consultas_olap.sql`) |
| Mineração: técnica escolhida (Apriori) | 5 | Entregue (`docs/mineracao.md`) |
| Mineração: resultado, regras e conclusões | 5 | Pendente |
| Relatório 2f, questões 12 e 13 | 5 | Pendente |
| Introdução, conclusão, uso de IA, referências e revisão | 1 | Depois das outras partes |
| Slides e ata de participação | 1 | Pendente |

### Checklist da Entrega 3

- [x] DDL do OLTP
- [x] Consultas OLAP (2 de cada operação)
- [ ] Comparação de tempo: OLTP x estrela x floco de neve
- [ ] Resultado da mineração com pelo menos 3 conclusões
- [x] Relatório: ORM, JPA e Hibernate (1a a 1d)
- [ ] Relatório: Data Warehousing (2a a 2f)
- [ ] Questões de fixação 1 a 13
- [ ] Declaração de uso de IA
- [ ] Referências (mínimo 6)
- [ ] Relatório em PDF nas normas ABNT
- [ ] Slides da apresentação
- [ ] Ata de participação assinada pelos 5

## Datas do professor

- 1ª entrega do relatório técnico: 16/11 (concluída)
- 2ª entrega do relatório técnico: 21/11 (concluída)
- 3ª entrega do relatório técnico: **28/11**
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
