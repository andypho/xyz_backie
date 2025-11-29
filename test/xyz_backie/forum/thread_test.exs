defmodule XyzBackie.Forum.ThreadTest do
  use XyzBackie.DataCase, async: false
  doctest XyzBackie.Forum.Thread

  alias XyzBackie.{
    Forum.Thread
  }

  describe "Thread" do
    test "Test url slug generation" do
      "Hello World"
      |> Slug.slugify()
      |> assert("hello-world")
    end

    test "Test creates a valid thread with title field only" do
      params = %{
        "title" => "Hello World"
      }

      changeset = Thread.changeset(%Thread{}, params)
      thread = apply_changes(changeset)

      assert changeset.valid?
      assert thread.title == "Hello World"
      assert thread.url_slug == "hello-world"
      assert thread.count == 0
    end

    test "Test title that is longer than max length" do
      params = %{
        "title" => String.duplicate(".", 141)
      }

      changeset = Thread.changeset(%Thread{}, params)

      refute changeset.valid?
      assert "Title should be at most 140 characters long" in errors_on(changeset).title
    end

    test "Test title trimming" do
      params = %{
        "title" => "   Hello World   "
      }

      changeset = Thread.changeset(%Thread{}, params)
      thread = apply_changes(changeset)

      assert changeset.valid?
      assert thread.title == "Hello World"
      assert thread.url_slug == "hello-world"
    end

    test "Test Empty title" do
      params = %{
        "title" => "    "
      }

      changeset = Thread.changeset(%Thread{}, params)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
    end

    test "Test thread insertion into DB" do
      params = %{
        "title" => "Hello World Test"
      }

      changeset = Thread.changeset(%Thread{}, params)

      {:ok, thread} = Repo.insert(changeset)

      assert thread.title == "Hello World Test"
      assert thread.url_slug == "hello-world-test"
      assert thread.count == 0
      assert thread.inserted_at != nil
    end

    test "Test unique url slug constraint" do
      params = %{
        "title" => "Duplicating Title"
      }

      changeset1 = Thread.changeset(%Thread{}, params)
      {:ok, _thread1} = Repo.insert(changeset1)

      changeset2 = Thread.changeset(%Thread{}, params)
      {:error, changeset2} = Repo.insert(changeset2)

      refute changeset2.valid?
      assert "Title has already been taken" in errors_on(changeset2).url_slug
    end
  end
end
