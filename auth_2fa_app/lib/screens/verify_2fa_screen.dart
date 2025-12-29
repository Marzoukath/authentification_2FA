import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';

class Verify2FAScreen extends StatefulWidget {
  const Verify2FAScreen({super.key});

  @override
  State<Verify2FAScreen> createState() => _Verify2FAScreenState();
}

class _Verify2FAScreenState extends State<Verify2FAScreen> {
  final _pinController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerifying = false; // Protection contre double soumission
  int? _userId;
  String? _method;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _userId = args['userId'];
      _method = args['method'];
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _handleVerify() {
    if (_isLoading || _isVerifying) return;
    _verify();
  }

  Future<void> _verify() async {
    // Protection contre double soumission
    if (_isVerifying) return;

    if (_pinController.text.length != 6) {
      Fluttertoast.showToast(
        msg: "Veuillez entrer un code à 6 chiffres",
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isVerifying = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    // Utiliser la méthode appropriée selon le type
    if (_method == 'totp') {
      success = await authProvider.verifyTOTP(
        userId: _userId!,
        code: _pinController.text,
      );
    } else {
      success = await authProvider.verifySMS(
        userId: _userId!,
        code: _pinController.text,
      );
    }

    setState(() {
      _isLoading = false;
      _isVerifying = false;
    });

    if (!mounted) return;

    if (success) {
      Fluttertoast.showToast(
        msg: "Vérification réussie !",
        backgroundColor: Colors.green,
      );

      // Navigation avec validation de la route
      Navigator.pushReplacementNamed(context, '/success-verification').then((
        _,
      ) {
        if (mounted) {
          // Force la navigation vers home après un délai court
          Timer(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            }
          });
        }
      });
    } else {
      Fluttertoast.showToast(
        msg: authProvider.errorMessage ?? "Code invalide",
        backgroundColor: Colors.red,
      );
      _pinController.clear();
    }
  }

  Future<void> _resendCode() async {
    if (_method == 'totp') {
      Fluttertoast.showToast(
        msg: "Utilisez votre application d'authentification",
        backgroundColor: Colors.blue,
      );
      return;
    }

    setState(() => _isResending = true);

    final response = await _apiService.sendVerificationCode(_userId!);

    setState(() => _isResending = false);

    if (response.success) {
      Fluttertoast.showToast(
        msg: "Code renvoyé avec succès",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(
        msg: "Erreur lors de l'envoi",
        backgroundColor: Colors.red,
      );
    }
  }

  String _getMethodName() {
    switch (_method) {
      case 'totp':
        return 'Application d\'authentification';
      case 'sms':
        return 'SMS';
      case 'email':
        return 'Email';
      default:
        return 'Méthode inconnue';
    }
  }

  IconData _getMethodIcon() {
    switch (_method) {
      case 'totp':
        return Icons.qr_code_2;
      case 'sms':
        return Icons.sms;
      case 'email':
        return Icons.email;
      default:
        return Icons.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getMethodIcon(),
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Vérification 2FA',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Entrez le code de vérification envoyé via ${_getMethodName()}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 50),
              Pinput(
                controller: _pinController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                onCompleted: (pin) => _verify(),
                autofocus: true,
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Vérifier',
                onPressed: (_isLoading || _isVerifying) ? null : _handleVerify,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
              if (_method != 'totp')
                TextButton(
                  onPressed: _isResending ? null : _resendCode,
                  child: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Renvoyer le code'),
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _method == 'totp'
                            ? 'Utilisez votre application d\'authentification pour obtenir le code'
                            : 'Le code expire dans 10 minutes',
                        style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
