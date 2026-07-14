# dashboardbuilder

Build a **self-contained, interactive HTML dashboard from Stata** — tabs, line/bar/bullet charts, KPI tiles, a "choose a unit" selector dropdown with a reference overlay, per-panel CSV and PNG downloads, hover tooltips, an optional save-as-PDF button, callout and source boxes, and Texas 2036 or neutral theming. One command family, one output file, no internet required to view it.

```stata
sysuse census, clear
dashboardbuilder init  , title("State explorer") tx2036 selector(state) refvalue("United States")
dashboardbuilder tab   , name(today) label("Where states stand")
dashboardbuilder panel kpi     , values(pop medage) title("Headline numbers")
dashboardbuilder panel compare , x(metric) y(v) title("Vital rates vs. the US")
dashboardbuilder build using "state_explorer.html", replace pdf truepdf open
```

The output is deliberately a **starter wireframe**: all data is inline JSON, every chart is readable vanilla SVG/JS with `EDIT-ME` markers, and the Stata **build receipt** tells you what was built and what likely still needs a human pass.

## What it looks like

The two views below are the hand-built "Texas County Explorer" that this package generalizes. `dashboardbuilder` writes the same layout from your Stata data: a controls card with a unit selector and a tab bar, KPI tiles, readable SVG charts, per-panel download buttons, and a source footer. Your data and options decide which pieces appear.

**A line panel with KPI tiles and a metric selector.**

![Texas County Explorer, population-outlook tab: a controls card with a county dropdown set to "Texas (statewide)" and two tabs, then a card holding four KPI tiles, a "Show" dropdown set to "Total population", and a line chart of low, mid, and high population-projection scenarios from 2020 to 2060, with Data (CSV), Chart (PNG), and Save as PDF buttons.](images/example-projection.png)

The county dropdown chooses the unit; the in-panel "Show" dropdown switches the plotted metric; the three lines are the low, mid, and high projection scenarios. Each panel carries its own Data (CSV), Chart (PNG), and Save as PDF buttons. In `dashboardbuilder` terms this is `init , selector(county) tx2036`, a `panel kpi`, and a `panel line`, with the Save as PDF button added by `build , pdf`.

**Shared-scale bars measured against a reference unit.**

