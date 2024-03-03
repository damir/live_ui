defmodule LiveUI.Cldr do
  @moduledoc false

  use Cldr,
    default_locale: "en",
    otp_app: :live_ui,
    providers: [Cldr.Number, Money, Cldr.Calendar, Cldr.DateTime],
    gettext: LiveUIWeb.Gettext

  # precompile_date_time_formats: ["y MMM d, E – "]
end
