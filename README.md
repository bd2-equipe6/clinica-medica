# Sistema de Clínica Médica - BD2

Trabalho da 2ª unidade de Banco de Dados II.
Equipe 6 - tema: clínica médica (atendimentos e procedimentos).

> **Uso de IA:** Usamos o Claude como apoio na resolução de erros de configuração e na escrita deste README. Tudo foi testado e revisado pela equipe.

Nessa primeira entrega o objetivo é ter o sistema OLTP funcionando em Java com JPA 2.1 + Hibernate 5.2.10 e PostgreSQL. Depois, na segunda parte, esses dados vão ser usados no Data Warehouse.

## O que precisa ter instalado

- JDK 8 (o Hibernate 5.2 precisa do Java 8)
  https://adoptium.net/temurin/releases/?version=8
  Escolher Windows, x64, JDK, versão 8 e baixar o .msi. Na instalação marcar "Set JAVA_HOME" e "Add to PATH".

- Eclipse Neon (Eclipse IDE for Java EE Developers), que é o que o professor pediu
  https://www.eclipse.org/downloads/packages/file/49873
  Não tem instalador, é só descompactar e abrir o eclipse.exe.
  Obs: dá pra usar um Eclipse mais novo também, desde que o projeto esteja usando o JDK 8.

- PostgreSQL
  https://www.postgresql.org/download/windows/
  Qualquer versão a partir da 12 serve. Eu testei com a 15.

- Git
  https://git-scm.com/downloads

## Configurando na sua máquina

1. Criar o banco no pgAdmin com o nome `clinica` (botão direito em Databases > Create > Database).

2. Clonar o repositório:
   ```
   git clone LINK_DO_REPOSITORIO
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
├── docs/        diagramas (UML e modelo relacional)
├── sql/         scripts SQL
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

## Quem faz o quê (Entrega 1)

- **Integrante 1 - Líder:** repositório, estrutura do projeto, prazos, juntar as partes e revisar a entrega.
- **Integrante 2 - Arquiteto de dados:** definir as entidades (mínimo 8), atributos e relacionamentos, fazer o diagrama UML e o modelo relacional. Os arquivos vão na pasta `docs/`.
- **Integrante 3 - Desenvolvedor ORM:** entidades com as anotações JPA, persistence.xml, GenericDAO, 10 consultas JPQL e 3 Criteria.
- **Integrante 4 - Engenheiro de ETL:** classe que gera os dados de teste (200 pacientes, 100 procedimentos, 5 unidades e 2.000 atendimentos em pelo menos 2 anos).
- **Integrante 5 - Analista de BI:** interface com CRUD de pelo menos 2 entidades, testar tudo e conferir os dados gerados.

Ordem: o 2 precisa terminar o modelo primeiro, porque o 3 depende dele. O 4 e o 5 dependem das entidades do 3.

## O que o professor pediu na Entrega 1

- [ ] Projeto Maven com pom.xml e persistence.xml
- [ ] No mínimo 8 entidades
- [ ] @OneToOne
- [ ] @OneToMany / @ManyToOne bidirecional
- [ ] @ManyToMany (ou entidade intermediária)
- [ ] Herança (@Inheritance)
- [ ] Classe @Embeddable e atributo @Enumerated
- [ ] Datas com @Temporal ou java.time
- [ ] Diagrama UML e modelo relacional
- [ ] GenericDAO com CRUD
- [ ] 10 consultas JPQL (junção, JOIN FETCH, GROUP BY/HAVING, subconsulta, parâmetro nomeado, paginação e 2 @NamedQuery)
- [ ] 3 consultas Criteria, uma com filtro dinâmico
- [ ] Gerador de dados
- [ ] Interface com CRUD de 2 entidades

## Prazos

- Semana 1 (30/10 a 05/11): equipes, tema e papéis
- Semana 2 (06/11 a 08/11): entidades, persistence.xml e DAOs
- Semana 3 (09/11 a 11/11): consultas e carga de dados - **Entrega 1**
- Semana 4 (12/11 a 16/11): modelo estrela, floco de neve e ETL - Entrega 2
- Semana 5 (16/11 a 19/11): OLAP, mineração e relatório - Entrega 3
- Semana 6 (21/11 a 27/11): apresentação

## Como usar o Git

O professor olha o histórico de commits pra ver a participação de cada um, então **cada um faz commit do próprio trabalho com a própria conta**.

```
git pull origin main
git checkout -b integrante3-entidades
(faz as alterações)
git add .
git commit -m "Cria entidade Paciente"
git push origin integrante3-entidades
```

Depois abre um Pull Request no GitHub pra main. Eu reviso e faço o merge.

Antes de começar a mexer, sempre dá um `git pull` pra pegar o que os outros já subiram.