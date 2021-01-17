defmodule Bank.Cldr do
  @moduledoc """
  Define a backend module that will host our
  Cldr configuration and public API.

  Most function calls in Cldr will be calls
  to functions on this module.
  """

  use Cldr,
    locales: ["pt", "en"],
    default_locale: "pt",
    providers: [Cldr.Number, Money]
end
