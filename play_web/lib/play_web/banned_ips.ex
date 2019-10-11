defmodule PlayWeb.BannedIPs do
  def banned?(ip_addr_tuple) do
    text = File.read!(file_path())
    IO.inspect(text, label: "text")
  end

  defp file_path, do: Path.join(:code.priv_dir(:play_web), "bans.txt")
end
