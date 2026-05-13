# RoomLedger UI/UX Redesign — Next Steps

This file captures the next priorities for implementing the premium AMOLED redesign described in `UI_UX_REDESIGN_PLAN.md`.

## 1. Establish the global design system

- [ ] Define AMOLED theme tokens for colors, text, surfaces, radius, and shadows
- [ ] Implement a shared theme provider using Flutter `ThemeData` / Material 3
- [ ] Create reusable surface widgets for matte glass, layered cards, and soft elevation
- [ ] Add global typography styles using `Inter` (or `SF Pro Display` fallback)
- [ ] Ensure spacing, padding, and visual hierarchy are consistent across screens

## 2. Build the new navigation experience

- [ ] Replace existing navigation with a floating pill-style bottom bar
- [ ] Add tabs: Home, Shared, Add, Debts, Profile
- [ ] Implement active pill transitions and smooth icon animations
- [ ] Add subtle glass-style background and floating elevation styling
- [ ] Validate responsive layout for portrait and tablet widths

## 3. Redesign the Home Dashboard

- [ ] Create the top header with greeting, profile, month, and notification indicator
- [ ] Build the hero finance card with total pending amount, monthly spending, progress, mini graph, and roommate avatars
- [ ] Add quick action buttons for: Add Expense, Record Repayment, Analytics, Roommates, Backup, Alerts
- [ ] Add a smart insights section with contextual messages and premium styling
- [ ] Implement a recent activity timeline with grouped sections and swipe/compact row behavior

## 4. Redesign shared expenses

- [ ] Convert the shared expenses screen into a clean timeline layout: Today / Yesterday / Earlier
- [ ] Build an expense tile with avatar, title, amount, payment status, timestamp, category, and owed user
- [ ] Add swipe gestures: right to mark paid, left to edit/delete
- [ ] Support long press to open an action bottom sheet
- [ ] Polish interactions with soft motion and grouped surface hierarchy

## 5. Redesign debts screens

- [ ] Create a debt summary screen with compact debt cards
- [ ] Add roommate profile, pending amount, repayment percentage, progress ring, last repayment, and pending count to each card
- [ ] Add mini charts or progress visuals for each debt
- [ ] Build a detailed debt screen with top summary card, repayment progress animation, milestones, and payment labels
- [ ] Ensure the screen feels premium, trustworthy, and easy to scan

## 6. Product polish and quality

- [ ] Audit current app screens against the redesign vision
- [ ] Remove or refactor dated Material UI-like layouts
- [ ] Add smooth animations and transitions with `flutter_animate` / `animations`
- [ ] Validate color accessibility and readability on AMOLED
- [ ] Write small UI-focused tests for the key redesigned screens

## 7. Implementation checklist for stage 1

- [ ] Complete theme system and reusable UI components
- [ ] Update app navigation and baseline scaffold
- [ ] Ship redesigned home dashboard first
- [ ] Build shared expenses screen next
- [ ] Complete debts screen redesign
- [ ] Review and refine based on the premium visual direction

## Notes

This list is meant to be a practical developer checklist to move the redesign from concept into code. Adjust priorities as implementation reveals new dependencies or opportunities.
