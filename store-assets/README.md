# Play Store assets

Design: deep green (#005A36) background — Invois's brand primary — with a
white receipt mark (3 line-item bars, torn-paper bottom edge) and an emerald
(#10B981) checkmark badge signaling "paid/complete". No text baked into the
launcher icon itself, per Play Store guidance (icons with text scale badly).

## Files here (upload directly to Play Console)
- `play_store_icon_512.png` — 512x512, fully opaque, no transparency. This is
  the app icon shown on your Play Store listing page.
- `feature_graphic.png` — 1024x500. Shown at the top of your store listing.

## Already wired into the app (no action needed)
- `android/app/src/main/res/mipmap-*/ic_launcher.png` — legacy launcher icon,
  every density (mdpi through xxxhdpi).
- `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png` +
  `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` +
  `android/app/src/main/res/values/colors.xml` — adaptive icon (Android 8+),
  foreground content kept inside the safe zone so it survives circle/squircle/
  rounded-square launcher masks without clipping (verified programmatically).

## Still needed — screenshots
Screenshots need to come from a real device running the actual app (Play
Store reviews for authenticity, and mockups don't do the real UI justice).
Play Store requires at minimum 2 phone screenshots, 16:9 or 9:16, JPEG or
24-bit PNG, 320px–3840px on the long edge. Once v1.2.1 is installed, send
screenshots of: Dashboard, the invoice wizard, and Products — I can then
frame/polish them (device bezel, consistent crop) into upload-ready assets.
