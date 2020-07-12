defmodule BankingSandbox.Workers.TransactionExecutor do
    require Logger    
    use GenServer
    alias BankingSandbox.Workers.AccountTracker
    @supervisor BankingSandbox.PrimarySupervisor
    @registry BankingSandbox.Registry

    def start() do 
        DynamicSupervisor.start_child(@supervisor, {__MODULE__, []})
    end

    def get_account(account_id) do
        case Registry.lookup(@registry, {AccountTracker, account_id}) do
          [{pid, _}] -> {:ok, pid}
          [] -> {:error, :not_found}
        end
    end

    def terminate(reason, state) do
        Logger.info"reason #{reason}"
    end

    def start_link(opts) do        
        GenServer.start_link(__MODULE__, opts)
    end

    def init(_opts) do
       {:ok, %{}}
    end

    def handle_call({:execute, account_id},_,state) do     
        Logger.info"CHILDREN #{inspect Supervisor.which_children(BankingSandbox.PrimarySupervisor)}"
        with {:ok, pid} <- get_account(account_id) do
            GenServer.call(pid, {:transaction})
        else
            {:error,reason} ->
                {:error,reason}
        end
        {:reply,account_id, state}
    end
end