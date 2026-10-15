# Portfolio sliding underline

This Waybar CFFI v2 module draws one underline over the existing
`hyprland/workspaces` widget. The native module still handles workspace state,
clicks, scrolling, dynamically added workspaces, and monitor filtering.

The 300ms animation uses the portfolio's `cubic-bezier(0, .99, .62, 1.07)`.
Quick switches retarget from the current position. GTK's frame clock runs only
while the underline is moving. The module occupies no space in the bar and only
draws when the portfolio theme defines `portfolio_accent`.

Rebuild after editing the C source:

```sh
sh ~/.config/waybar/cffi/build.sh
```

Then restart Waybar. A configuration-only SIGUSR2 reload can retain the old
library in memory. Builds replace the library atomically so a running Waybar
can safely keep using its previous version until the restart.

Configure timing using `duration-ms` in `cffi/portfolio-underline` in the Waybar
config. Remove that module from `modules-left` to restore the native underline;
the theme keeps a fallback when the helper is absent.
