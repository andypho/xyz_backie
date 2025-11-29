defmodule XyzBackie.Repo do
  use Ecto.Repo,
    otp_app: :xyz_backie,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Changeset

  @doc """
  Get the errors from a changeset with the given options.

  The options can be:

  * `:output` - the type of output, can be `:default` (the default) or `:string`.
    If `:string`, the errors are returned as a single string.
    If `:default`, the errors are returned as a list of strings.

  Returns the errors from the changeset.

  ## Examples

      iex> XyzBackie.Repo.get_errors(changeset)
      %{title: ["Title should be at least 3 characters"], ...}

      iex> XyzBackie.Repo.get_errors(changeset, output: :string)
      "Title should be at least 3 characters"
  """
  def get_errors(_, opts \\ [])

  def get_errors(%Ecto.Changeset{} = changeset, opts) do
    traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> format_output(opts)
  end

  def get_errors({:error, %Ecto.Changeset{} = changeset}, opts) do
    get_errors(changeset, opts)
  end

  defp format_output(response, opts) do
    output = Keyword.get(opts, :output, :default)

    case output do
      :string ->
        Enum.reduce_while(response, "", fn {_key, [value]}, acc ->
          if acc == "" do
            {:cont, value}
          else
            {:halt, acc}
          end
        end)

      _ ->
        response
    end
  end
end
