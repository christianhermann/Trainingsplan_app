# UI Guidelines

## Design goals

The UI should feel dark, modern, clean, and mobile-first.
The main job of the interface is to make workout execution and logging fast.
Large numbers, clear card structure, and minimal friction matter more than decorative elements.

## Workflow priority

The workbook is built around recurring workout rows that show weight, reps per normal set, rep-out target, set goal, last-set performance, video, and notes. 
That means the app UI should prioritize fast reading of prescription data and fast entry of performed data. 

## Main screens

Use these main screens:
- Setup
- Today Workout / Timer
- History
- Settings

This matches the intended app structure and supports the workbook flow from configuration to execution to review.

## Setup screen

The Setup screen should allow:
- frequency selection
- training max entry
- auxiliary lift selection
- rounding configuration
- program generation
- program reset

The workbook’s Quick Setup area includes maxes, auxiliary choices, and setup-style control values, so this screen should feel structured rather than generic. 

## Today Workout screen

This is the highest-priority screen.

It should show:
- week and day header
- current lift name
- working weight in large type
- reps per normal set
- rep-out target
- set goal
- last-set logging input
- notes input
- video link input
- finish / complete action

Those fields come straight from the workout rows repeated across the workbook sheets. 

## Timer behavior

The timer should always be easy to reach from the active workout screen.
It should not hide the current exercise prescription.
Rest timing is a support tool, not the center of the page.

## Card hierarchy

Use a clear hierarchy:
- primary lift card first
- secondary lift cards after
- accessory cards last

Main lifts should read as more important than auxiliary or accessory work because the workbook is organized around named main-lift and auxiliary-lift progressions. 

## Input patterns

Recommended input patterns:
- numeric keypad for reps and weight
- one-tap completion states
- persistent notes field
- optional video link field
- swipe or button-based next-exercise flow

Avoid dense tables on mobile.
Use vertically stacked cards instead.

## History screen

The History screen should support:
- session list
- session detail
- lift detail
- visible last-set results
- notes and video history
- progression change visibility

The workbook stores last-set performance and notes directly in training rows, so those should remain visible in history rather than hidden in secondary menus. 

## Settings screen

The Settings screen should include:
- units
- rounding options
- timer defaults
- theme options
- import/export hooks
- reset actions

## Visual style

Recommended style:
- dark background
- high contrast text
- muted secondary text
- one accent color for action states
- rounded cards
- consistent spacing
- large tap targets

Avoid:
- tiny fonts
- spreadsheet-like cramped layouts
- too many charts on the home screen
- deep nested menus
- flashy gradients that reduce readability

## Accessibility

Support:
- large text scaling
- readable color contrast
- haptic confirmation for key logging actions
- buttons that are easy to tap mid-workout

The app should still feel efficient when used with one hand between sets.