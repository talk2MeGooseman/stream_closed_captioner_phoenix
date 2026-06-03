defmodule StreamClosedCaptionerPhoenixWeb.SupportersHTML do
  use StreamClosedCaptionerPhoenixWeb, :html
  embed_templates("supporters/*")

  @doc """
  Renders a single patron card. Active patrons get a filled, colored heart and
  a green status badge; former patrons get a muted outline heart and a dimmed card.
  """
  attr :patron, :map, required: true

  def patron_card(assigns) do
    assigns = assign(assigns, :active?, active_patron?(assigns.patron))

    ~H"""
    <div class={[
      "group relative flex items-center gap-4 overflow-hidden rounded-2xl border bg-white p-5 shadow-sm",
      "transition duration-200 hover:-translate-y-1 hover:shadow-xl dark:bg-gray-800",
      if(@active?,
        do: "border-rose-100 dark:border-rose-900/40",
        else: "border-gray-100 dark:border-gray-700"
      )
    ]}>
      <span class={[
        "absolute inset-y-0 left-0 w-1.5",
        if(@active?,
          do: "bg-gradient-to-b from-rose-400 to-pink-500",
          else: "bg-gray-200 dark:bg-gray-600"
        )
      ]} />

      <div class="min-w-0">
        <div class="truncate text-lg font-semibold text-gray-900 dark:text-gray-100">
          {@patron["fullName"]}
        </div>
        <span class={[
          "mt-1.5 inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium",
          if(@active?,
            do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
            else: "bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300"
          )
        ]}>
          <span class={[
            "h-1.5 w-1.5 rounded-full",
            if(@active?, do: "bg-green-500", else: "bg-gray-400")
          ]} />
          {get_polite_status(@patron["currentlyEntitledAmountCents"])}
        </span>
      </div>
    </div>
    """
  end

  @spec filter_patreon_subscribers(list()) :: list()
  def filter_patreon_subscribers(subscribes) do
    Enum.filter(subscribes, fn x ->
      x["campaignLifetimeSupportCents"] > 0
    end)
  end

  @doc """
  Splits a list of patrons into `{active, former}` based on whether they are
  currently contributing (`currentlyEntitledAmountCents > 0`).
  """
  @spec partition_patrons(list()) :: {list(), list()}
  def partition_patrons(patrons) do
    patrons
    |> filter_patreon_subscribers()
    |> Enum.split_with(&active_patron?/1)
  end

  @spec active_patron?(map()) :: boolean()
  def active_patron?(patron) do
    (patron["currentlyEntitledAmountCents"] || 0) > 0
  end

  def get_polite_status(support_value) do
    case support_value > 0 do
      true -> "Active Patron"
      _ -> "Former Patron"
    end
  end
end
