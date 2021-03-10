defmodule StreamClosedCaptionerPhoenix.Transcripts.TranscriptAdmin do
  alias StreamClosedCaptionerPhoenix.Accounts

  def ordering(_schema) do
    [desc: :id]
  end

  def get_user(%{user_id: id}) do
    id
    |> Accounts.get_user!()
    |> Map.get(:username)
  end

  def index(_) do
    [
      user_id: %{name: "User", value: fn p -> get_user(p) end},
      name: nil,
      session: nil
    ]
  end

  # def form_fields(_) do
  #   [
  #     user_id: %{update: :readonly},
  #     caption_delay: nil,
  #     cc_box_size: nil,
  #     filter_profanity: nil,
  #     hide_text_on_load: nil,
  #     language: nil,
  #     pirate_mode: nil,
  #     showcase: nil,
  #     switch_settings_position: nil,
  #     text_uppercase: nil,
  #   ]
  # end

  def scheduled_tasks(_) do
    [
      %{
        name: "Remove Old Transcripts",
        initial_value: nil,
        every: 15,
        action: fn _ ->
          # count = Bakery.Products.cache_product_count()
          # "count" will be passed to this function in its next run.
          {:ok, nil}
        end
      }
    ]
  end
end
