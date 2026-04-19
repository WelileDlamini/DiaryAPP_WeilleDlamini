
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/access_code_service.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChanging;

  const PinSetupScreen({super.key, this.isChanging = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final List<TextEditingController> _confirmControllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _confirmFocusNodes =
      List.generate(4, (index) => FocusNode());

  bool _isLoading = false;
  bool _showConfirmation = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (var controller in _confirmControllers) {
      controller.dispose();
    }
    for (var focusNode in _confirmFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _getCurrentInputCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  String _getCurrentConfirmCode() {
    return _confirmControllers.map((controller) => controller.text).join();
  }

  void _onCodeInput(String value, int index, bool isConfirm) {
    final controllers = isConfirm ? _confirmControllers : _controllers;
    final focusNodes = isConfirm ? _confirmFocusNodes : _focusNodes;

    if (value.isNotEmpty && index < 3) {
      focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onBackspace(int index, bool isConfirm) {
    final controllers = isConfirm ? _confirmControllers : _controllers;
    final focusNodes = isConfirm ? _confirmFocusNodes : _focusNodes;

    if (index > 0) {
      controllers[index - 1].clear();
      focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _clearCode() {
    for (var controller
        in (_showConfirmation ? _confirmControllers : _controllers)) {
      controller.clear();
    }
    (_showConfirmation ? _confirmFocusNodes : _focusNodes)[0].requestFocus();
    setState(() {});
  }

  Future<void> _setupCode() async {
    if (!_showConfirmation) {
      // First step: show confirmation screen
      setState(() {
        _showConfirmation = true;
      });
      _confirmFocusNodes[0].requestFocus();
      return;
    }

    // Second step: verify and save
    final code = _getCurrentInputCode();
    final confirmCode = _getCurrentConfirmCode();

    if (code != confirmCode) {
      _showErrorSnackBar('PIN codes do not match. Please try again.');
      setState(() {
        _showConfirmation = false;
      });
      _clearAllCodes();
      _focusNodes[0].requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AccessCodeService.setAccessCode(code);
      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isChanging
                  ? 'PIN changed successfully'
                  : 'PIN set up successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorSnackBar('Error setting up PIN. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearAllCodes() {
    for (var controller in _controllers) {
      controller.clear();
    }
    for (var controller in _confirmControllers) {
      controller.clear();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isChanging ? 'Change PIN' : 'Set up PIN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 80,
                  color: const Color(0xFF7B2D8E), // Purple
                ),
                const SizedBox(height: 32),
                Text(
                  _showConfirmation
                      ? 'Confirm your PIN'
                      : 'Create your 4-digit PIN',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7B2D8E), // Purple
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _showConfirmation
                      ? 'Enter your PIN again to confirm'
                      : 'This PIN will protect access to your diary',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    final controllers =
                        _showConfirmation ? _confirmControllers : _controllers;
                    final focusNodes =
                        _showConfirmation ? _confirmFocusNodes : _focusNodes;

                    return SizedBox(
                      width: 60,
                      height: 60,
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 1,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF7B2D8E), // Purple
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) =>
                            _onCodeInput(value, index, _showConfirmation),
                        onTap: () {
                          controllers[index].selection =
                              TextSelection.fromPosition(
                            TextPosition(
                                offset: controllers[index].text.length),
                          );
                        },
                        onSubmitted: (value) {
                          if (value.isEmpty && index > 0) {
                            _onBackspace(index, _showConfirmation);
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: (_showConfirmation
                                ? _getCurrentConfirmCode().length == 4
                                : _getCurrentInputCode().length == 4)
                            ? _setupCode
                            : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFF7B2D8E), // Purple
                        ),
                        child: Text(
                            _showConfirmation ? 'Confirm PIN' : 'Continue'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _clearCode,
                        child: const Text('Clear'),
                      ),
                      if (_showConfirmation) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showConfirmation = false;
                            });
                            _clearAllCodes();
                            _focusNodes[0].requestFocus();
                          },
                          child: const Text('Back'),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}