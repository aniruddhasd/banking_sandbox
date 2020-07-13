defmodule BankingSandbox.PrimarySupervisor do
  @moduledoc """
      Supervisor for conversation processes
  """
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
