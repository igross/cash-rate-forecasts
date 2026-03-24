"""
Replicate IFM Investors' "RBA Cash rate expectations" chart.

Plots the actual RBA cash rate as a dark step-function line, overlays
successive ~18-month futures strips as light grey/taupe lines, and
highlights the latest futures strip in orange with the endpoint annotated.
"""

import warnings
warnings.filterwarnings("ignore")

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.ticker as mticker
from datetime import datetime, timedelta
import pyreadr

# =============================================================================
# 1) Load futures data
# =============================================================================
rds = pyreadr.read_r("combined_data/all_data.Rds")
futures = list(rds.values())[0]

futures["date"] = pd.to_datetime(futures["date"])
futures["scrape_date"] = pd.to_datetime(futures["scrape_date"])

# Keep one observation per (scrape_date, contract expiry month)
futures = (
    futures.sort_values("scrape_date")
    .groupby(["scrape_date", "date"])
    .last()
    .reset_index()
)

# =============================================================================
# 2) Historical actual RBA cash rate (target rate changes since 2015)
# =============================================================================
# Source: RBA official target rate changes
rate_changes = [
    ("2015-02-04", 2.25),
    ("2015-05-06", 2.00),
    ("2016-05-04", 1.75),
    ("2016-08-03", 1.50),
    ("2019-06-05", 1.25),
    ("2019-07-03", 1.00),
    ("2019-10-02", 0.75),
    ("2020-03-04", 0.50),
    ("2020-03-20", 0.25),
    ("2020-11-04", 0.10),
    ("2022-05-04", 0.35),
    ("2022-06-08", 0.85),
    ("2022-07-06", 1.35),
    ("2022-08-03", 1.85),
    ("2022-09-07", 2.35),
    ("2022-10-05", 2.60),
    ("2022-11-02", 2.85),
    ("2022-12-07", 3.10),
    ("2023-02-08", 3.35),
    ("2023-03-08", 3.60),
    ("2023-05-03", 3.85),
    ("2023-06-07", 4.10),
    ("2023-08-08", 4.10),  # hold
    ("2023-11-08", 4.35),
    ("2025-02-18", 4.10),
    ("2025-04-01", 3.85),  # latest known
]

actual = pd.DataFrame(rate_changes, columns=["date", "rate"])
actual["date"] = pd.to_datetime(actual["date"])

# Extend to today so the step line continues
last_date = pd.Timestamp("2026-03-24")
actual = pd.concat(
    [actual, pd.DataFrame({"date": [last_date], "rate": [actual["rate"].iloc[-1]]})],
    ignore_index=True,
)

# =============================================================================
# 3) Sample futures strips — one per month (mid-month preference)
# =============================================================================
scrape_dates_sorted = sorted(futures["scrape_date"].unique())

# Group scrape dates by year-month, pick one near mid-month
scrape_df = pd.DataFrame({"scrape_date": scrape_dates_sorted})
scrape_df["ym"] = scrape_df["scrape_date"].values.astype("datetime64[M]")
scrape_df["day"] = scrape_df["scrape_date"].dt.day

sampled_scrapes = (
    scrape_df.assign(dist=lambda d: (d["day"] - 15).abs())
    .sort_values("dist")
    .groupby("ym")
    .first()
    .reset_index()["scrape_date"]
    .tolist()
)

# Also always include the latest scrape
latest_scrape = max(scrape_dates_sorted)
if latest_scrape not in sampled_scrapes:
    sampled_scrapes.append(latest_scrape)

# =============================================================================
# 4) Build the plot
# =============================================================================
fig, ax = plt.subplots(figsize=(10, 6.5))

# Background colour — white
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

# --- Plot old futures strips (grey/taupe) ---
for sd in sorted(sampled_scrapes):
    strip = futures[futures["scrape_date"] == sd].sort_values("date")
    if strip.empty:
        continue
    # Only keep ~18 months forward from scrape date
    strip = strip[strip["date"] <= sd + pd.DateOffset(months=18)]
    if len(strip) < 2:
        continue
    if sd == latest_scrape:
        continue  # plot latest separately
    ax.plot(
        strip["date"],
        strip["cash_rate"],
        color="#b5a99a",   # taupe/grey matching IFM style
        linewidth=0.7,
        alpha=0.55,
        zorder=1,
    )

