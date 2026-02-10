# Project Blueprint: Marine Survey Logger

## Overview

Marine Survey Logger is a Flutter application designed for marine biologists and researchers to efficiently collect and manage survey data in the field. The app provides a streamlined data entry process, integrates with the device's hardware for location and photo capture, and ensures data is stored securely and can be easily exported.

## Style, Design, and Features

### Implemented Features (v1.0)

*   **Core:**
    *   **Cross-Platform:** Built with Flutter for iOS, Android, and Web.
    *   **State Management:** Using `provider` for robust and scalable state management.
    *   **Dependency Injection:** Leveraging `provider` for dependency injection of services like the database.
*   **UI/UX:**
    *   **App Name:** Marine Survey Logger
    *   **Language:** The user interface is in French.
    *   **Theme:** Modern, clean theme with a professional color palette suitable for scientific work.
    *   **Layout:** A scrollable main screen to accommodate all data entry fields.
*   **Data Entry & Capture:**
    *   **Data Entry Form:** A comprehensive form with fields for:
        *   `site`
        *   `species`
        *   `Latitude`
        *   `Longitude`
        *   `Temperature`
        *   `pH`
        *   `O2 dissous` (Dissolved Oxygen)
        *   `Sexe` (Sex)
        *   `standard length`
        *   `total length`
        *   `Id_photos`
        *   `remarks`
    *   **Location Services:**
        *   Automatic capture of Latitude and Longitude using the device's GPS.
        *   Manual override for coordinates.
    *   **Photo Capture:**
        *   A 2x3 grid of buttons for different photo angles (LG, LD, D, V, TF, C).
        *   Opens the device camera on button tap.
        *   Saves images with a standardized filename: `SITE_species_YYYYMMDD_IDphoto_VUE.jpg`.
        *   Displays thumbnails of captured photos in the grid.
*   **Data Management:**
    *   **Database:** On-device storage using an SQLite database via the `sqflite` package.
    *   **Photo Linking:** Stores references to captured photos as a JSON object within each observation record.
    *   **Data Export:** A feature to export the entire SQLite database and all associated images as a single ZIP file.

## Current Task: Initial Project Setup and UI

**Plan:**

1.  **Add Dependencies:** Add `provider`, `google_fonts`, `sqflite`, `image_picker`, `geolocator`, `path_provider`, and `archive` to `pubspec.yaml`.
2.  **Initial UI:**
    *   Modify `lib/main.dart` to create the main application structure.
    *   Implement a `ChangeNotifierProvider` for theme management.
    *   Create a scrollable data entry form with all the specified fields in French.
    *   Implement the 2x3 photo capture grid.
    *   Set up a modern, clean theme with a professional color palette.
3.  **Database and Services (Future Step):**
    *   Create a database helper class to manage the SQLite database.
    *   Implement services for location and photo capture.
4.  **Backend Logic (Future Step):**
    *   Implement the logic for saving observations to the database.
    *   Implement the logic for exporting data as a ZIP file.
