import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const SecureVaultApp());
}

class SecureVaultApp extends StatelessWidget {
  const SecureVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Vault',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash delay
    
    final prefs = await SharedPreferences.getInstance();
    final hasPasscode = prefs.containsKey('secure_passcode');
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => hasPasscode 
            ? const PasscodeVerificationScreen() 
            : const PasscodeSetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Secure Vault',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Protecting your privacy',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class PasscodeSetupScreen extends StatefulWidget {
  const PasscodeSetupScreen({super.key});

  @override
  State<PasscodeSetupScreen> createState() => _PasscodeSetupScreenState();
}

class _PasscodeSetupScreenState extends State<PasscodeSetupScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _confirmPasscodeController = TextEditingController();
  bool _isObscured = true;

  Future<void> _createPasscode() async {
    if (_passcodeController.text.length < 4) {
      _showMessage('Passcode minimal 4 digit');
      return;
    }
    
    if (_passcodeController.text != _confirmPasscodeController.text) {
      _showMessage('Passcode tidak cocok');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secure_passcode', _passcodeController.text);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Keamanan'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 60,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 30),
            const Text(
              'Buat Passcode Keamanan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Passcode akan digunakan untuk mengakses vault pribadi Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _passcodeController,
              keyboardType: TextInputType.number,
              obscureText: _isObscured,
              decoration: InputDecoration(
                labelText: 'Passcode Baru',
                prefixIcon: const Icon(Icons.password),
                suffixIcon: IconButton(
                  icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasscodeController,
              keyboardType: TextInputType.number,
              obscureText: _isObscured,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Passcode',
                prefixIcon: const Icon(Icons.password),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createPasscode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Buat Passcode',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PasscodeVerificationScreen extends StatefulWidget {
  const PasscodeVerificationScreen({super.key});

  @override
  State<PasscodeVerificationScreen> createState() => _PasscodeVerificationScreenState();
}

class _PasscodeVerificationScreenState extends State<PasscodeVerificationScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  bool _isObscured = true;
  int _failedAttempts = 0;

  Future<void> _verifyPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPasscode = prefs.getString('secure_passcode');
    
    if (_passcodeController.text == savedPasscode) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
      );
    } else {
      setState(() => _failedAttempts++);
      _passcodeController.clear();
      
      if (_failedAttempts >= 3) {
        _showMessage('Terlalu banyak percobaan gagal');
        await Future.delayed(const Duration(seconds: 2));
        exit(0);
      } else {
        _showMessage('Passcode salah. Sisa percobaan: ${3 - _failedAttempts}');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Keamanan'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 60,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 30),
            const Text(
              'Masukkan Passcode',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Masukkan passcode untuk mengakses vault pribadi Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _passcodeController,
              keyboardType: TextInputType.number,
              obscureText: _isObscured,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Passcode',
                prefixIcon: const Icon(Icons.password),
                suffixIcon: IconButton(
                  icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_failedAttempts > 0)
              Text(
                'Percobaan gagal: $_failedAttempts/3',
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyPasscode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Buka Vault',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  List<File> vaultFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVaultFiles();
  }

  Future<Directory> _getSecureVaultDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/.securevault');
    
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
      
      // Buat file .nomedia untuk menyembunyikan dari galeri
      final nomediaFile = File('${vaultDir.path}/.nomedia');
      await nomediaFile.writeAsString('');
    }
    
    return vaultDir;
  }

  Future<void> _loadVaultFiles() async {
    setState(() => _isLoading = true);
    
    try {
      final vaultDir = await _getSecureVaultDirectory();
      final files = vaultDir
          .listSync()
          .whereType<File>()
          .where((file) => !path.basename(file.path).startsWith('.'))
          .toList();
      
      setState(() => vaultFiles = files);
    } catch (e) {
      _showMessage('Gagal memuat file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFilesToVault() async {
    // Minta izin akses storage
    final permission = await Permission.manageExternalStorage.request();
    if (!permission.isGranted) {
      _showMessage('Izin akses storage diperlukan');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi', 'pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _isLoading = true);
      
      try {
        final vaultDir = await _getSecureVaultDirectory();
        
        for (var platformFile in result.files) {
          if (platformFile.path != null) {
            final sourceFile = File(platformFile.path!);
            final fileName = path.basename(platformFile.path!);
            final destinationPath = path.join(vaultDir.path, fileName);
            
            // Copy file ke vault
            await sourceFile.copy(destinationPath);
            
            // Hapus file asli (opsional)
            try {
              await sourceFile.delete();
            } catch (e) {
              // Ignore jika gagal menghapus file asli
            }
          }
        }
        
        await _loadVaultFiles();
        _showMessage('${result.files.length} file berhasil ditambahkan ke vault');
      } catch (e) {
        _showMessage('Gagal menambahkan file: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteFile(File file) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus File'),
        content: Text('Apakah Anda yakin ingin menghapus "${path.basename(file.path)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await file.delete();
        await _loadVaultFiles();
        _showMessage('File berhasil dihapus');
      } catch (e) {
        _showMessage('Gagal menghapus file: $e');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildFileIcon(File file) {
    final extension = path.extension(file.path).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      case '.mp4':
      case '.mov':
      case '.avi':
        return const Icon(Icons.video_file, size: 40, color: Colors.blue);
      case '.pdf':
        return const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red);
      case '.doc':
      case '.docx':
        return const Icon(Icons.description, size: 40, color: Colors.blue);
      case '.txt':
        return const Icon(Icons.text_snippet, size: 40, color: Colors.green);
      default:
        return const Icon(Icons.insert_drive_file, size: 40, color: Colors.grey);
    }
  }

  void _previewFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif'].contains(extension)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(file: file),
        ),
      );
    } else {
      _showMessage('Preview tidak tersedia untuk jenis file ini');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Vault'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : vaultFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.folder_open,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Vault Kosong',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tap tombol + untuk menambahkan file',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: vaultFiles.length,
                    itemBuilder: (context, index) {
                      final file = vaultFiles[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _previewFile(file),
                          onLongPress: () => _deleteFile(file),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  child: _buildFileIcon(file),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                color: Colors.black54,
                                child: Text(
                                  path.basename(file.path),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFilesToVault,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final File file;

  const ImagePreviewScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(path.basename(file.path)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: Image.file(file),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _changePasscode() async {
    final newPasscode = await showDialog<String>(
      context: context,
      builder: (context) => const PasscodeChangeDialog(),
    );
    
    if (newPasscode != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('secure_passcode', newPasscode);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passcode berhasil diubah')),
      );
    }
  }

  Future<void> _clearVault() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua File'),
        content: const Text('Apakah Anda yakin ingin menghapus semua file di vault? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final vaultDir = Directory('${appDir.path}/.securevault');
        
        if (await vaultDir.exists()) {
          await vaultDir.delete(recursive: true);
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua file telah dihapus')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Ubah Passcode'),
            subtitle: const Text('Ganti passcode keamanan'),
            onTap: _changePasscode,
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('Hapus Semua File'),
            subtitle: const Text('Kosongkan vault'),
            onTap: _clearVault,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Tentang'),
            subtitle: const Text('Secure Vault v1.0'),
          ),
        ],
      ),
    );
  }
}

class PasscodeChangeDialog extends StatefulWidget {
  const PasscodeChangeDialog({super.key});

  @override
  State<PasscodeChangeDialog> createState() => _PasscodeChangeDialogState();
}

class _PasscodeChangeDialogState extends State<PasscodeChangeDialog> {
  final _oldPasscodeController = TextEditingController();
  final _newPasscodeController = TextEditingController();
  final _confirmPasscodeController = TextEditingController();

  Future<void> _changePasscode() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPasscode = prefs.getString('secure_passcode');
    
    if (_oldPasscodeController.text != currentPasscode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passcode lama salah')),
      );
      return;
    }
    
    if (_newPasscodeController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passcode minimal 4 digit')),
      );
      return;
    }
    
    if (_newPasscodeController.text != _confirmPasscodeController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passcode baru tidak cocok')),
      );
      return;
    }
    
    Navigator.pop(context, _newPasscodeController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Passcode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _oldPasscodeController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Passcode Lama',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newPasscodeController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Passcode Baru',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasscodeController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Konfirmasi Passcode Baru',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _changePasscode,
          child: const Text('Ubah'),
        ),
      ],
    );
  }
}