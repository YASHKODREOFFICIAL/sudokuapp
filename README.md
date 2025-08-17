# Sudoku Game App - Flutter Implementation

## Overview
A feature-rich Sudoku game application built with Flutter that offers daily challenges, statistics tracking, and an intuitive gameplay experience.

## Features
- 🎮 **Daily Challenges**: New puzzle every day
- 🧩 **Random Puzzles**: Unlimited gameplay
- 📊 **Statistics Tracking**: Wins and failures
- 🎨 **Dark Theme**: Easy on eyes
- 🚦 **Smart Validation**: Real-time error checking
- ⏱ **Attempt Counter**: 10-attempt limit per puzzle

## Installation
```bash
git clone https://github.com/your-username/sudoku-flutter.git
cd sudoku-flutter
flutter pub get

Puzzle Data Format
Create assets/puzzles.json with:

[
  {
    "default": [
      [null,4,null,null,null,null,null,1,7],
      [null,2,null,4,5,null,null,null,null],
      [7,8,null,1,3,6,null,4,5],
      [null,1,4,3,6,5,null,null,8],
      [null,5,null,2,null,8,null,6,4],
      [null,null,8,7,null,null,5,null,null],
      [null,3,1,5,null,2,null,null,6],
      [8,null,2,null,7,3,4,null,null],
      [9,7,5,null,null,null,null,3,null]
    ],
    "solution": [
      [5,4,6,8,2,9,3,1,7],
      [1,2,3,4,5,7,6,8,9],
      [7,8,9,1,3,6,2,4,5],
      [2,1,4,3,6,5,7,9,8],
      [3,5,7,2,9,8,1,6,4],
      [6,9,8,7,1,4,5,2,3],
      [4,3,1,5,8,2,9,7,6],
      [8,6,2,9,7,3,4,5,1],
      [9,7,5,6,4,1,8,3,2]
    ]
  }
]


Game Mechanics
Controls:

Tap cells to select
Use number pad to input values
Erase button removes entries
Reset restarts puzzle
New Game loads random puzzle

Win Conditions:

Complete puzzle correctly
Recorded in statistics

Failure Conditions:

10 incorrect attempts
Puzzle marked as failed


Technical Implementation

Flutter Framework: UI implementation

JSON Storage: Puzzle data and statistics
State Management: setState for UI updates
Path Provider: Local data persistence

Screens
Home: Game entry point
Daily Game: Calendar-based selection
Puzzle: Main gameplay  
Statistics: Performance tracking
