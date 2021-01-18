[![Build Status](https://www.travis-ci.org/jhonisds/bank.svg?branch=main)](https://www.travis-ci.org/jhonisds/bank) [![codecov](https://codecov.io/gh/jhonisds/bank/branch/main/graph/badge.svg?token=O7T9IK4OW5)](https://codecov.io/gh/jhonisds/bank)

Projeto bank desenvolvido com a linguagem funcional `Elixir`. Tem como principal objetivo aplicar os
requisitos do [desafio técnico Stone](https://gist.github.com/Isabelarrodrigues/873b8849e8b54f0968d77a4b2f111ec4).

# Bank

O projeto permite realizar operações financeiras como: depósitos, retiradas, tranferências de valores, split de transações e conversão de moedas.
Utiliza a biblioteca `ex_money` que implementa um conjunto de funções aritméticas em conformidade com o padrão [ISO 4217](https://www.iso.org/iso-4217-currency-codes.html). A API [open exchange rates](https://openexchangerates.or) é empregada para a conversão de moedas.

## Ambiente de desenvolvimento

![elixir](https://hexdocs.pm/elixir/assets/logo.png)

Para execução do projeto é necessário instalar o `Elixir` e o banco de dados `PostgreSQL`.

> Elixir é uma linguagem dinâmica e funcional projetada para construir aplicativos escaláveis ​​e de fácil manutenção.
> Sua instalação pode ser feita conforme o [guia de instalação](https://elixir-lang.org/install.html) ou por meio do [asdf](https://asdf-vm.com/#/core-manage-asdf).

> PostgreSQL para a persistência dos dados.
> Guia de [instalacão](https://www.postgresql.org/download/), também pode ser obtido via asdf ou [docker](https://hub.docker.com/_/postgres).
> Segue abaixo estrutura da tabela accounts.

tabela: `accounts`

| Column        | Type                           |
| ------------- | ------------------------------ |
| id            | bigint                         |
| account_owner | character varying(255)         |
| balance       | character varying(255)         |
| currency      | money_with_currency            |
| insert_at     | timestamp(0) without time zone |
| update_at     | timestamp(0) without time zone |

Após a instalação das ferramentas realize o clone do projeto e execute os comandos abaixo.

```sh
git clone https://github.com/jhonisds/bank.git
cd bank
mix deps.get
mix ecto.setup
```

O projeto fornece um arquivo de `seeds.exs`, para criação de registros pré definidos.
Obtidos através dos comandos `mix ecto.setup` ou `mix run priv/repo/seeds.exs`.

```elixir
accounts = [
  %{account_owner: "Tupac", currency: Money.new(:BRL, 0), balance: "R$ 0"},
  %{account_owner: "Jay", currency: Money.new(:BRL, 500), balance: "R$ 500"},
  %{account_owner: "Notorious", currency: Money.new(:BRL, 500), balance: "R$ 500,55"},
  %{account_owner: "Lauryn", currency: Money.new(:USD, 100), balance: "U$ 100.99"},
  %{account_owner: "Dre", currency: Money.new(:EUR, 200), balance: "€ 200.05"},
  %{account_owner: "Snoop", currency: Money.new(:AUD, 300), balance: "AU$ 300,00"}
]

Enum.each(accounts, &Accounts.create_account/1)
```

## Dependências

| Biblioteca                                                             | Descrição                                                                                                                     |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| [ecto_sql](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.html)         | persistência de dados                                                                                                         |
| [ex_money_sql](https://hexdocs.pm/ex_money_sql/readme.html)            | implementa a estrutura de dados `%Money{}` em conformidade com a [ISO 4217](https://www.iso.org/iso-4217-currency-codes.html) |
| [ex_doc](https://hexdocs.pm/ex_doc/readme.html)                        | gerador de documentação                                                                                                       |
| [dialyxir](https://hexdocs.pm/dialyxir/readme.html)                    | análise de código estático                                                                                                    |
| [mix_test_watch](https://hexdocs.pm/mix_test_watch/api-reference.html) | roda os testes automaticamente conforme as mudanças no código                                                                 |
| [excoveralls](https://hexdocs.pm/excoveralls/readme.html)              | gera relatórios de cobertura de testes                                                                                        |
| [credo](https://hexdocs.pm/credo/overview.html)                        | ferramenta de análise de código estático                                                                                      |

## Execute as transações

Certifique-se que o banco de dados postgreSQL esteja em execução. E no diretório do projeto abra o terminal e execute o shell interativo do Elixir
com o comando `iex -S mix` e informe as operações abaixo:

> `create_account/1` recebe um map com os parâmetros account_owner único e obrigatório,
> currency é opcional, se não informado utiliza o padrao :BRL.

```elixir
Accounts.create_account %{account_owner: "Jhoni"}
{:ok, %Account{}}
```

> `deposit/3` recebe uma conta(id) e valor para depósito.
> currency é opcional, se não informado utiliza o padrao :BRL.

```elixir
Transactions.deposit 1, 200.99
{:ok, "successfuly deposit transaction - current balance: R$ 200,99"}
```

> `withdraw/2` recebe uma conta(id) e valor para retirada.

```elixir
Transactions.withdraw 1, 200.99
{:ok, "successfuly withdraw transaction - current balance: R$ 00.00"}
```

> `transfer/3` recebe uma conta(id) para retirada, depósito e valor.

```elixir
Transactions.transfer 1, 2, 20
{:ok,
 "successfuly transfer R$ 20,00 to Notorious - current balance: R$ 1.112,99"}
```

> `split/3` recebe uma conta(id) para retirada, contas(list) para depósito e valor.
> Permite apenas transações entre mesma moeda.

```elixir
Transactions.split 1, [1,2,3], 100
[
  error: "same account - choose another account to transfer",
  ok: "successfuly transfer R$ 33,33 to Notorious - current balance: R$ 1.079,66",
  error: "cannot transfer monies with different currencies"
]
```

> `exchange/3` recebe moedas para conversão e valor.

```elixir
Transactions.exchange :BRL, :USD, 100.99
{:ok, "successfuly exchange: US$ 19,08"}
```

## Documentação

Documentação dos módulos e funções do projeto através do comando `mix docs`.

```sh
mix docs
```

## Testes

Comandos para execução dos testes:

```sh
mix test # executa todos os testes
mix test test/bank/transactions_test.exs:94 # informe arquivo e linha para executar um teste específico

mix test --cover # cobertura de testes
mix coveralls.html # gera relatório de cobertura `cover/excoveralls.html`

```

## Qualidade

Ferramentas para integração contínua e cobertura de testes. Além da inclusão do alias: ` format_credo: ["format", "credo --strict"]` que garante a formatação e consistência do código.

- [Travis CI](https://travis-ci.org/)
- [Codecov](https://about.codecov.io/)

## Referências

### Livros

- [Learn Functional Programming With Elixir](https://pragprog.com/titles/cdc-elixir/learn-functional-programming-with-elixir/)
- [Elixir in Action](https://www.manning.com/books/elixir-in-action-second-edition)
- [Programming Elixir 1.6](https://pragprog.com/titles/elixir16/programming-elixir-1-6/)

### Sites

- [Elixir School](https://elixirschool.com/pt/)
- [Elixir lang](https://elixir-lang.org/getting-started/introduction.html)
- [Melhores Práticas na StoneCo](https://github.com/stone-payments/stoneco-best-practices/blob/master/README_pt.md)
- [O Guia de Estilo Elixir](https://github.com/gusaiani/elixir_style_guide/blob/master/README_ptBR.md)
- [Open exchange rates](https://openexchangerates.org/)
- [ex_money](https://hexdocs.pm/ex_money/readme.html)

## License

- Mit

## Novas funcionalidades

- A estrutura do projeto está preparada para implementar uma aplicação web com [Phoenix](https://phoenixframework.org/).
