defmodule XyzBackie.Repo.Migrations.CreateThreadsPostTables do
  use Ecto.Migration

  def change do
    create table(:threads) do
      add(:title, :string, null: false)
      add(:url_slug, :string, null: false)
      add(:count, :integer, null: false, default: 0)

      timestamps(type: :utc_datetime_usec, default: fragment("now()"))
    end

    create(unique_index(:threads, [:url_slug]))
    create(index(:threads, [:count]))

    create table(:posts) do
      add(:thread_id, references(:threads, on_delete: :delete_all), null: false)
      add(:content, :text, null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("now()"), updated_at: false)
    end

    create(index(:posts, [:thread_id]))
  end
end
