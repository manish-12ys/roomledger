# RoomLedger — Premium AMOLED UI/UX Redesign Plan

> Transform RoomLedger from a functional expense tracker into a premium financial workspace for roommates.

---

# Vision

RoomLedger should feel like:

- A premium fintech dashboard
- A modern SaaS workspace
- A calm and professional financial system
- A polished App Store-quality product

The redesign must focus on:

- Clarity
- Readability
- Trust
- Smoothness
- Premium interactions
- Modern visual hierarchy

---

# Design Direction

## Visual Identity

```txt
AMOLED Graphite + Soft Emerald + Matte Glass
```

### Design Mood

- Minimal
- Professional
- Futuristic
- Elegant
- Calm
- Premium

---

# Inspiration

The redesign should take inspiration from:

- Linear
- Apple Wallet
- Arc Browser
- Revolut
- Monzo
- Notion
- Modern investment dashboards
- Premium SaaS platforms

Avoid:

- Flashy crypto aesthetics
- Over-glowing UI
- Rainbow gradients
- Generic Material UI clones

---

# Tech Stack

## Frontend

- Flutter
- Material 3
- Responsive layouts
- Reusable widgets
- Scalable architecture

## Recommended Packages

```yaml
flutter_riverpod
go_router
flutter_animate
animations
google_fonts
fl_chart
isar
freezed
```

---

# Theme System

## AMOLED Background System

### Primary Background

```txt
#000000
```

### Layered Surfaces

```txt
Surface 1 → #0A0A0B
Surface 2 → #111113
Surface 3 → #17171A
Surface 4 → #1E1E22
```

These surfaces should create:

- subtle hierarchy
- depth
- softness
- reduced eye strain

---

# Accent System

## Primary Accent

```txt
#3DDC97
```

Use for:

- active states
- buttons
- progress
- highlights
- navigation
- graphs

---

## Secondary Accent

```txt
#8BA38F
```

Use subtly for:

- inactive states
- secondary charts
- muted emphasis

---

# Status Colors

```txt
Success → #4ADE80
Warning → #FBBF24
Danger  → #FB7185
Info    → #94A3B8
```

---

# Text Colors

```txt
Primary   → #FFFFFF
Secondary → #B3B3B8
Muted     → #7B7B84
Disabled  → #5A5A63
```

---

# Typography

## Font

```txt
Inter
```

Alternative:

```txt
SF Pro Display
```

---

## Typography Scale

```txt
Display Large → 36
Headline      → 28
Title          → 20
Body           → 15
Label          → 12
```

Typography should feel:

- clean
- balanced
- premium
- highly readable

---

# Radius System

```txt
Small  → 14
Medium → 22
Large  → 30
XL     → 38
```

---

# Shadow & Depth System

Use:

- soft shadows
- matte surfaces
- subtle highlights
- layered depth

Avoid:

- strong neon glows
- harsh borders
- excessive blur

---

# Navigation Redesign

## Floating Navigation Bar

Replace current bottom navigation with:

```txt
Floating pill navigation
```

### Tabs

- Home
- Shared
- Add
- Debts
- Profile

---

## Navigation Styling

```txt
Background   → #121214
Active Pill  → #232327
Active Icon  → #3DDC97
Inactive Icon→ #7B7B84
```

### Features

- glass effect
- floating elevation
- spring animations
- active pill transitions
- smooth icon animations

---

# Global UI System

All screens must use:

- large rounded corners
- layered surfaces
- soft gradients
- smooth animations
- proper spacing
- visual hierarchy
- matte styling

Avoid:

- flat gray rectangles
- inconsistent padding
- overly dense UI
- repetitive layouts

---

# Home Dashboard Redesign

## Goal

The home screen should feel:

- intelligent
- premium
- personalized
- alive

---

## Structure

### Top Header

Contains:

- greeting
- user profile
- current month
- subtle notification indicator

---

## Hero Finance Card

Main centerpiece of the screen.

### Contains

- total pending amount
- monthly spending
- repayment progress
- mini graph
- active roommates

### Style

- matte glass surface
- subtle emerald tint
- soft depth
- animated graph lines

---

## Quick Actions

Convert actions into:

- modern icon grid
- tactile buttons
- neumorphic/glass hybrid

### Actions

- Add Expense
- Record Repayment
- Analytics
- Roommates
- Backup
- Alerts

---

## Smart Insights

Examples:

```txt
"Sai has overdue repayments"
"Spending increased 18%"
"You settled 3 debts this week"
```

Insights should feel:

- contextual
- elegant
- AI-assisted

---

## Recent Activity

Use:

