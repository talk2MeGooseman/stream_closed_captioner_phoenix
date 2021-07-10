ExUnit.configure(timeout: :infinity)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(StreamClosedCaptionerPhoenix.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)

# Mocks services out using their provider
Mox.defmock(Azure.MockCognitive, for: Azure.CognitiveProvider)
Mox.defmock(Twitch.MockExtension, for: Twitch.ExtensionProvider)
Mox.defmock(Twitch.MockHelix, for: Twitch.HelixProvider)
