defmodule BankingSandboxWeb.TransactionView do
  use BankingSandboxWeb, :view

  def render("transactions.json", %{transactions: transactions}) do
    %{data: render_many(transactions, __MODULE__, "transaction.json")}
  end

  def render("transaction.json", %{transaction: transaction}) do
    %{
      type: transaction.type,
      running_balance: transaction.running_balance |> Float.to_string(),
      links: transaction.links,
      id: transaction.id,
      description: transaction.description,
      date: transaction.date,
      amount: transaction.amount |> Float.to_string(),
      account_id: transaction.account_id
    }
  end

  def render("error.json", %{error: error}) do
    %{error: error}
  end
end
