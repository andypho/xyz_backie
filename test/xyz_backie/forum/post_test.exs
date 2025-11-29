defmodule XyzBackie.Forum.PostTest do
  use XyzBackie.DataCase, async: false
  doctest XyzBackie.Forum.Post

  alias XyzBackie.{
    Forum.Thread,
    Forum.Post
  }

  setup do
    thread =
      Repo.get_by(Thread, url_slug: "hello-world")
      |> case do
        nil ->
          Repo.insert!(%Thread{title: "Hello World", url_slug: "hello-world", count: 0})

        thread ->
          thread
      end

    {:ok, thread: thread}
  end

  describe "Post" do
    test "Test creates a valid post with required fields" do
      params = %{
        "thread_id" => 1,
        "content" => "This is a forum post"
      }

      changeset = Post.changeset(%Post{}, params)
      post = apply_changes(changeset)

      assert changeset.valid?
      assert post.thread_id == 1
      assert post.content == "This is a forum post"
    end

    test "Test validates required fields are present" do
      changeset = Post.changeset(%Post{}, %{})

      refute changeset.valid?
      errors = errors_on(changeset)
      assert "can't be blank" in errors.thread_id
      assert "can't be blank" in errors.content
    end

    test "Test content that is longer than max length" do
      params = %{
        "thread_id" => 1,
        "content" => String.duplicate(".", 10_001)
      }

      changeset = Post.changeset(%Post{}, params)

      refute changeset.valid?
      assert "should be at most 10000 character(s)" in errors_on(changeset).content
    end

    test "Test empty content" do
      params = %{
        "thread_id" => 1,
        "content" => ""
      }

      changeset = Post.changeset(%Post{}, params)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).content
    end

    test "Test post insertion into DB", %{thread: thread} do
      params = %{
        "thread_id" => thread.id,
        "content" => "Foo Bar"
      }

      changeset = Post.changeset(%Post{}, params)

      {:ok, post} = Repo.insert(changeset)

      assert post.thread_id == thread.id
      assert post.content == "Foo Bar"
      assert post.inserted_at != nil
    end
  end
end
