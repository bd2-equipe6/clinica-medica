# Scripts SQL

Aqui ficam todos os scripts do Data Warehouse. O banco é o mesmo da aplicação (`clinica`), mas cada parte fica no seu próprio esquema, separado das tabelas do OLTP que o Hibernate cria no `public`.

## Pastas

| Pasta | O que vai nela | Responsável |
|---|---|---|
| `dw/` | DDL do modelo estrela (esquema `dw`) e do floco de neve (esquema `dw_floco`) | Integrante 2 |
| `etl/` | Área de staging, carga das dimensões, carga da fato, carga incremental e SCD tipo 2 | Integrante 4 |
| `validacao/` | Conferência da carga (OLTP x DW) e teste do fluxo completo | Integrantes 1 e 5 |
| `olap/` | Consultas OLAP da Entrega 3 (roll-up, drill-down, slice, dice e pivot) | Integrante 5 |

## Esquemas no banco

- `public`: tabelas do sistema (OLTP), criadas pelo Hibernate. **Os scripts do DW não alteram nada aqui**, só leem.
- `staging`: área de staging do ETL.
- `dw`: modelo estrela.
- `dw_floco`: modelo floco de neve.

## Ordem para rodar

1. Rodar a aplicação pelo menos uma vez e o `GeradorDados`, para o OLTP ter dados.
2. `dw/DDL_modelo_Estrela.sql`
3. `dw/DDL_modelo_Floco_de_Neve.sql`
4. Os scripts de `etl/`, na ordem do número no nome do arquivo.
5. Os scripts de `validacao/`.

Os DDLs começam com `DROP SCHEMA ... CASCADE`, então rodar de novo **apaga o DW inteiro**. O OLTP não é afetado.

## Nomes dos arquivos

Na pasta `etl/`, comecem o nome com um número para deixar a ordem clara, por exemplo:

```
01_staging.sql
02_dim_tempo.sql
03_dimensoes.sql
04_fato.sql
05_carga_incremental.sql
06_scd2_paciente.sql
```

Sem espaço e sem acento no nome do arquivo.