# --- Plot latest futures strip (orange) ---
latest_strip = futures[futures["scrape_date"] == latest_scrape].sort_values("date")
latest_strip = latest_strip[
    latest_strip["date"] <= latest_scrape + pd.DateOffset(months=18)
]
if not latest_strip.empty:
    ax.plot(
        latest_strip["date"],
        latest_strip["cash_rate"],
        color="#e8731a",  # IFM orange
        linewidth=3,
        zorder=3,
        solid_capstyle="round",
    )
    # Annotate endpoint
    end_rate = latest_strip["cash_rate"].iloc[-1]
    end_date = latest_strip["date"].iloc[-1]
    ax.annotate(
        f"{end_rate:.2f}%",
        xy=(end_date, end_rate),
        xytext=(15, 0),
        textcoords="offset points",
        fontsize=12,
        fontweight="bold",
        color="#e8731a",
        va="center",
        bbox=dict(
            boxstyle="round,pad=0.3",
            facecolor="white",
            edgecolor="#e8731a",
            linewidth=1.5,
        ),
    )

# --- Plot actual cash rate (dark teal step line) ---
ax.step(
    actual["date"],
    actual["rate"],
    where="post",
    color="#1a6e6e",  # dark teal matching IFM
    linewidth=2,
    zorder=2,
)

# =============================================================================
# 5) Styling to match IFM chart
# =============================================================================

# Axis limits
ax.set_xlim(pd.Timestamp("2015-01-01"), pd.Timestamp("2027-06-01"))
ax.set_ylim(-0.1, 5.5)

# Y-axis
ax.yaxis.set_major_locator(mticker.MultipleLocator(0.5))
ax.yaxis.set_major_formatter(mticker.FormatStrFormatter("%.1f"))
ax.set_ylabel("%pa", fontsize=12, rotation=0, labelpad=20, va="top", ha="right")
ax.yaxis.set_label_coords(-0.02, 1.02)

# X-axis — year labels only
ax.xaxis.set_major_locator(mdates.YearLocator())
ax.xaxis.set_major_formatter(mdates.DateFormatter("'%y"))

# Grid — light horizontal lines only
ax.grid(axis="y", color="#e0e0e0", linewidth=0.5)
ax.grid(axis="x", visible=False)

# Spines
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.spines["left"].set_color("#cccccc")
ax.spines["bottom"].set_color("#cccccc")

# Tick styling
ax.tick_params(axis="both", which="both", length=0, labelsize=11, colors="#555555")

# Title
ax.set_title(
    "RBA Cash rate expectations*",
    fontsize=16,
    fontweight="bold",
    loc="left",
    pad=15,
    color="#2b2b2b",
)

# Annotations matching IFM style
ax.text(
    pd.Timestamp("2023-06-01"),
    5.15,
    "RBA cash rate\n& futures pricing",
    fontsize=10,
    fontstyle="italic",
    fontweight="bold",
    color="#2b2b2b",
    ha="center",
)

ax.text(
    pd.Timestamp("2018-06-01"),
    2.9,
    "*Successive 18 month\n  futures strips",
    fontsize=9,
    fontstyle="italic",
    color="#b5a99a",
    ha="center",
)

# Source & branding
ax.text(
    0.0,
    -0.08,
    "Source: ASX, Bloomberg",
    transform=ax.transAxes,
    fontsize=8,
    color="#999999",
    ha="left",
)

plt.tight_layout()
plt.savefig("docs/rba_cash_rate_expectations.png", dpi=300, bbox_inches="tight")
plt.savefig("docs/rba_cash_rate_expectations.pdf", dpi=300, bbox_inches="tight")
print("Saved to docs/rba_cash_rate_expectations.png")
