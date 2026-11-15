# Informações da clínica para o Data Warehouse

Aqui está o que a gente achou importante analisar depois, usando as entidades que já estão no projeto: Paciente, Médico, Unidade, Atendimento, ItemAtendimento, Procedimento, CategoriaProcedimento, Especialidade, Convênio e Prontuário.

## O que queremos descobrir

- Quais procedimentos e categorias dão mais dinheiro e quais são mais feitos.
- Qual unidade atende mais e qual fatura mais, e como isso muda de mês para mês e de ano para ano.
- Quais médicos e especialidades têm mais procura.
- Qual a taxa de cancelamento (atendimentos cancelados em relação ao total) e se ela muda por unidade, médico, tipo de atendimento ou dia da semana.
- Que tipo de paciente (idade, cidade, convênio) mais usa cada categoria de procedimento.
- Quantos retornos existem em relação às consultas e quanto tempo o paciente leva para voltar.
- Quanto os convênios dão de desconto em relação ao valor total.
- Em quais dias e horários a clínica fica mais cheia.

## Como pensamos o modelo estrela

O fato principal seria o **item de atendimento**, ou seja, cada procedimento feito dentro de um atendimento. As medidas são a quantidade, o valor unitário e o desconto, que já existem na tabela, mais o valor bruto (quantidade vezes valor unitário) e o valor líquido (valor bruto menos o desconto), que seriam calculados na hora de carregar.

Dá para ter também um fato por **atendimento**, só com o total de itens, o valor total e um contador. Ele ajuda a calcular cancelamento e ocupação.

As dimensões seriam:

- **Tempo:** data, ano, semestre, trimestre, mês, dia da semana, hora e turno (vem de `dataHora` do atendimento).
- **Paciente:** faixa etária, cidade, UF, bairro, tipo sanguíneo e data de cadastro.
- **Médico:** nome, CRM e especialidade.
- **Unidade:** nome, cidade e UF.
- **Procedimento:** código, nome e categoria.
- **Convênio:** nome e percentual de desconto.
- **Atendimento:** tipo e status, que podem ficar juntos numa dimensão só.

No floco de neve (Entrega 2), a ideia é separar a categoria do procedimento, a cidade da unidade e do paciente, e a especialidade do médico.

## Exemplos de OLAP para a Entrega 3

- Roll-up: receita por mês, depois por trimestre, depois por ano.
- Drill-down: sair da categoria e ver cada procedimento dela.
- Slice: olhar só uma unidade, ou só os atendimentos realizados.
- Dice: duas unidades, dois anos e uma categoria específica ao mesmo tempo.
- Pivot: unidades nas linhas, trimestres nas colunas e receita líquida nas células.

## Ideias de mineração

- Agrupar pacientes por idade, número de atendimentos e valor gasto (K-means).
- Ver quais procedimentos aparecem juntos no mesmo atendimento (regras de associação).
- Tentar prever se um atendimento vai ser cancelado, usando tipo, unidade, médico, dia da semana, horário e idade (árvore de decisão).

## Pontos para combinar com o grupo

1. **Convênio e paciente.** Hoje `Paciente.convenio` está como `@OneToOne(unique = true)`, o que quer dizer que cada convênio só pode ter um paciente. Na prática vários pacientes usam o mesmo convênio, então talvez o certo seja muitos para um. Isso muda a dimensão de convênio.
2. **O que é o desconto.** Precisamos decidir se `ItemAtendimento.desconto` é um valor em reais ou um percentual. O validador considera que é em reais.
3. **Dados gerados.** Para a mineração fazer sentido, os dados não podem ser todos iguais. Seria bom variar o status (por exemplo uns 70% realizados, 20% cancelados e 10% agendados), ter mais atendimentos em dias úteis e dar pesos diferentes para as unidades e os procedimentos. A opção 3 do menu mostra como os atendimentos estão distribuídos.
4. **Valor do atendimento.** O atendimento não tem valor total, ele só existe nos itens. Por isso todo atendimento precisa ter pelo menos um item, e o validador confere isso.
5. **Médico e unidade.** Não existe ligação direta entre os dois. Para saber que médico atende em qual unidade, só olhando os atendimentos.
