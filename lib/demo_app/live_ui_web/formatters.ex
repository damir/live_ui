defmodule LiveUIWeb.Formatters do
  @moduledoc false

  def money(record, value) do
    Money.new(Map.get(record, :currency), value)
  end
end
