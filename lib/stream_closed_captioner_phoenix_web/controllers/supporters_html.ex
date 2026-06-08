defmodule StreamClosedCaptionerPhoenixWeb.SupportersHTML do
  use StreamClosedCaptionerPhoenixWeb, :html
  embed_templates("supporters/*")

  # Monogram-avatar palette, mirrored from the supporters design.
  @avatar_palette ~w(#9146FF #22D3EE #F59E0B #34D399 #F472B6 #60A5FA)

  @doc """
  Renders an active patron as a card: gradient monogram avatar, name, and the
  "Active Patron" heart tier.
  """
  attr :patron, :map, required: true

  def patron_card(assigns) do
    assigns = assign(assigns, :name, assigns.patron["fullName"])

    ~H"""
    <article class="pcard">
      <span class="pcard__avatar" aria-hidden="true" style={avatar_style(@name)}>
        {initials(@name)}
      </span>
      <h3 class="pcard__name">{@name}</h3>
      <span class="pcard__tier">
        <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
          <path d="M12 20.3 4.3 12.6a4.6 4.6 0 0 1 0-6.5 4.6 4.6 0 0 1 6.5 0l1.2 1.2 1.2-1.2a4.6 4.6 0 0 1 6.5 0 4.6 4.6 0 0 1 0 6.5L12 20.3Z" />
        </svg>
        Active Patron
      </span>
    </article>
    """
  end

  @doc "Renders a former patron as a compact chip: monogram dot + name."
  attr :patron, :map, required: true

  def patron_chip(assigns) do
    assigns = assign(assigns, :name, assigns.patron["fullName"])

    ~H"""
    <span class="fchip">
      <span class="fchip__dot" aria-hidden="true" style={avatar_style(@name)}>{initials(@name)}</span>
      <span class="fchip__name">{@name}</span>
    </span>
    """
  end

  @doc """
  Up to two uppercase initials for a patron name, ignoring punctuation. Falls
  back to a star when a name has no alphanumeric characters.
  """
  @spec initials(any()) :: String.t()
  def initials(name) do
    cleaned = name |> to_string() |> String.replace(~r/[^A-Za-z0-9\s]/u, "") |> String.trim()

    case String.split(cleaned, ~r/\s+/, trim: true) do
      [first, second | _] -> String.upcase(String.first(first) <> String.first(second))
      [only] -> only |> String.slice(0, 2) |> String.upcase()
      [] -> "★"
    end
  end

  @doc "Inline gradient background for a monogram avatar, deterministic per name."
  @spec avatar_style(any()) :: String.t()
  def avatar_style(name) do
    color = Enum.at(@avatar_palette, :erlang.phash2(name, length(@avatar_palette)))
    "background: linear-gradient(150deg, #{color}, color-mix(in srgb, #{color} 50%, #000));"
  end

  @doc """
  Splits a list of patrons into `{active, former}` based on whether they are
  currently contributing (`currentlyEntitledAmountCents > 0`), keeping only
  those who have ever contributed.
  """
  @spec partition_patrons(list()) :: {list(), list()}
  def partition_patrons(patrons) do
    patrons
    |> filter_patreon_subscribers()
    |> Enum.split_with(&active_patron?/1)
  end

  @spec filter_patreon_subscribers(list()) :: list()
  def filter_patreon_subscribers(subscribes) do
    Enum.filter(subscribes, fn x ->
      x["campaignLifetimeSupportCents"] > 0
    end)
  end

  @spec active_patron?(map()) :: boolean()
  def active_patron?(patron) do
    (patron["currentlyEntitledAmountCents"] || 0) > 0
  end
end
