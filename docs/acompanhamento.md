# Acompanhamento do projeto

Aqui eu (Matheus, líder) registro os commits de cada um, os Pull Requests e o que confiro antes de fazer o merge. Atualizo a cada entrega.

## Commits por integrante

Situação em 18/11:

| Integrante | Conta no GitHub | Commits | O que fez |
|---|---|---|---|
| 1 - Matheus | MatheusBastosBarbosa / matheusbastosbarbosaUcsal | 2 | Estrutura inicial do projeto Maven, merge do PR #3 |
| 2 - Edson | edsonNeto-dev | 10 | Diagramas UML, relacional, estrela e floco de neve; DDLs do DW |
| 3 - Danton | DantonFontes | 3 | Mapeamento JPA, GenericDAO, consultas JPQL e Criteria; merges dos PRs #1 e #2 |
| 4 - André | Andre Luiz | 1 | Gerador de dados de teste |
| 5 - Jade | Jade Cerqueira | 1 | Interface de console e validador de dados |

Pra atualizar essa tabela, rodar na pasta do projeto:

```
git pull origin main
git shortlog -sne --all
git log --all --format="%h | %an | %ad | %s" --date=short
```

## Pull Requests

| PR | Branch | Autor | O que traz | Situação |
|---|---|---|---|---|
| #1 | integrante4-carga | André | Gerador de dados de teste | Mesclado em 15/11 |
| #2 | integrante5 | Jade | Interface de console e validador de dados | Mesclado em 15/11 |
| #3 | integrante2 | Edson | Diagramas e DDLs do modelo estrela e do floco de neve | Mesclado em 18/11 |

## O que eu confiro antes de fazer o merge

- [ ] O PR é da branch da pessoa, com a conta dela, e não direto na `main`.
- [ ] Não tem conflito com a `main`.
- [ ] Não tem senha pessoal no `persistence.xml`.
- [ ] Não subiu `target/`, `.idea/`, `.settings/`, `.classpath` nem `.project`.
- [ ] Os arquivos estão na pasta certa (ver `sql/README.md`).
- [ ] Nome de arquivo sem espaço e sem acento.
- [ ] Código Java compila e roda (projeto sem X vermelho no Eclipse).
- [ ] Script SQL roda do começo ao fim num banco `clinica` limpo.
- [ ] Atende o que está no checklist da entrega no README.

## Observações da revisão

- **PR #3 (Edson):** os dois DDLs rodam sem erro no PostgreSQL (6 tabelas em `dw` e 9 em `dw_floco`). Atende o mínimo do professor: 1 fato com 4 medidas, 5 dimensões, Tempo completa e 2 dimensões normalizadas no floco. Ficou pendente acrescentar `item_atendimento_id` na fato, pra carga incremental conseguir identificar cada item.
