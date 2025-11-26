# Mental Health Monitor (Flutter)

A cross-platform Flutter application designed to estimate user stress levels through device sensors (camera, optional audio, interaction patterns) and provide insights, history logs, and user-centric guidance. This repository contains a clean and extensible codebase structured for modular development, privacy-focused data flow, and easy ML model integration.

---

## 🔍 Overview

**Mental Health Monitor** enables:
- Real-time stress score estimation  
- Camera-based facial analysis pipeline (extensible to ML models)  
- Local-only data processing by default  
- History tracking and visual trend analysis  
- Minimalistic, scalable architecture for future model upgrades  

This project provides the mobile framework and data pipeline, letting you plug in your own ML models (TFLite/ONNX/Remote API).

---

## 🧩 Features

### ✔ Core
- Live camera preview (Flutter `camera` plugin)
- Stress inference hook (replaceable with real models)
- Local session storage (Hive / SQLite)
- Stress logs + weekly/monthly trends
- Cross-platform support: **Android, iOS, Web, Linux, macOS, Windows**

### ✔ Privacy-first
- No data leaves the device unless explicitly opted-in  
- Clear consent flows  
- Local deletion + user-controlled export  

### ✔ Extensibility
- Pluggable inference layer  
- Supports TFLite or server-side inference  
- Clear separation of UI, logic, and services  

---

## 📁 Project Structure

Mental_Health_Monitor/
├── lib/
│ ├── main.dart
│ ├── ui/ # Screens (Home, Dashboard, History, Settings)
│ ├── services/ # Camera, Model inference, Local DB
│ ├── models/ # App-level data models
│ ├── utils/ # Helpers, constants
│
├── assets/
│ ├── models/ # ML models (TFLite, etc.)
│ └── screenshots/
│
├── docs/
│ ├── 01-overview.md
│ ├── 02-features.md
│ ├── 03-architecture.md
│ └── 04-privacy.md
│
├── .github/
│ ├── CONTRIBUTING.md
│ └── ISSUE_TEMPLATE.md
│
├── .gitignore
├── LICENSE
└── README.md
