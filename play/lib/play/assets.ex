defmodule Play.Assets do
  use Scenic.Assets.Static,
    otp_app: :play

  def asset_path, do:
    Path.join([__DIR__, "..", "..", "assets"]) |> Path.expand()
end
