defmodule XyzBackie.Forum.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias XyzBackie.{
    Forum.Thread
  }

  @type t :: %__MODULE__{}

  @max_content_length 10_000

  @timestamps_opts [type: :utc_datetime_usec]
  schema "posts" do
    belongs_to(:thread, Thread)

    field(:content, :string)

    timestamps(updated_at: false)
  end

  @optional_fields []
  @required_fields [:thread_id, :content]

  @doc false
  def changeset(post, params \\ %{}) do
    post
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:content, max: @max_content_length)
  end
end
