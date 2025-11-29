defmodule XyzBackie.Forum.Thread do
  use Ecto.Schema
  import Ecto.Changeset

  alias XyzBackie.{
    Forum.Post
  }

  @type t :: %__MODULE__{}

  @max_title_length 140

  @timestamps_opts [type: :utc_datetime_usec]
  schema "threads" do
    field(:title, :string)
    field(:url_slug, :string)
    field(:count, :integer, default: 0)

    has_many(:posts, Post)

    timestamps()
  end

  @optional_fields []
  @required_fields [:title, :url_slug, :count]

  @doc false
  def changeset(post, params \\ %{}) do
    post
    |> cast(params, @required_fields ++ @optional_fields)
    |> update_change(:title, &String.trim/1)
    |> generate_slug()
    |> unique_constraint(:url_slug, message: "Title has already been taken")
    |> validate_required(@required_fields)
    |> validate_length(:title,
      max: @max_title_length,
      message: "Title should be at most #{@max_title_length} characters long"
    )
  end

  def generate_slug(changeset) do
    get_field(changeset, :title)
    |> case do
      title when is_binary(title) ->
        put_change(changeset, :url_slug, Slug.slugify(title))

      _ ->
        changeset
    end
  end
end
