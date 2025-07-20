# Architecture

This section describes the overall structure of EndoscopeAI.

## Tech Stack
- **Flutter** for the cross-platform UI
- **Dart** as the main language
- **Rust** module for YOLO inference via flutter_rust_bridge
- **Python** for the speech-to-text server

## Static View
The static dependencies between major modules are shown in the diagram:
![Static View](static-view/diagram.mmd)

## Dynamic View
This sequence illustrates how a doctor annotates a screenshot:
![Dynamic View](dynamic-view/diagram.mmd)

## Deployment View
The application runs entirely on the doctor's workstation:
![Deployment View](deployment-view/diagram.mmd)
