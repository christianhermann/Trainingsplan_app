# App Overview

## Purpose

This app converts an Excel-based strength training workbook into a native Flutter Android experience. 
The workbook already defines main lifts, auxiliary lifts, training maxes, weekly prescriptions, progression behavior, and workout logging fields, so the app should reproduce that logic rather than invent a new training system. 

## Core idea

The training plan is organized around a 21-week structure. 
It supports weekly frequency templates from 2x to 6x. 
Each workout row is centered on practical training data such as weight, reps per normal set, rep-out target, set goal, reps on last set, video, and notes. 

## Main entities

Primary lifts in the workbook are Squat, Bankdruecken, Deadlift, and Schulterdruecken. 
Auxiliary lifts include Leg Press, Wider Stance Squat, DB Bench, Incline DB Press, Trap Bar Deadlift, and DB Schulterdruecken. 
The workbook also includes additional accessory-style entries such as Latzug, Rudern, T-Bar Rudern, Bizeps Curls, and Trizeps Extension. 

## App screens

The mobile app should use these core screens:
- Setup
- Timer / Today Workout
- History
- Settings

These screens match the real workflow implied by the workbook: setup maxes and frequency, generate workouts, log results, and review prior sessions. 

## Product goals

The app should help a user:
- set or edit training maxes
- choose a weekly training frequency
- generate week and day workouts
- view working weights and targets
- log actual performance on the last set
- store notes and video references
- review training history
- carry progression logic forward

## Technical direction

The first version should be local-first and Android-first.
Use Flutter for UI, Riverpod for state, and Drift/SQLite for persistence.
All calculation logic should live in testable services, not inside widgets.

## Scope boundaries

This is not a generic workout tracker.
It is a workbook-to-app conversion project.
The MVP should focus on correctness of training logic, fast workout logging, and a clean mobile interface before adding advanced features like workbook import or cloud sync.