import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:archive/archive_io.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'database_helper.dart';
import 'services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.blueGrey;

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: appTextTheme,
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Marine Survey Logger',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();
  final _photoService = PhotoService();
  final _dbHelper = DatabaseHelper.instance;
  final _uuid = Uuid();

  final _siteController = TextEditingController();
  final _speciesController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();
  final _tempController = TextEditingController();
  final _phController = TextEditingController();
  final _o2Controller = TextEditingController();
  final _sexeController = TextEditingController();
  final _stdLengthController = TextEditingController();
  final _totalLengthController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _observationId;
  final Map<String, File> _photos = {};

  final Map<String, String> photoViews = {
    'LG': 'Latéral gauche',
    'LD': 'Latérale droite',
    'D': 'Dorsale',
    'V': 'Ventrale',
    'TF': 'Tête',
    'C': 'Caudale',
  };

  @override
  void initState() {
    super.initState();
    _observationId = _uuid.v4();
  }

  void _getLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _latController.text = position.latitude.toString();
        _longController.text = position.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _takePhoto(String view) async {
    final site = _siteController.text;
    final species = _speciesController.text;

    if (site.isEmpty || species.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les champs Site et Espèce avant de prendre une photo.')),
      );
      return;
    }

    try {
      final photo = await _photoService.takePhoto(site, species, _observationId!, view);
      if (photo != null) {
        setState(() {
          _photos[view] = photo;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la prise de photo: $e')));
    }
  }

  void _saveObservation() async {
    if (_formKey.currentState!.validate()) {
      final photosJson = jsonEncode(_photos.map((key, value) => MapEntry(key, value.path)));
      final observation = {
        'site': _siteController.text,
        'species': _speciesController.text,
        'latitude': double.tryParse(_latController.text) ?? 0.0,
        'longitude': double.tryParse(_longController.text) ?? 0.0,
        'temperature': double.tryParse(_tempController.text) ?? 0.0,
        'ph': double.tryParse(_phController.text) ?? 0.0,
        'o2_dissous': double.tryParse(_o2Controller.text) ?? 0.0,
        'sexe': _sexeController.text,
        'standard_length': double.tryParse(_stdLengthController.text) ?? 0.0,
        'total_length': double.tryParse(_totalLengthController.text) ?? 0.0,
        'id_photos': _observationId,
        'remarks': _remarksController.text,
        'photos_json': photosJson,
      };

      await _dbHelper.insertObservation(observation);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Observation enregistrée avec succès!')),
      );
      _resetForm();
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _siteController.clear();
    _speciesController.clear();
    _latController.clear();
    _longController.clear();
    _tempController.clear();
    _phController.clear();
    _o2Controller.clear();
    _sexeController.clear();
    _stdLengthController.clear();
    _totalLengthController.clear();
    _remarksController.clear();
    setState(() {
      _photos.clear();
      _observationId = _uuid.v4();
    });
  }

  void _exportData() async {
    final observations = await _dbHelper.getObservations();
    if (observations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune observation à exporter.')),
      );
      return;
    }

    final dbPath = await getDatabasesPath();
    final dbFile = File('$dbPath/marine_survey.db');
    List<File> imageFiles = [];
    for (var obs in observations) {
      final photosJson = jsonDecode(obs['photos_json']);
      for (var path in photosJson.values) {
        imageFiles.add(File(path));
      }
    }

    final downloadsDirectory = await getDownloadsDirectory();
    final now = DateTime.now();
    final formatter = DateFormat('ddMMyyyy_HHmm');
    final formattedDate = formatter.format(now);
    final zipFile = File('${downloadsDirectory!.path}/marine_survey_export_$formattedDate.zip');

    var encoder = ZipFileEncoder();
    encoder.create(zipFile.path);
    encoder.addFile(dbFile);

    for (var file in imageFiles) {
      if (await file.exists()) {
        encoder.addFile(file);
      }
    }
    encoder.close();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Données exportées vers ${zipFile.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal de bord Marin'),
        actions: [
          IconButton(
            icon: Icon(Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
            tooltip: 'Changer de thème',
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: _exportData,
            tooltip: 'Exporter les données',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(controller: _siteController, label: 'Site'),
              _buildTextField(controller: _speciesController, label: 'Espèce'),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller: _latController, label: 'Latitude', keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(controller: _longController, label: 'Longitude', keyboardType: TextInputType.number)),
                  IconButton(icon: const Icon(Icons.location_searching), onPressed: _getLocation),
                ],
              ),
              _buildTextField(controller: _tempController, label: 'Température', keyboardType: TextInputType.number),
              _buildTextField(controller: _phController, label: 'pH', keyboardType: TextInputType.number),
              _buildTextField(controller: _o2Controller, label: 'O2 dissous', keyboardType: TextInputType.number),
              _buildTextField(controller: _sexeController, label: 'Sexe'),
              _buildTextField(controller: _stdLengthController, label: 'Longueur standard', keyboardType: TextInputType.number),
              _buildTextField(controller: _totalLengthController, label: 'Longueur totale', keyboardType: TextInputType.number),
              _buildTextField(controller: _remarksController, label: 'Remarques', maxLines: 3),
              const SizedBox(height: 20),
              Text('Instructions pour la photo:', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              const Text(
                '• Éviter les reflets directs sur les écailles.\n'
                '• Le poisson doit être bien à plat (le plus possible).\n'
                '• Assurez-vous que la queue apparaît sur l\'image.\n'
                '• Même hauteur du sol et distance de la caméra et angle entre toutes les photos.\n'
                '• Pas d\'ombres fortes, pas de doigts visibles, éviter les reflets d\'eau, pas de flou.\n'
                '• Essuyer légèrement le poisson, retirer les débris.',
              ),
              const SizedBox(height: 20),
              Text('Photos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _buildPhotoGrid(),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveObservation,
                  child: const Text('Enregistrer l\'observation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer une valeur';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: photoViews.length,
      itemBuilder: (context, index) {
        final viewKey = photoViews.keys.elementAt(index);
        final viewName = photoViews[viewKey];
        final photoFile = _photos[viewKey];
        return ElevatedButton(
          onPressed: () => _takePhoto(viewKey),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: photoFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    photoFile,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : Text(viewName!, textAlign: TextAlign.center),
        );
      },
    );
  }
}
