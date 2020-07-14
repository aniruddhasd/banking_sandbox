# BankingSandbox

## To start the Banking Sandbox server, run

  To start the Banking Sandbox server, run
  ```console
  $ docker-compose up
  ```
  This will download the necessary deps, create the environment and start the server at [`localhost:4000`](http://localhost:4000)

  If you have an existing phoenix environment, setup for live_view:

  * Setup the project with `mix setup`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Banking Server Dashboard
  The Live Bank Server display current stats about the banking server. Total number of customers, accounts & transactions (credit & debit), updated in real-time.
  The Token list acts as a source to pick from, to test out the APIs.

## Banking Sandbox APIs usage:

GET /accounts
```console
curl --request GET 'http://localhost:4000/accounts' \
  --header 'Authorization: <YOUR-TOKEN>'
```  
GET /accounts/:account_id
```console
curl --request GET 'http://localhost:4000/accounts/<YOUR-ACCOUNT-ID>' \
  --header 'Authorization: <YOUR-TOKEN>'
```  
GET /accounts/:account_id/transactions
```console
curl --request GET 'http://localhost:4000/accounts/<YOUR-ACCOUNT-ID>/transactions' \
  --header 'Authorization: <YOUR-TOKEN>'
```
