# Description

Designed to streamline field research for a Master’s thesis in Aquaculture, this specialized Android application provides a digital solution for standardized fish data collection. The app enables researchers to efficiently log key physiological parameters—such as height and weight—while automatically capturing precise geographical coordinates for environmental mapping. To support detailed morphological analysis, the interface includes a dedicated workflow for capturing six standardized photographs of each specimen from specific orientations, ensuring a consistent and high-quality dataset for further study.

Check some screenshots of my android application: 

<p align="center">
  <img src="docs/screen1.jpg" width="32%" alt="Survey Section 1" />
  <img src="docs/screen2.jpg" width="32%" alt="Survey Section 3" />
  <img src="docs/screen3.jpg" width="32%" alt="Survey Section 4" />
</p>

To get the apk you would have to download this repo and follow the installation process described below or you can also contact me at: [loicyng@gmail.com](mailto:loicyng@gmail.com)

## Table of Contents
- [Description](#description)
- [Stack](#stack)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Citation](#citation)
- [Author](#author)
- [License](#license)
- [Support](#support)
- [ToDo](#todo)

## Stack

*   **Flutter:** The application is built using the Flutter framework for cross-platform development.
*   **Dart:** The programming language used for Flutter development.
*   **sqflite:** A Flutter plugin for SQLite, used for local database storage.
*   **provider:** A state management library for Flutter.
*   **image_picker:** A Flutter plugin for selecting images from the device's gallery or camera.
*   **path_provider:** A Flutter plugin for finding commonly used locations on the filesystem.
*   **geolocator:** A Flutter plugin for getting the device's location.
*   **archive:** A Dart library for working with archives (e.g., ZIP).
*   **google_fonts:** A Flutter package for using fonts from Google Fonts.
*   **uuid:** A Dart library for generating universally unique identifiers.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Installation

To run this application on your local machine, you will need to have Flutter installed. If you do not have Flutter installed, you can follow the instructions on the [Flutter website](https://flutter.dev/docs/get-started/install).

Once you have Flutter installed, you can clone this repository and run the application using the following commands:

```bash
git clone https://github.com/fiastros/HappyFish.git
cd HappyFish
flutter pub get
flutter run
```

To build the APK file, run the following command:

```bash
flutter build apk
```
The APK file will be located in the `build/app/outputs/flutter-apk/` directory. 

## Instructions on how to use the app

- after typing every information please save before exporting or closing the app !
- you do not need to export after every save ! just write every observation and take the images and save Then at the end of the day, export the .zip or before your phone storage's get full
- The exported `marine_survey_export.zip` file will be saved in your device's "Downloads" folder: Internal storage → Android → data → com.example.myapp → files → downloads



## Citation

If you use this application in your research, academic work, or any other project, please cite it as follows:

**APA Format:**
```
EYANGO TABI, T. G. L. (2026). ENSAHV. Retrieved from https://github.com/fiastros/HappyFish
```

**BibTeX Format:**
```bibtex
@software{ensahv2026,
  author = {EYANGO TABI, Theophile G. Loic},
  title = {ENSAHV M2},
  year = {2026},
  url = {https://github.com/fiastros/HappyFish}
}
```

**Chicago Format:**
```
EYANGO TABI, Theophile G. Loic. "ENSAHV M2." Accessed 2026. https://github.com/fiastros/HappyFish
```

## Author

**Dr. EYANGO TABI, Theophile G. Loic**
- Department of Aquaculture
- ENSAHV University of Douala, Cameroon
- Expertise: Machine Learning, Deep Learning, Computer Science, Uncertainty Quantification

## License

This project is provided for educational and research purposes. Attribution to the author is required for any use of this software or its derivatives.

## Support

For issues, feature requests, or questions, please open an issue on the [GitHub repository](https://github.com/fiastros/HappyFish/issues).

## ToDo

V0.3

- [x] Add the location of the stored data on the android device
- [x] Correct the fact that the user can save .zip even if survey is empty
- [x] Correct the fact after saving a survey the fields are still filled with previous answers

V0.4
- [x] when I export new file, i don't want to ovewrite previous "marine_survey_export.zip" but rather create a new name incremented with date time for example "marine_survey_export_09022026_1809.zip"

v0.5
- [ ] Check on android that images are not saved in standard image folder ? what happens after i delete app ? 
- [ ] Whats happens if i just save observations without exporting and I minize the app, will I still be able to save ? 
- [ ] If i save observations and close app, will i be able to later export apps ? 
- [ ] If I save .zip close app and come back latter will i still be able to save empty folder ? 
- [ ] check what happens when 


---