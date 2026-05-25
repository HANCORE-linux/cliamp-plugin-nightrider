# cliamp-plugin-nightrider

A dynamic, center-expanding spectrum visualizer for [cliamp](https://cliamp.stream). It features discrete bars that grow outward from the screen center, utilizing an intensity-based color gradient that shifts from white to red based on signal strength.

![Knightrider](showcase/preview.png)

## Install

```bash
cliamp plugins install [YOUR_GITHUB_USERNAME]/cliamp-plugin-nightrider
```

Start `cliamp` and press `v` to cycle through the visualizers until `nightrider` appears.

```sh
cliamp plugins remove nightrider
```
## Tuning

The plugin is a single Lua file. If you want to customize the visual behavior or aesthetics, you can edit the configuration directly in your local plugin file: `~/.config/cliamp/plugins/nightrider.lua`.

Below are the primary parameters you can modify:

| What | Where | Effect |
| :--- | :--- | :--- |
| **Color Scheme** | `COLORS` | Modify the ANSI escape sequences to match your terminal theme. |
| **Grid Density** | `for c = 1, cols, 2` | Change the step value (e.g., to `3`) to increase space between bars. |
| **Bar Symbols** | `local char = ...` | Swap `█` or `·` for different aesthetic markers. |

## How it works

`cliamp-plugin-nightrider` processes real-time audio bands provided by `cliamp`. It calculates an expansion radius based on bass intensity, causing the visualization to "bloom" from the center. Each bar uses an intensity-mapped gradient, ensuring that colors transition smoothly from the base to the peak regardless of the window size or signal amplitude.

## Requirements

* `cliamp` with Lua plugin support
* A terminal with 256-color ANSI support

## License

MIT - see [LICENSE](LICENSE).
