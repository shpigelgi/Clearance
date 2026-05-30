# Clearance

Clearance is a native macOS app for **monthly, zero-based cash-flow routing** — a deliberate end-of-month ritual for deciding where every shekel of income goes, confirming you "cleared" the month, and keeping an untouched historical record of each one.

> 📖 **New here? Read [ABOUT.md](ABOUT.md)** — a deep, jargon-free explanation of the
> problem Clearance solves, the way of thinking behind it, and exactly how you use it
> month to month (with a worked example). This README is the quick technical entry point.

## The problem it solves

Most budgeting apps track spending *after the fact* and lump everything into one running balance. Clearance is built around a different, intentional workflow:

1. **Income arrives** — either a fixed monthly figure or computed from the days you actually worked.
2. **Obligations come out** — rent and the month's actual card spend.
3. **What's left is the *buffer*** — the surplus you get to route on purpose, or the deficit you need to notice.
4. **Wealth is routed with intent** — you deliberately move money into named savings/investment funds and check each one off as you transfer it.
5. **The month is closed and preserved** — past months are a record, not a live balance. *"Route income with intent, then keep the historical record untouched."*

It answers one recurring question every month — **"Did I clear, and where did the surplus go?"** — and then shows whether that habit is compounding over time.

## What it actively does

### The Clearance Check
- Income entered directly, **or** calculated from `days worked × income-per-day` against a baseline.
- Rent and a customizable list of **card-spend categories**, each with a planned target and the actual amount spent.
- A live **Remaining Buffer** = effective income − rent − actual spend, shown as a state-reactive **Surplus** (green) or **Deficit** (red) figure.

### The Wealth Engine
- A customizable list of **routing funds** (e.g. an investment portfolio, an emergency fund, a car fund, a hobby fund), each with a target amount and a "transferred" checkbox.
- A **Month Routing** summary: effective income, planned vs. confirmed routing, and transfer progress.

### Growth Estimator
- Each fund carries its **own annual growth-rate** assumption.
- A 12-month projection compounds this month's targets per fund into a single projected value.

### Insights & Analytics
- A **Buffer Trend** chart across recent months (Swift Charts).
- **Rolling Spend Average** and **Wealth Velocity** (cumulative confirmed routing) metrics.

### Fully customizable categories
- **Add, remove, and rename** both spend categories and routing funds — per month, inline.
- A **Settings template** defines the default set of categories that every new month inherits; editing the template affects future months only, leaving existing months untouched.

### Built for the Mac
- `NavigationSplitView` sidebar of historical months; start a new month or add a specific past month.
- In-app **zoom** (⌘+ / ⌘− / ⌘0) that scales the whole interface.
- **JSON export** of all monthly reviews for a readable, portable local backup.
- **Liquid Glass** card surfaces on macOS 26+, with a graceful material fallback on earlier systems.
- Local-only **SwiftData** persistence — no CloudKit, no iCloud, no account.

## Install

1. Download the latest `Clearance-x.y.z.dmg` from the [Releases page](https://github.com/shpigelgi/Clearance/releases).
2. Open the DMG and drag **Clearance** into your **Applications** folder.
3. **First launch only** — because the app is free/ad-hoc-signed (not notarized through a paid Apple Developer account), macOS Gatekeeper blocks the first open. Either:
   - **Right-click** `Clearance.app` → **Open** → **Open** in the dialog, or
   - run `xattr -dr com.apple.quarantine /Applications/Clearance.app` in Terminal.

   You only do this once. After that it opens normally and Spotlight finds it like any app.

### Updates

Clearance updates itself. It checks for new releases automatically (about once a day and on launch), and you can check any time via **Clearance → Check for Updates…**. When a new version is available it downloads, verifies, and installs in place — no manual reinstall, and no Gatekeeper prompt on updates.

## Build from source

Open `Clearance.xcodeproj` in Xcode and run the `Clearance` scheme on macOS 14 or newer.

## UI tests

`ClearanceUITests` is an adversarial XCUITest suite that drives the real app against a throwaway in-memory store (so your data is never touched) and screenshots each step:

```sh
./run-ui-tests.sh
```

Screenshots and the result bundle land in `.qa-ui-review/`. The script keeps build output outside `~/Documents` to avoid the macOS Documents-access prompt.
