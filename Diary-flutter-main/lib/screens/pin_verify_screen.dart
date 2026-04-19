

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/access_code_service.dart';

class PinVerifyScreen extends StatefulWidget {
  final bool canCancel;
  final VoidCallback? onVerificationSuccess;

  const PinVerifyScreen({
    super.key,
    this.canCancel = true,
    this.onVerificationSuccess,
  });

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<PinVerifyScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  bool _isLoading = false;
  int _attempts = 0;
  final int _maxAttempts = 3;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    // Auto-focus on first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _getCurrentInputCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  void _onCodeInput(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-verify when all 4 digits are entered
    if (_getCurrentInputCode().length == 4) {
      _verifyCode();
    }

    setState(() {});
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  Future<void> _verifyCode() async {
    final code = _getCurrentInputCode();
    if (code.length != 4) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isCorrect = await AccessCodeService.verifyAccessCode(code);

      if (isCorrect) {
        // Correct code - mark as logged in
        await AccessCodeService.setLoginState(true);

        if (mounted) {
          // Call callback if provided instead of popping
          if (widget.onVerificationSuccess != null) {
            widget.onVerificationSuccess!();
          } else {
            Navigator.of(context).pop(true);
          }
        }
      } else {
        // Incorrect code
        _attempts++;

        if (_attempts >= _maxAttempts) {
          // Max attempts reached
          if (mounted) {
            if (widget.canCancel) {
              Navigator.of(context).pop(false);
            } else {
              // Cannot cancel - close the app
              SystemNavigator.pop();
            }
          }
        } else {
          // Show error and clear
          _performShakeAnimation();
          _clearCode();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Incorrect PIN. Attempts remaining: ${_maxAttempts - _attempts}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying PIN: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _performShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  void _showForgotCodeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Forgot your PIN?'),
          content: const Text(
            'To reset your access code, you will need to uninstall and reinstall the app. '
            'Please note that this will delete all your data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.canCancel
          ? AppBar(
              title: const Text('Verify PIN'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        (widget.canCancel ? kToolbarHeight : 0) -
                        100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 80,
                        color: const Color(0xFF7B2D8E), // Purple
                      ),
                      const SizedBox(height: 32),
                      Text(
                        widget.canCancel
                            ? 'Enter your access code'
                            : 'App Locked',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF7B2D8E), // Purple
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.canCancel
                            ? 'Enter your 4-digit code to continue'
                            : 'Enter your PIN to unlock the app',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      if (_attempts > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            'Attempts remaining: ${_maxAttempts - _attempts}',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          return SizedBox(
                            width: 60,
                            height: 60,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
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
                                  borderSide: BorderSide(
                                    color: _attempts > 0
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _attempts > 0
                                        ? Colors.red
                                        : const Color(0xFF7B2D8E), // Purple
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) => _onCodeInput(value, index),
                              onTap: () {
                                _controllers[index].selection =
                                    TextSelection.fromPosition(
                                  TextPosition(
                                      offset: _controllers[index].text.length),
                                );
                              },
                              onSubmitted: (value) {
                                if (value.isEmpty && index > 0) {
                                  _onBackspace(index);
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
                              onPressed: _getCurrentInputCode().length == 4
                                  ? _verifyCode
                                  : null,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color(0xFF7B2D8E), // Purple
                              ),
                              child: const Text('Verify'),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _clearCode,
                              child: const Text('Clear'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _showForgotCodeDialog,
                              child: Text(
                                'Forgot your PIN?',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}