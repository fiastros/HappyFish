import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:archive/archive_io.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart'; // Make sure intl is added back to pubspec.yaml
import 'package:path/path.dart' as path;

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
          home: const ObservationListScreen(),
        );
      },
    );
  }
}

class ObservationListScreen extends StatefulWidget {
  const ObservationListScreen({super.key});

  @override
  _ObservationListScreenState createState() => _ObservationListScreenState();
}

class _ObservationListScreenState extends State<ObservationListScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _observations = [];

  @override
  void initState() {
    super.initState();
    _refreshObservations();
  }

  void _refreshObservations() async {
    final data = await _dbHelper.getObservations();
    setState(() {
      _observations = data;
    });
  }

  void _exportData() async {
    try {
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
        if (obs['photos_json'] != null) {
          final photosJson = jsonDecode(obs['photos_json']);
          if (photosJson is Map) {
            for (var path in photosJson.values) {
              imageFiles.add(File(path));
            }
          }
        }
      }

      final downloadsDirectory = await getDownloadsDirectory();
      final zipFile = File('${downloadsDirectory!.path}/marine_survey_export.zip');

      // Use Archive class directly to avoid issues with ZipFileEncoder
      final archive = Archive();

      // Add DB file
      if (await dbFile.exists()) {
         final dbBytes = await dbFile.readAsBytes();
         final dbName = path.basename(dbFile.path);
         archive.addFile(ArchiveFile(dbName, dbBytes.length, dbBytes));
      }

      // Add Image files
      for (var file in imageFiles) {
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final name = path.basename(file.path);
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        }
      }

      final encoder = ZipEncoder();
      final zipData = encoder.encode(archive);
      if (zipData != null) {
          await zipFile.writeAsBytes(zipData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Données exportées vers ${zipFile.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'exportation: $e')),
      );
    }
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
      body: _observations.isEmpty
          ? const Center(child: Text('Aucune observation enregistrée.'))
          : ListView.builder(
              itemCount: _observations.length,
              itemBuilder: (context, index) {
                final obs = _observations[index];
                final date = obs['date'] ?? 'Date inconnue';
                return ListTile(
                  title: Text('${obs['site']} - ${obs['species']}'),
                  subtitle: Text('Date: $date'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ObservationFormScreen(observation: obs),
                      ),
                    );
                    _refreshObservations();
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ObservationFormScreen(),
            ),
          );
          _refreshObservations();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ObservationFormScreen extends StatefulWidget {
  final Map<String, dynamic>? observation;

  const ObservationFormScreen({super.key, this.observation});

  @override
  _ObservationFormScreenState createState() => _ObservationFormScreenState();
}

class _ObservationFormScreenState extends State<ObservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();
  final _photoService = PhotoService();
  final _dbHelper = DatabaseHelper.instance;
  final _uuid = Uuid();

  final _dateController = TextEditingController();
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
  int? _dbId;
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
    if (widget.observation != null) {
      _loadObservation(widget.observation!);
    } else {
      _observationId = _uuid.v4();
      _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    }
  }

  void _loadObservation(Map<String, dynamic> obs) {
    _dbId = obs['id'];
    _dateController.text = obs['date'] ?? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    _siteController.text = obs['site'];
    _speciesController.text = obs['species'];
    _latController.text = obs['latitude'].toString();
    _longController.text = obs['longitude'].toString();
    _tempController.text = obs['temperature'].toString();
    _phController.text = obs['ph'].toString();
    _o2Controller.text = obs['o2_dissous'].toString();
    _sexeController.text = obs['sexe'];
    _stdLengthController.text = obs['standard_length'].toString();
    _totalLengthController.text = obs['total_length'].toString();
    _remarksController.text = obs['remarks'];
    _observationId = obs['id_photos'];

    if (obs['photos_json'] != null) {
      final photosJson = jsonDecode(obs['photos_json']);
      if (photosJson is Map) {
        photosJson.forEach((key, value) {
          _photos[key] = File(value);
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
         final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
        });
      }
    }
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
      // Pass the view key directly (e.g., 'LG', 'TF') to ensure uniqueness in filename
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

  Future<void> _renameImages(String newSite, String newSpecies) async {
    final directory = await getApplicationDocumentsDirectory();
    final Map<String, File> newPhotos = {};

    for (var entry in _photos.entries) {
      final view = entry.key;
      final file = entry.value;
      if (await file.exists()) {
        final extension = path.extension(file.path);
        // Ensure filename format matches creation logic: SITE_species_YYYYMMDD_IDphoto_VUE.jpg
        // Use a consistent date format for renaming if needed, or keep original date?
        // Let's use current date to avoid complexity or extract from filename?
        // Simpler: use the existing _observationId and view.
        // We need the date part. Let's reuse the logic from PhotoService or similar.
        final now = DateTime.now();
        final formattedDate = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        
        // Construct new filename
        final newFileName = '${newSite}_${newSpecies}_${formattedDate}_${_observationId}_$view$extension';
        final newPath = path.join(directory.path, newFileName);

        if (file.path != newPath) {
            try {
                final newFile = await file.rename(newPath);
                newPhotos[view] = newFile;
            } catch (e) {
                print('Error renaming file: $e');
                newPhotos[view] = file; // Keep old if rename fails
            }
        } else {
            newPhotos[view] = file;
        }
      }
    }
    setState(() {
        _photos.clear();
        _photos.addAll(newPhotos);
    });
  }


  void _saveObservation() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Rename images if site or species changed (and we are updating)
        if (_dbId != null) {
             await _renameImages(_siteController.text, _speciesController.text);
        }

        final photosJson = jsonEncode(_photos.map((key, value) => MapEntry(key, value.path)));
        final observation = {
          'date': _dateController.text,
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

        if (_dbId != null) {
          observation['id'] = _dbId!;
          await _dbHelper.updateObservation(observation);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Observation mise à jour avec succès!')),
          );
        } else {
          await _dbHelper.insertObservation(observation);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Observation enregistrée avec succès!')),
          );
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    }
  }

  void _deleteObservation() async {
    if (_dbId != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Voulez-vous vraiment supprimer cette observation et ses photos ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          await _dbHelper.deleteObservation(_dbId!);
          // Optional: Delete photos from filesystem
          for (var file in _photos.values) {
            if (await file.exists()) {
              await file.delete();
            }
          }
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Observation supprimée.')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dbId != null ? 'Modifier Observation' : 'Nouvelle Observation'),
        actions: [
          if (_dbId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteObservation,
              tooltip: 'Supprimer',
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
              InkWell(
                onTap: () => _selectDate(context),
                child: IgnorePointer(
                  child: _buildTextField(controller: _dateController, label: 'Date et Heure', keyboardType: TextInputType.datetime),
                ),
              ),
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
              _buildTextField(controller: _remarksController, label: 'Remarques', maxLines: 3, isMandatory: false),
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
                  child: Text(_dbId != null ? 'Mettre à jour' : 'Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, int maxLines = 1, TextInputType? keyboardType, bool isMandatory = true}) {
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
        validator: isMandatory ? (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer une valeur';
          }
          return null;
        } : null,
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
