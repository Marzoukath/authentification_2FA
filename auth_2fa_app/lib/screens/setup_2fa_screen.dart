import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pinput/pinput.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class Setup2FAScreen extends StatefulWidget {
  const Setup2FAScreen({super.key});

  @override
  State<Setup2FAScreen> createState() => _Setup2FAScreenState();
}

class _Setup2FAScreenState extends State<Setup2FAScreen> {
  final _apiService = ApiService();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String _selectedMethod = 'totp';
  bool _isLoading = false;
  bool _showConfirmation = false;

  // TOTP Data
  String? _qrCodeUrl;
  String? _secret;

  // Recovery Codes
  List<String>? _recoveryCodes;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentStatus() async {
    final response = await _apiService.get2FAStatus();
    if (response.success && response.data != null) {
      final enabled = response.data['enabled'] ?? false;
      if (enabled) {
        _showDisableOption();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _setupMethod() async {
    setState(() => _isLoading = true);

    try {
      switch (_selectedMethod) {
        case 'totp':
          await _setupTOTP();
          break;
        case 'sms':
          await _setupSMS();
          break;
        case 'email':
          await _setupEmail();
          break;
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setupTOTP() async {
    final response = await _apiService.enable2FATOTP();

    if (response.success && response.data != null) {
      setState(() {
        _qrCodeUrl = response.data['qr_code_url'];
        _secret = response.data['secret'];
        _showConfirmation = true;
      });
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? "Erreur",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _setupSMS() async {
    if (_phoneController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Veuillez entrer votre numéro",
        backgroundColor: Colors.orange,
      );
      return;
    }

    final response = await _apiService.enable2FASMS(_phoneController.text);

    if (response.success) {
      setState(() => _showConfirmation = true);
      Fluttertoast.showToast(
        msg: "Code envoyé par SMS",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? "Erreur",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _setupEmail() async {
    final response = await _apiService.enable2FAEmail();

    if (response.success) {
      setState(() => _showConfirmation = true);
      Fluttertoast.showToast(
        msg: "Code envoyé par email",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? "Erreur",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _confirmSetup() async {
    if (_codeController.text.length != 6) {
      Fluttertoast.showToast(
        msg: "Code à 6 chiffres requis",
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    dynamic response;
    switch (_selectedMethod) {
      case 'totp':
        response = await _apiService.confirm2FATOTP(_codeController.text);
        break;
      case 'sms':
        response = await _apiService.confirm2FASMS(_codeController.text);
        break;
      case 'email':
        response = await _apiService.confirm2FAEmail(_codeController.text);
        break;
    }

    setState(() => _isLoading = false);

    if (response.success) {
      setState(() {
        _recoveryCodes = List<String>.from(response.data['recovery_codes'] ?? []);
      });
      _showSuccessDialog();
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? "Code invalide",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _disable2FA() async {
    setState(() => _isLoading = true);
    final response = await _apiService.disable2FA();
    setState(() => _isLoading = false);

    if (response.success) {
      Fluttertoast.showToast(
        msg: "2FA désactivée",
        backgroundColor: Colors.green,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: "Erreur",
        backgroundColor: Colors.red,
      );
    }
  }

  void _showDisableOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('2FA déjà activée'),
        content: const Text('Voulez-vous désactiver la 2FA actuelle ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _disable2FA();
            },
            child: const Text('Désactiver', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('2FA activée !'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Codes de récupération :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Conservez ces codes en lieu sûr. Ils vous permettront de vous connecter si vous perdez accès à votre méthode 2FA.',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _recoveryCodes!
                      .map((code) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Terminé'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration 2FA'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_showConfirmation) ...[
                const Text(
                  'Choisissez une méthode',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionnez comment vous souhaitez recevoir les codes de vérification',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                _buildMethodCard(
                  'totp',
                  'Application d\'authentification',
                  'Google Authenticator, Authy, etc.',
                  Icons.qr_code_2,
                ),
                const SizedBox(height: 16),
                _buildMethodCard(
                  'sms',
                  'SMS',
                  'Recevoir un code par SMS',
                  Icons.sms,
                ),
                const SizedBox(height: 16),
                _buildMethodCard(
                  'email',
                  'Email',
                  'Recevoir un code par email',
                  Icons.email,
                ),
                const SizedBox(height: 30),
                if (_selectedMethod == 'sms') ...[
                  CustomTextField(
                    label: 'Numéro de téléphone',
                    hint: '+229 XX XX XX XX',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                ],
                CustomButton(
                  text: 'Continuer',
                  onPressed: _setupMethod,
                  isLoading: _isLoading,
                ),
              ] else ...[
                const Text(
                  'Confirmation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                if (_selectedMethod == 'totp' && _qrCodeUrl != null) ...[
                  const Text(
                    'Scannez ce QR code avec votre application d\'authentification',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _qrCodeUrl!,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clé manuelle :',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _secret!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                const Text(
                  'Entrez le code de vérification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                Pinput(
                  controller: _codeController,
                  length: 6,
                  onCompleted: (pin) => _confirmSetup(),
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Confirmer',
                  onPressed: _confirmSetup,
                  isLoading: _isLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard(
      String method,
      String title,
      String subtitle,
      IconData icon,
      ) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}