# Técnica de mineração escolhida

Escolhemos **regras de associação com o algoritmo Apriori**. A ideia é descobrir quais categorias de procedimento costumam aparecer juntas no mesmo atendimento (por exemplo, quem faz exame laboratorial também faz vacina na mesma ida à clínica).

## Por que o Apriori

A tabela fato tem uma linha por procedimento dentro de um atendimento. Se agruparmos pelo `atendimento_id`, cada atendimento vira uma "cesta" com os procedimentos que foram feitos nele. É exatamente o formato que o Apriori usa, então não precisa de nenhuma transformação complicada.

Pela lógica do `GeradorDados`, os atendimentos de consulta e retorno trazem a consulta mais, às vezes, exame, vacina ou terapia; os de exame trazem de 1 a 3 exames; e os de emergência trazem um pequeno procedimento mais exames. Numa simulação com essa mesma lógica, cerca de 40% dos atendimentos tinham 2 ou mais procedimentos (e uns 37% tinham 2 ou mais categorias diferentes), o que dá cestas suficientes para minerar.

## Por que não as outras duas

- **k-means:** precisaria de variáveis por paciente, e a `dim_paciente` só tem cidade, UF e convênio (não tem idade). O gerador também sorteia o paciente de cada atendimento de forma uniforme, então os grupos tenderiam a refletir só o acaso.
- **Árvore de decisão:** o alvo mais interessante seria prever o cancelamento. Só que atendimento cancelado não tem item, então não entra na fato, e no OLTP o cancelamento é sorteado (8%) sem depender de nenhum outro campo. Não haveria o que aprender.

## Como vamos fazer

1. **Extrair as cestas do DW** (primeira consulta abaixo). Usamos a **categoria** do procedimento e não o procedimento em si, porque são 100 procedimentos diferentes e um par específico aparece em bem menos de 1% dos atendimentos (na simulação, o par mais frequente ficou em torno de 0,4%). Com categorias são só 7 itens e, na simulação, vários pares passaram de 3% de suporte (o maior chegou perto de 8%).
2. **Montar a tabela de cestas:** uma linha por atendimento e uma coluna por categoria (verdadeiro ou falso).
3. **Rodar o Apriori** com suporte mínimo de 3% e confiança mínima de 30%. Pode ser em Python (biblioteca `mlxtend`, funções `apriori` e `association_rules`) ou no Weka.
4. **Interpretar** olhando suporte, confiança e lift. Só vale a pena comentar as regras com lift maior que 1. Uma regra do tipo "Terapias → Consultas" com confiança alta faz sentido, porque no gerador as terapias só aparecem como extra de uma consulta.

Como os dados são sintéticos, as regras que aparecerem refletem o jeito que o gerador foi montado e não o comportamento de uma clínica de verdade. Vale comentar isso no relatório.

## Consultas de apoio

Cestas (uma linha por atendimento e categoria):

```sql
SELECT f.atendimento_id, p.categoria
FROM dw.fato_atendimento f
INNER JOIN dw.dim_procedimento p ON p.sk_procedimento = f.sk_procedimento
GROUP BY f.atendimento_id, p.categoria
ORDER BY f.atendimento_id, p.categoria;
```

Quantos atendimentos têm 2 ou mais categorias (para conferir se dá para minerar):

```sql
SELECT COUNT(*) AS atendimentos,
       COUNT(*) FILTER (WHERE categorias >= 2) AS com_2_ou_mais_categorias,
       ROUND(100.0 * COUNT(*) FILTER (WHERE categorias >= 2) / COUNT(*), 1) AS percentual
FROM (SELECT f.atendimento_id, COUNT(DISTINCT p.categoria) AS categorias
      FROM dw.fato_atendimento f
      INNER JOIN dw.dim_procedimento p ON p.sk_procedimento = f.sk_procedimento
      GROUP BY f.atendimento_id) c;
```
