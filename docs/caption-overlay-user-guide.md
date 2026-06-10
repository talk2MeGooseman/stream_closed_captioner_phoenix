# Showing Your Captions On Stream: The Caption Overlay

The caption overlay is a personal web page that displays your live captions over a transparent background. Add it to OBS (or any streaming tool that supports browser sources) and your captions appear right on your stream — styled however you like, visible to every viewer, no Twitch extension required.

## Getting your overlay URL

1. Open the **Caption Settings** page in your Stream Closed Captioner dashboard.
2. Find the **OBS Caption Source** card. It shows your personal overlay URL.
3. Click **Copy** to copy the URL.

Your URL contains a private token that is unique to you. Treat it like a password for your captions — anyone with the URL can watch your live captions.

### Regenerating your URL

If your URL ever leaks (for example, it appeared on stream), click **Regenerate** on the same card to get a fresh one.

> **Warning:** Regenerating immediately invalidates your old URL *everywhere you've pasted it* — OBS browser sources, bookmarks, anywhere. After regenerating, you must update OBS with the new URL. A stale URL is the most common reason captions "silently stop showing." If that happens, the overlay page shows a notice telling you the URL is no longer valid, so check your OBS source for that message first.

## Adding the overlay to OBS

1. In OBS, click **+** under *Sources* and choose **Browser**.
2. Name it something like "Captions" and click OK.
3. Paste your overlay URL into the **URL** field.
4. Set a size — **Width 800, Height 200** is a good starting point for a caption strip. Any size works; captions always sit at the **bottom** of the source, so place the source where you want your captions to appear.
5. Click OK. The background is transparent — you'll only see the caption box when captions are coming through.

Start captioning from your dashboard as usual, and your words appear in the overlay.

## Customizing how your captions look

You don't have to touch the URL by hand — there's a built-in settings tool:

1. Open your overlay URL in a normal browser tab (Chrome, Firefox, Safari…).
2. Click the **gear button** in the top-right corner.
3. A settings panel opens, and the caption box fills with **sample text** so you can see every change instantly — no need to be live or speaking.
4. Adjust font size, colors, opacity, alignment, lines, font, and uppercase. The **page URL updates live** as you change settings, and so does the **Copy URL field** at the bottom of the panel.
5. When it looks right, click **Copy** (or copy the address bar) and paste that URL into your OBS browser source.

Close the panel (✕) and the sample text disappears; your real captions take over.

The gear button only appears in normal browsers — inside OBS it stays hidden automatically. If you want it guaranteed off on stream (the automatic hiding can briefly flash the gear when a browser source reloads, such as on scene switches), add `settings=0` to the URL in your OBS source.

## Appearance settings reference

All appearance options live in the URL as `name=value` pairs after the `?`, separated by `&` — for example:

```
…/captions/YOUR-TOKEN?font_size=48&align=center&bg_opacity=50
```

Anything you leave out uses its default. Out-of-range numbers are clamped to the nearest allowed value.

| Setting      | What it does                              | Allowed values                                   | Default |
| ------------ | ----------------------------------------- | ------------------------------------------------ | ------- |
| `font_size`  | Caption text size in pixels               | 10–120                                           | 32      |
| `color`      | Text color (hex code, no `#` needed)      | 3 or 6 digit hex, e.g. `FFD700` or `FD0`         | `FFFFFF` (white) |
| `bg`         | Caption box background color (hex code)   | 3 or 6 digit hex                                 | `000000` (black) |
| `bg_opacity` | How opaque the caption box is, in percent | 0 (invisible) – 100 (solid)                      | 70      |
| `align`      | Text alignment inside the box             | `left`, `center`, `right`                        | `left`  |
| `uppercase`  | Show all text in CAPITALS                 | `true`, `false`                                  | Follows your account's text-uppercase setting |
| `lines`      | How many lines of text stay visible       | 1–10                                             | 3       |
| `font`       | Typeface style                            | `sans`, `serif`, `mono`                          | `sans`  |

## The `settings` switch

One extra option controls the settings tool itself:

| URL contains   | Behavior                                                                  |
| -------------- | ------------------------------------------------------------------------- |
| *(nothing)*    | Automatic: gear shows in normal browsers, hidden inside OBS               |
| `settings=1`   | Gear is always available — even inside OBS, so you can tweak the overlay by interacting with the browser source directly |
| `settings=0`   | Gear is always hidden, everywhere                                          |

Tip: if you use `settings=1` to style your overlay from inside OBS, remember to remove it before going live — the copied URL keeps `settings=1` while you're using it. Delete `settings=1` from the URL in your OBS source, or simply add `settings=0` to the end of the URL (it wins over an earlier `settings=1`).

## Caption delay

If you've set a caption delay with the **Caption delay** control on the **Caption Settings** page (for example, to sync captions with your stream's broadcast delay), the overlay honors it: captions appear in the overlay that many seconds after you speak, matching what your viewers see.

## Troubleshooting

**Captions aren't appearing in the overlay**
- Open the overlay URL in a browser. If you see a *"this caption source URL is no longer valid"* notice, the URL was regenerated — copy the current one from the OBS Caption Source card and update OBS.
- Make sure you're actually captioning: the dashboard must be open with captions running for text to flow.
- If you use a caption delay, wait it out — captions arrive that many seconds late by design.

**The gear button doesn't show in my browser**
- Check the URL for `settings=0` and remove it.

**The gear button is showing on my stream**
- Your OBS URL probably contains `settings=1`. Re-copy the URL without it, or add `settings=0` to force the gear off.

Happy streaming!
