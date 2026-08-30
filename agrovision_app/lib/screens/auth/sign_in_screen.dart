import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  final bool showGuestOption;
  const SignInScreen({super.key, this.showGuestOption = true});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    final result = await AuthService().signIn(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _errorMsg = result.error);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please enter your email first.');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });
    final result = await AuthService().resetPassword(_emailCtrl.text);
    if (!mounted) return;
    setState(() { _isLoading = false; _errorMsg = result.isSuccess ? result.message : result.error; });
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: AppTheme.splashGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  _buildLogo(),
                  const SizedBox(height: 36),
                  _buildCard(isDark, l10n),
                  const SizedBox(height: 20),
                  if (widget.showGuestOption)
                    _buildGuestOption(l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.eco_rounded, size: 44, color: Colors.white),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 14),
        RichText(
          text: const TextSpan(children: [
            TextSpan(text: 'AgroVision ', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 26, color: Colors.white)),
            TextSpan(text: 'AI', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 26, color: Color(0xFF6EE7B7))),
          ]),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 4),
        Text('Smart Agriculture Platform', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withOpacity(0.7))).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildCard(bool isDark, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.signIn, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 4),
            Text(l10n.signInSubtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(height: 24),
            // Email
            _buildTextField(
              label: l10n.emailLabel,
              controller: _emailCtrl,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.emailRequired;
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) return l10n.emailInvalid;
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Password
            _buildTextField(
              label: l10n.passwordLabel,
              controller: _passCtrl,
              icon: Icons.lock_outline_rounded,
              isDark: isDark,
              obscureText: _obscurePass,
              suffix: IconButton(
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.passwordRequired;
                if (v.length < 6) return l10n.passwordTooShort;
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _forgotPassword,
                child: Text(l10n.forgotPassword, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreen)),
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMsg!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF991B1B)))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(l10n.signIn),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.noAccount, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignUpScreen())),
                  child: Text(l10n.signUp, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppTheme.emeraldGreen, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, delay: 200.ms).fadeIn();
  }

  Widget _buildGuestOption(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.white30)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(l10n.orContinueWith, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white60)),
            ),
            const Expanded(child: Divider(color: Colors.white30)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _continueAsGuest,
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white70),
            label: Text(l10n.continueAsGuest, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white70)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.white.withOpacity(0.35)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.guestLimitNote, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white54)),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final fillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.emeraldGreen, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
