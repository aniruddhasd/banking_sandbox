defmodule BankingSandboxWeb.PageControllerTest do
    use BankingSandboxWeb.ConnCase

    alias BankingSandbox.BankServer
    alias BankingSandbox.Banking
    alias BankingSandbox.Utils.Helpers
    require Logger
    describe "API" do

        setup do            
            token = BankServer.get_token_list() |> Helpers.generate_random(1)
            conn = build_conn() |> put_req_header("authorization", token)
            {:ok, conn: conn, token: token}
        end
        
        test "Fetch all accounts associated with a token", %{conn: conn, token: token} do
            {:ok, accounts} = Banking.get_customer_accounts(token)
            conn = get(conn, Routes.page_path(conn, :list))
            assert true == is_list Map.get(json_response(conn, 200),"data")
            #assert json_response(conn, 200) |> Jason.encode! == render_account_json("accounts.json", accounts: accounts)
        end

        test "Display error when illegitimate token is used to access accounts", %{conn: conn} do
            token = "random_text_token"       
            conn = build_conn() |> put_req_header("authorization", token)     
            conn = get(conn, Routes.page_path(conn, :list))
            assert json_response(conn, 401) == %{"error" => "not_found"}
        end

        test "Fetch specific account associated with a token & account ID", %{conn: conn, token: token} do
            {:ok, accounts} = Banking.get_customer_accounts(token)
            account = accounts |> Helpers.generate_random(1)
            conn = get(conn, Routes.page_path(conn, :show, account.id))
            assert Map.get(json_response(conn, 200), "id") == account.id
            #assert json_response(conn, 200) |> Jason.encode! == render_account_json("account.json", account: account)
        end

        test "Fetch all transactions of specific account associated with a token & account ID", %{conn: conn, token: token} do
            {:ok, accounts} = Banking.get_customer_accounts(token)
            account = accounts |> Helpers.generate_random(1)
            Process.sleep(3000)
            {:ok, transactions} = Banking.get_customer_account_transactions(token, account.id)
            conn = get(conn, Routes.page_path(conn, :show_transactions, account.id))
            assert true == is_list Map.get(json_response(conn, 200),"data")
            #assert json_response(conn, 200) |> Jason.encode! == render_transaction_json("transactions.json", transactions: transactions)
        end        

        defp render_account_json(template, assigns) do
            assigns = Map.new(assigns)
        
            BankingSandboxWeb.AccountView.render(template, assigns)
            |> Jason.encode!
        end

        defp render_transaction_json(template, assigns) do
            assigns = Map.new(assigns)
        
            BankingSandboxWeb.TransactionView.render(template, assigns)
            |> Jason.encode!
          end
    end
end
  