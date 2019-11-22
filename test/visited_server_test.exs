defmodule VisitedServerTest do
  use ExUnit.Case
  alias RedisPoolex, as: Redis

  defp clear_db do
    Redis.query(["FLUSHDB"])
  end

  test "get empty model by default" do
    clear_db()
    assert VisitedServer.Model.init() == %{}
  end

  test "add one domain" do
    utime = 1_545_221_231
    links = ["http://ya.ru"]
    {:ok, state} = VisitedServer.Model.add_visited_links(%{}, links, utime)
    assert state == %{utime => ["ya.ru"]}
  end

  test "add multiple domains" do
    utime1 = 1_545_221_231

    links1 = [
      "http://ya.ru",
      "https://stackoverflow.com/questions/11828270/how-to-exit-the-vim-editor"
    ]

    utime2 = 1_545_221_232
    links2 = ["funbox.ru", "https://ya.ru?q=123"]

    {:ok, state} = VisitedServer.Model.add_visited_links(%{}, links1, utime1)
    {:ok, state} = VisitedServer.Model.add_visited_links(state, links2, utime2)

    assert state == %{utime1 => ["stackoverflow.com", "ya.ru"], utime2 => ["ya.ru", "funbox.ru"]}
  end

  test "add invalid domain" do
    utime = 1_545_221_231
    links = ["http://!invalid"]
    {:ok, state} = VisitedServer.Model.add_visited_links(%{}, links, utime)
    assert state == %{}
  end

  test "get all domains" do
    utime1 = 1_545_221_231
    utime2 = 1_545_221_232
    state = %{utime1 => ["stackoverflow.com", "ya.ru"], utime2 => ["ya.ru", "funbox.ru"]}
    {:ok, domains} = VisitedServer.Model.get_visited_domains(state, utime1, utime2)
    assert domains == ["stackoverflow.com", "ya.ru", "funbox.ru"]
  end

  test "get part of domains" do
    utime1 = 1_545_221_231
    utime2 = 1_545_221_232
    state = %{utime1 => ["stackoverflow.com", "ya.ru"], utime2 => ["ya.ru", "funbox.ru"]}
    {:ok, domains} = VisitedServer.Model.get_visited_domains(state, utime2, utime2)
    assert domains == ["ya.ru", "funbox.ru"]
  end

  test "get no domains" do
    utime1 = 1_545_221_231
    utime2 = 1_545_221_232
    state = %{utime1 => ["stackoverflow.com", "ya.ru"], utime2 => ["ya.ru", "funbox.ru"]}
    {:ok, domains} = VisitedServer.Model.get_visited_domains(state, utime2 + 1, utime2 + 2)
    assert domains == []
  end

  test "add & get with database" do
    utime = 1_545_219_425
    from = 1_545_217_638
    to = 1_545_221_231

    links = [
      "https://ya.ru",
      "https://ya.ru?q=123",
      "funbox.ru",
      "https://stackoverflow.com/questions/11828270/how-to-exit-the-vim-editor"
    ]

    clear_db()
    {:ok, state} = VisitedServer.Model.add_visited_links(%{}, links, utime)
    {:ok, domains} = VisitedServer.Model.get_visited_domains(state, from, to)
    assert domains == ["stackoverflow.com", "funbox.ru", "ya.ru"]
  end
end