- grouped timeline
- swipe gestures
- compact rows
- status chips

---

# Shared Expenses Redesign

## Goal

Make expense tracking:

- faster to scan
- cleaner
- visually organized

---

## Layout

### Timeline Grouping

```txt
Today
Yesterday
Earlier
```

---

## Expense Tile

Contains:

- avatar
- title
- amount
- payment status
- timestamp
- category
- owed user

---

## Interactions

### Swipe Right

```txt
Mark Paid
```

### Swipe Left

```txt
Edit / Delete
```

### Long Press

Open action bottom sheet.

---

# Debts Screen Redesign

## Goal

Transform debts into:
> visual financial summaries

---

## Debt Card

Contains:

- roommate profile
- pending amount
- repayment %
- circular progress
- last repayment
- pending count

---

## Design Improvements

Use:

- compact cards
- progress rings
- mini charts
- grouped hierarchy

---

# Debt Detail Screen

## Goal

Feel:

- premium
- detailed
- financial
- trustworthy

---

## Layout

### Top Summary Card

Contains:

- roommate
- debt title
- total amount
- remaining amount
- created date

---

## Progress Section

Features:

- repayment progress animation
- milestone indicators
- payment labels

---

## Timeline

Replace plain rows with:

- settlement timeline
- repayment history
- payment chips
- timestamps

---

## Floating Action Button

```txt
Record Payment
```

Use:

- extended FAB
- morph animations
- spring transitions

---

# Personal Expenses Redesign

## Goal

Create a cleaner personal finance experience.

---

## Features

- monthly summary
- category trends
- expense analytics
- spending graphs
- grouped expenses
- smart insights

---

# Analytics Screen Redesign

## Goal

This should become the:
> showcase screen of the app

Most visually advanced screen.

---

# Analytics Sections

## Spending Overview

- total spending
- shared spending
- personal spending

---

## Trend Graph

Interactive animated graph.

---

## Donut Breakdown

Elegant category visualization.

---

## Category Analysis

Animated bars and percentages.

---

## Friend Comparison

Debt comparison cards.

---

## Smart Insights

Financial summaries and patterns.

---

# Chart Design Rules

Use:

- emerald
- olive
- amber
- slate
- silver

Avoid:

- rainbow dashboards
- overly colorful charts
- crypto-style graphs

---

# Roommates Screen Redesign

## Goal

Make roommates feel like:
> financial profiles

---

## Roommate Cards

Contains:

- avatar
- join date
- total owed
- repaid amount
- pending amount
- trust score

---

## Features

- expandable cards
- swipe gestures
- animated bottom sheets
- context menus

---

# Drawer / Side Panel

## Style

- matte glass
- grouped sections
- premium spacing
- smooth transitions

---

## Include

- Dashboard
- Analytics
- Roommates
- Settings
- Backup
- Export
- Theme Preferences

---

# Component System

## Core Components

- AppScaffold
- FloatingNavbar
- GlassCard
- AppButton
- AnimatedFAB

---

## Finance Components

- DebtCard
- ExpenseTile
- ProgressRing
- FinanceSummaryCard

---

## Analytics Components

- ChartContainer
- InsightCard
- AnalyticsSummary

---

## Utility Components

- BottomSheet
- SectionHeader
- EmptyState
- LoadingSkeleton

---

# Motion System

## Required Animations

### Navigation

- shared axis transitions
- fade-through motion

---

### Components

- spring animations
- ripple feedback
- animated counters
- chart animations

---

### Gestures

- swipe physics
- drag interactions
- FAB morphing

---

# Microinteractions

Add:

- smooth haptics
- animated toggles
- hover feedback
- shimmer loading
- gesture animations
- progress animations

---

# Layout Improvements

Improve:

- spacing consistency
- visual grouping
- readability
- section hierarchy
- scrolling experience

Reduce:

- repetitive layouts
- oversized cards
- empty space overload

---

# Performance Requirements

The redesign must:

- maintain 60fps+
- minimize overdraw
- optimize rebuilds
- support lazy loading
- use efficient animations
- support AMOLED optimization

---

# Responsiveness

Support:

- phones
- tablets
- foldables
- landscape mode

---

# Accessibility

Support:

- scalable text
- readable contrast
- semantic labels
- accessible touch targets

---

# Final Experience Goal

RoomLedger should ultimately feel like:

```txt
A premium financial operating system
for roommate expense management.
```

The final product should communicate:

- trust
- clarity
- quality
- smoothness
- professionalism
- modernity

Every screen should feel:

- intentional
- balanced
- refined
- elegant
- production-ready

```
