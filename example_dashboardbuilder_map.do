*! example_dashboardbuilder_map.do — EXTENDED example
*! ----------------------------------------------------------------------------
*!  Embeds an interactive sparkta2 choropleth MAP inside a dashboardbuilder
*!  dashboard, using the -panel html- type. The map is built as a standalone,
*!  fully OFFLINE (self-contained) sparkta2 HTML file, then inlined into the
*!  dashboard via an <iframe srcdoc> — so the finished dashboard is still ONE
*!  self-contained file you can email or drop on a shared drive.
*!
*!  Requires: dashboardbuilder + a Python 3 visible to Stata (see -help
*!            dashboardbuilder-), AND sparkta2 (the map engine we embed).
*!  Run:      do example_dashboardbuilder_map.do
*! ----------------------------------------------------------------------------
version 16
clear all
set more off
capture mkdir "dashboard_examples"

* ---- require sparkta2 (the engine that draws the map we embed) ------------------
capture which sparkta2
if _rc {
    di as error "This extended example needs sparkta2 (the map engine). Install it once:"
    di as error `"  . net install sparkta2, from("https://raw.githubusercontent.com/ericabooth/sparkta2-stata/master/ado/") replace force"'
    di as error "Then re-run this do-file. (The other examples do not need sparkta2.)"
    exit
}

* ═══════════════════════════════════════════════════════════════════════════
* 1. County data. Load the 254 real Texas county names + FIPS (shipped next to
*    this do-file as texas_counties.csv) and attach a synthetic "readiness index"
*    so the demo has something to show. Swap in your own county dataset keyed by
*    5-digit FIPS to reuse this pattern with real numbers.
* ═══════════════════════════════════════════════════════════════════════════
capture findfile texas_counties.csv
if _rc {
    di as error "texas_counties.csv not found — run this from the package folder"
    di as error "(the file ships next to example_dashboardbuilder_map.do)."
    exit 601
}
import delimited "`r(fn)'", varnames(1) stringcols(2) clear   // fips (numeric), county (name)
set seed 2036
gen double readiness = 100*runiform()                 // synthetic 0-100 "readiness index"
gen double income    = 40000 + 35000*runiform()       // synthetic median household income
label var readiness "Workforce readiness index (0-100, synthetic)"
label var income    "Median household income (USD, synthetic)"
tempfile counties
save `counties'

* ═══════════════════════════════════════════════════════════════════════════
* 2. Build the choropleth as a STANDALONE, OFFLINE sparkta2 map.
*    -offline- inlines D3 + the Texas geography into the map file, so it has no
*    external dependencies — which is exactly what lets dashboardbuilder inline
*    it and keep the whole dashboard self-contained and offline-safe.
* ═══════════════════════════════════════════════════════════════════════════
tempfile mapfile
sparkta2 readiness, id(fips) name(county) geo(texas) type(choropleth) ///
    scheme(blues) title("Workforce readiness by county") ///
    offline noopen export("`mapfile'.html")

* ═══════════════════════════════════════════════════════════════════════════
* 3. Assemble the dashboard: the map on one tab, summary panels on another.
* ═══════════════════════════════════════════════════════════════════════════
use `counties', clear
dashboardbuilder init , title("Texas county readiness explorer") ///
    subtitle("a sparkta2 map embedded inside a dashboardbuilder dashboard (synthetic demo)") ///
    tx2036

dashboardbuilder tab , name(map)     label("Map")
dashboardbuilder tab , name(numbers) label("The numbers")

* -- the MAP: an external sparkta2 HTML file, inlined as an html panel ----------
dashboardbuilder panel html , tab(map) file("`mapfile'.html") height(760) ///
    title("Readiness index by county") ///
    interp("Darker counties score higher. This is a live sparkta2 D3 map (zoom/hover work) embedded in the card below.") ///
    note("Map drawn by sparkta2 (bundled D3 + Texas geography). Values are synthetic for illustration.")

* -- statewide KPI tiles (collapse to one row first) ----------------------------
preserve
    collapse (mean) readiness income
    dashboardbuilder panel kpi , tab(numbers) values(readiness income) ///
        title("Statewide averages") ///
        interp("Averages across all 254 counties in the synthetic dataset.")
restore

* -- highest-readiness counties (static ranking) --------------------------------
*    Show 30 (not a handful) so the reader sees the spread across real counties.
gsort -readiness
keep in 1/30
dashboardbuilder panel hbar , tab(numbers) x(county) y(readiness) ///
    title("Thirty highest-readiness counties") ytitle("readiness index (synthetic)")

* CSV/PNG/tooltips default on; the map panel shows neither (it embeds a file).
* -corner- floats the Save-as-PDF button in the bottom-right corner.
* Auto-open is on by default; pass -noopen- to suppress.
dashboardbuilder build using "dashboard_examples/county_map_dashboard.html", replace ///
    pdf corner ///
    callout("The values here are synthetic; the point of this example is the pattern: build any HTML (here a sparkta2 map) and drop it into a dashboard panel.") ///
    sourcenote("Demo data are synthetic. Map rendered by sparkta2; dashboard by dashboardbuilder (Texas 2036 Data & Research).")

di as res _n "done — county_map_dashboard.html embeds the sparkta2 map on the 'Map' tab."
