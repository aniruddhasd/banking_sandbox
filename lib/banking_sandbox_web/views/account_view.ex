defmodule BankingSandboxWeb.AccountView do
    use BankingSandboxWeb, :view
    def render("accounts.json", %{accounts: accounts}) do
        %{data: render_many(accounts, __MODULE__, "account.json")}
    end
    def render("account.json", %{account: account}) do
        %{
            account_number: account.account_number,
            balances: %{available: account.balances.available |> Float.to_string, ledger: account.balances.ledger |> Float.to_string},
            currency_code: account.currency_code,
            enrollment_id: account.enrollment_id,
            id: account.id,
            institution: account.institution,
            links: account.links,
            name: account.name,
            routing_numbers: account.routing_numbers
        }
    end

    def render("error.json", %{error: error}) do
        %{error: error}
    end
end