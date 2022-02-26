# Projeção de Novos Casos e Óbitos de Covid

## Como funciona

Esse projeto consiste em um script gerador de projeções para novos casos
e óbitos de Covid para todas as UFs e a nível Brasil.

O motor gerador das projeções é o algoritmo
[Prophet](https://github.com/facebook/prophet), projeto de código aberto
desenvolvido e mantido pelo time de ciência de dados do Facebook.

Os atributos do algoritmo já estão definidos no código-fonte, sem necessidade de
intervenção manual ou input de parâmetros.

O algoritmo está programado para levar em consideração a sazonalidade
anual, já que esse é um comportamento observado nos dados da série
histórica.

Para mais informações de como esse projeto funciona, consulte os
comentários no código-fonte.

## Dataset

A fonte dos dados é oriunda do dataset `cases-brazil-states.csv`,
disponibilizado no repositório <https://github.com/wcota/covid19br>.

A cada execução, o script baixa o dataset novamente, substituindo o
anterior, na intenção de sempre fornecer os dados mais atualizados para
a criação da projeção.

## Uso

Para usar, siga a sintaxe abaixo:

`[interpretador da linguagem R] GerarProjecao.R [número de meses para projeção]`

Exemplo:

`Rscript GerarProjecao.R 24`

## Resultados

Os resultados sairão na pasta onde o script se encontra. São eles:

-   Plot interativo de Casos de Covid - Nacional

-   Plot interativo de Óbitos de Covid - Nacional

-   Plot interativo de Casos de Covid - 27 UFs

-   Plot interativo de Óbitos de Covid - 27 UFs

-   Resultados em planilhas - Nacional

-   Resultados em planilhas - 27 UFs

-   Plot de Tendência e Sazonalidade de Casos - Nacional

-   Plot de Tendência e Sazonalidade de Óbitos - Nacional

-   Plot de Tendência e Sazonalidade de Casos - 27 UFs

-   Plot de Tendência e Sazonalidade de Óbitos - 27 UFs