![Texas County Explorer, current-estimates tab: KPI tiles for Bastrop County (population 118,908, +22.3% growth, $82,730 income, 22.3% uninsured) above three bar panels (shares and rates, population growth, and dollars), each showing the county's orange bars with a navy peer-comparison marker on a shared scale, plus CSV and Save as PDF buttons.](images/example-current-estimates.png)

Here the reference is a peer group ("similar counties"). Each panel draws the selected county's bars (orange) with a peer marker (navy) on one shared scale, so bar lengths compare directly. In `dashboardbuilder` this is the `compare` panel: it places a `|` marker at the reference value, and the reference is ordinary data you build with `collapse` and `append` (the `state_explorer` example shows the pattern with a synthetic United States row).

## Why this shape

- **Builder grammar (putdocx-style).** Each `panel` call snapshots *the data currently in memory*, so you feed the dashboard one analytic subset at a time: `use`/`collapse`/`keep if`, capture a panel, load the next cut, capture the next panel.
- **Self-contained output.** No CDN, no external files, no server. Double-click to open; attach to email; drop on a shared drive; print to PDF.
- **A wireframe, not a walled garden.** The generated file is meant to be opened and tweaked. The receipt and inline comments point at the intended tweak points.

## Use cases

Reach for `dashboardbuilder` when you have a Stata result and want a shareable page a non-Stata reader can open, filter, and download from, without standing up a server or hand-writing HTML. Four shapes cover most Texas 2036 work, and each maps to a runnable dashboard in [`example_dashboardbuilder.do`](example_dashboardbuilder.do) and an example in `help dashboardbuilder`:

- **A unit explorer.** One page where the reader picks a county, district, campus, or region, and every panel re-renders for that unit against a statewide or peer benchmark. This is the "Texas County Explorer" pattern shown above. Start from the `state_explorer` dashboard (help example 2); the mechanism is the [selector](#the-selector-the-choose-a-county-pattern) with a `refvalue`.
- **A release companion.** A small dashboard that ships beside a data release or a memo so readers see the headline numbers and can pull the underlying rows as CSV. Start from `auto_quick` (help example 1), a KPI, bar, and table page you can build in a few lines.
- **A trend page.** A metric over time, often split across tabs, where different panels show different cuts of the series. Start from `lifeexp` (help example 3), which feeds a restricted subset (`keep if year>=1950`) to one panel so each panel embeds its own snapshot.
- **A survey or microdata summary.** Collapse microdata to group means, then chart the groups. Start from the optional `nhanes_bp` dashboard at the end of the example do-file.

Copy the closest dashboard and swap in your data. The help file's three numbered examples are the same code as the first three dashboards, so `help dashboardbuilder` and the do-file describe one workflow, not two.

## Layout it generates

Header (title/subtitle) → controls card (selector dropdown + tab bar + PDF button) → one card per panel (title, interpretation callout, CSV button, chart, legend, note) → callout box → source footer. This generalizes the hand-built "Texas County Explorer" prototype used with the *There is no average Texas* presentation.

## Panel types

| type | what it draws | key options |
|---|---|---|
| `kpi` | big-number tiles (one row of data) | `values(varlist)` |
| `line` | line chart, one line per y variable | `x() y(varlist)` |
| `bar` | vertical bars | `x() y()` |
| `hbar` | horizontal bars (rankings) | `x() y()` |
| `compare` | bullet bars with a reference marker, shared scale | `x() y() [ref()]` |
| `table` | plain table (first 500 rows; CSV has all) | `[vars()]` |

All types accept `tab() title() note() interp() ytitle()`.

## Downloads, tooltips, and opening

Self-contained and **on by default** (turn off with the `no*` switches):

- **Per-panel CSV** (`nocsv` to disable) — downloads the panel's rows, filtered to the current selection.
- **Per-panel PNG** (`nopng` to disable) — on the chart panels (line/bar/hbar/compare), which are SVG and rasterize in-browser with no library. kpi/table are HTML (browsers taint the canvas on HTML→PNG), so they keep CSV.
- **Hover tooltips** (`notooltip` to disable) — styled, and **no CDN/library required**.

PDF is opt-in, two flavors:

- `pdf` — a **Save as PDF** button using the browser's print-to-PDF. Fully offline.
- `truepdf` — a one-click **Download PDF** button. **Pulls `html2pdf.js` from a CDN**, so that button needs internet and won't work air-gapped (the rest of the dashboard still does); it degrades gracefully with a message when offline.

Opening: `open` launches the file in your browser when the build finishes. The receipt also prints clickable **open the dashboard** / **show its folder** links, and you can re-open the last build any time with `dashboardbuilder openlast` / `dashboardbuilder openfolder`.

## The selector (the "choose a county" pattern)

`init , selector(state) refvalue("United States")` gives the dashboard a dropdown. Any panel whose captured data contain a variable named `state` filters live; panels without it stay static (rename the column to opt a panel out on purpose). The `refvalue` unit is pinned to the top of the dropdown, overlays `line` panels as a dashed series, and supplies the `|` markers on `compare` panels. The reference unit is ordinary data — build it yourself with `collapse` + `append` (the example shows how).

## Install

From this folder (or a GitHub raw URL serving it):

```stata
net install dashboardbuilder, from("<path-or-url-to-this-folder>")
* or simply copy dashboardbuilder.ado + dashboardbuilder.sthlp to your PERSONAL adopath
help dashboardbuilder
```

Try it:

```stata
do example_dashboardbuilder.do    // builds 3-4 dashboards into ./dashboard_examples/
```

## Requirements

- **Stata 16+** (uses the built-in Python integration).
- **A Python 3 visible to Stata.** Standard library only (`json`, `os`) — **nothing to pip install, ever**. `dashboardbuilder init` checks and, if Stata cannot see Python, prints the exact fix:
  ```stata
  python search
  python set exec /usr/local/bin/python3, permanently    // Mac/Linux
  python set exec C:\Python312\python.exe, permanently   // Windows
  ```
- No other software. The generated HTML runs in any modern browser, offline.

## What the receipt watches for

Untitled panels; Stata-date x variables; panels embedding >2,000 rows (collapse first); tables >500 rows; KPI cards with >6 tiles; bars with >25 categories; selector declared but some panels static; missing `sourcenote()`; no `interp()` anywhere. Plus fixed reminders: search the file for `EDIT-ME`, and extend `fmtSmart()` for `$`/`%` formatting.

## Files

| file | purpose |
|---|---|
| `dashboardbuilder.ado` | the command (Stata orchestration + embedded Python engine + HTML template) |
| `dashboardbuilder.sthlp` | full help: syntax, options, selector semantics, troubleshooting, examples |
| `example_dashboardbuilder.do` | four worked dashboards from shipped datasets (`auto`, `census`, `uslifeexp`, optional `nhanes2`) |
| `stata.toc`, `dashboardbuilder.pkg` | `net install` plumbing |

## Notes and limits (v1)

- Data privacy: everything you capture is embedded in the file. Share the HTML only where you would share the data.
- Charts are wireframe-grade on purpose: no animations, and the smart number formatter is generic until you tell it about `$` or `%` (search the file for `fmtSmart`). Styled hover tooltips are on by default and need no library.
- One selector per dashboard; reference overlay applies to `line` and `compare` panels.
- Roadmap candidates: scatter panels, per-metric formats, a second reference (peer-median) toggle, small-count reliability flags.

## License

MIT. © Texas 2036 Data & Research (Eric Booth).
