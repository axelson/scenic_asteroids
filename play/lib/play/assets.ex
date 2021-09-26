defmodule Play.Assets do
  use Scenic.Assets.Static,
    otp_app: :play,
    alias: [
      roboto: {:scenic, "fonts/roboto.ttf"}
    ]
end
