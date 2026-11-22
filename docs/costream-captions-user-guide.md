# Captioning Your Co-Streamers: Guest Captions

> **Draft** — for the site's help section. Screenshots and final link URLs to
> be added before publishing.

Streaming with a friend, a podcast guest, or a whole squad? Co-stream captions
let the people streaming *with* you have their speech captioned too — shown to
your viewers right alongside your own captions, labeled with their name, like:

```
Did you see that boss fight?
Alice: I can't believe we actually beat it.
```

Your guests don't need a Stream Closed Captioner account, and you stay in
control the whole time: you can mute or remove any guest instantly, and
nothing they say reaches your viewers unless *you* are live and captioning.

## What you'll need

- **You (the host):** your normal Stream Closed Captioner setup — nothing new.
- **Your guests:** Google Chrome, Microsoft Edge, or Safari. Guest captions
  use the browser's built-in speech recognition, and other browsers don't
  support it yet. That's the only requirement — no account, no install.
- **Your viewers:** the current version of the Twitch extension. Viewers on
  older versions simply won't see guest captions (your own captions are
  unaffected).

## Inviting a guest

1. Open **Co-stream Captions** from your dashboard's side menu.
2. Type your guest's name — this is the label viewers will see in front of
   their captions, so pick something readable like `Alice`, not
   `xX_alice_Xx_backup2`. You choose the name, not the guest.
3. Click **Create invite link**, then **Copy**, and send the link to your
   guest however you like (Discord DM, etc.).
4. That's it. You can have up to **4 guest links** at a time.

**Treat each link like a key to your stream's captions.** Anyone who has it
can put words on your stream while you're live. Send it privately, and if a
link ever leaks — or a guest turns out to be a gremlin — click
**Kick & revoke** and that link is dead everywhere, immediately and
permanently. Recurring co-streamer? Their link keeps working stream after
stream until you revoke it, so you only have to send it once.

## What your guest does

Your guest opens the link and lands on a simple captioning page:

1. Pick their **spoken language** (it starts on yours).
2. Click **Start Captions** and allow microphone access when the browser asks.
3. Talk. They'll see their own live captions on the page, exactly as your
   viewers see them — including any words your filters cleaned up.

The page also shows them two status badges worth knowing about:

- **Connected / Connection problem** — their link to the caption service.
- **Streamer is captioning / Streamer offline** — guest captions only flow
  while *you* are actively captioning from your dashboard. If you stop, their
  captions pause automatically; when you start again, they resume. A guest
  can never broadcast to your audience while you're away.

If they see a yellow browser warning instead of a Start button, they're not
in Chrome, Edge, or Safari — have them reopen the link in one of those.

## Staying in control while live

The **Co-stream Captions** page doubles as your live control room. For each
guest you can see whether they're connected and watch their captions in real
time as they speak. Two buttons sit next to every guest:

- **Mute** — their captions stop reaching viewers instantly, but they stay
  connected and can be unmuted just as fast. Good for "hold on, someone's
  eating chips into the mic."
- **Kick & revoke** — disconnects them *and* permanently kills their link.
  For when mute isn't enough.

There's also a master switch at the top of the page — **Guest captions
ON/OFF** — that silences *all* guest captions at once, no matter what, while
leaving your own captions untouched. Think of it as the big red button.

One more layer you already have: your **blocklist and profanity filter apply
to everything your guests say**, using your settings. It's your stream —
your rules run on their words too.

## What your viewers see and control

Guest captions appear in the extension interleaved with yours, each line
prefixed with the guest's name. Viewers get their own controls in the
extension's settings menu (the gear):

- **Co-Streamer Captions** — show or hide guest captions entirely. It's on by
  default, and the choice is remembered between visits.
- Watching your captions **translated** into another language? Guest captions
  aren't translated (they show in the guest's original language), so
  translated viewers get an extra choice: see guests' original text mixed in,
  or hide guests while translated.

## Guest captions on your OBS overlay

If you use the [caption overlay](caption-overlay-user-guide.md) as a browser
source, guest captions appear there too, name-prefixed, with your configured
caption delay applied — no changes needed on your end.

## FAQ & troubleshooting

**My guest talks but nothing shows up for viewers.**
Check, in order: Are *you* captioning right now? (Guests pause when you're
not.) Is the master **Guest captions** switch ON? Is that guest muted? Is the
viewer on the latest extension version?

**Can guests use translations or pirate mode?**
No — guest captions are kept deliberately lightweight so several people can
caption at once without slowing anything down. Filters yes, extras no.

**Do guest captions get saved to my transcripts?**
No. Only your own captions are stored.

**My guest's captions are low quality.**
Speech recognition quality depends on their browser and mic. Chrome generally
does best; a headset mic beats a laptop mic; and picking the right spoken
language on the guest page matters more than people expect.

**How many guests can talk at once?**
Up to 4 active guest links, all of whom can caption simultaneously.

**I don't see the Co-stream Captions page.**
The feature is being rolled out gradually — if the page says it isn't enabled
for your account yet, hang tight.
