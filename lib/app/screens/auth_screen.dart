import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/zenroom_i18n.dart';
import '../../core/theme/zenroom_theme.dart';
import '../../features/identity/domain/session.dart';
import '../app_controller.dart';
import '../widgets/zen_widgets.dart';
import 'legal_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscured = true;
  bool busy = false;
  UserRole demoRole = UserRole.member;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!AppConfig.demoMode &&
        (email.text.trim().isEmpty || password.text.isEmpty)) {
      showNotice(context, 'Ingresa tu correo y contraseña.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.controller.signIn(
        email.text.trim(),
        password.text,
        demoRole: demoRole,
      );
    } catch (error) {
      if (mounted) showNotice(context, error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openSignUp() async {
    final requestedRole = await Navigator.push<UserRole>(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpScreen(controller: widget.controller),
      ),
    );
    if (mounted && requestedRole != null) {
      setState(() => demoRole = requestedRole);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
    controller: widget.controller,
    child: _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SenseWorkLogo(),
          const SizedBox(height: 25),
          const _AuthHeading(
            title: 'Welcome back',
            subtitle: 'Your spaces and comfort data are waiting.',
          ),
          const SizedBox(height: 22),
          const _AuthLabel('Email address'),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('you@email.com'),
          ),
          const SizedBox(height: 15),
          const _AuthLabel('Password'),
          TextField(
            controller: password,
            obscureText: obscured,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: _inputDecoration('••••••••').copyWith(
              suffixIcon: IconButton(
                tooltip: tr(
                  context,
                  obscured ? 'Show password' : 'Hide password',
                ),
                onPressed: () => setState(() => obscured = !obscured),
                icon: Icon(
                  obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: ZenColors.muted,
                ),
              ),
            ),
          ),
          if (AppConfig.demoMode) ...[
            const SizedBox(height: 15),
            const _AuthLabel('Demo role'),
            DropdownButtonFormField<UserRole>(
              initialValue: demoRole,
              decoration: _inputDecoration(''),
              items: [
                DropdownMenuItem(
                  value: UserRole.member,
                  child: LText('Member', style: _fieldTextStyle),
                ),
                DropdownMenuItem(
                  value: UserRole.admin,
                  child: LText('Administrator', style: _fieldTextStyle),
                ),
              ],
              onChanged: (value) =>
                  setState(() => demoRole = value ?? UserRole.member),
            ),
          ],
          const SizedBox(height: 22),
          _AuthPrimaryButton(
            label: busy ? 'Signing in…' : 'Sign in',
            onPressed: busy ? null : submit,
          ),
          const SizedBox(height: 16),
          _AuthSwitchLink(
            prompt: 'New to SenseWork?',
            action: 'Sign up',
            onTap: openSignUp,
          ),
          const SizedBox(height: 11),
          const _AuthLegalFooter(),
        ],
      ),
    ),
  );
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool adminRequested = false;
  bool obscured = true;
  bool busy = false;

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (firstName.text.trim().isEmpty ||
        lastName.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.length < 8) {
      showNotice(context, 'Completa los campos y usa al menos 8 caracteres.');
      return;
    }
    setState(() => busy = true);
    try {
      if (!AppConfig.demoMode) {
        await widget.controller.identity.signUp(
          '${firstName.text.trim()} ${lastName.text.trim()}',
          email.text.trim(),
          password.text,
        );
      }
      if (mounted) {
        showNotice(
          context,
          AppConfig.demoMode
              ? 'Cuenta de demostración lista. Inicia sesión para explorar.'
              : 'Cuenta creada como miembro. Inicia sesión.',
        );
        Navigator.pop(
          context,
          adminRequested ? UserRole.admin : UserRole.member,
        );
      }
    } catch (error) {
      if (mounted) showNotice(context, error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
    controller: widget.controller,
    child: _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SenseWorkLogo(),
          const SizedBox(height: 24),
          _AuthHeading(
            title: 'Create your account',
            subtitle: adminRequested
                ? 'Prepare your administrator account to monitor your spaces.'
                : 'Discover the comfort of each room before choosing.',
          ),
          const SizedBox(height: 21),
          const _AuthLabel('First name'),
          TextField(
            controller: firstName,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(tr(context, 'Your first name')),
          ),
          const SizedBox(height: 14),
          const _AuthLabel('Last name'),
          TextField(
            controller: lastName,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(tr(context, 'Your last name')),
          ),
          const SizedBox(height: 14),
          const _AuthLabel('Email address'),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('you@email.com'),
          ),
          const SizedBox(height: 14),
          const _AuthLabel('Password'),
          TextField(
            controller: password,
            obscureText: obscured,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: _inputDecoration('••••••••').copyWith(
              suffixIcon: IconButton(
                tooltip: tr(
                  context,
                  obscured ? 'Show password' : 'Hide password',
                ),
                onPressed: () => setState(() => obscured = !obscured),
                icon: Icon(
                  obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: ZenColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          _AdminRoleSwitch(
            value: adminRequested,
            enabled: AppConfig.demoMode,
            onChanged: (value) => setState(() => adminRequested = value),
          ),
          const SizedBox(height: 13),
          _AuthPrimaryButton(
            label: busy ? 'Creating…' : 'Create account',
            onPressed: busy ? null : submit,
          ),
          const SizedBox(height: 14),
          _AuthSwitchLink(
            prompt: 'Already have an account?',
            action: 'Sign in',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          const _AuthLegalFooter(),
        ],
      ),
    ),
  );
}

const _fieldTextStyle = TextStyle(fontSize: 14, color: ZenColors.navy);

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF8E9AA4), fontSize: 13),
  filled: true,
  fillColor: Colors.white,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(7),
    borderSide: const BorderSide(color: Color(0xFFCDD4D9)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(7),
    borderSide: const BorderSide(color: Color(0xFFCDD4D9)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(7),
    borderSide: const BorderSide(color: ZenColors.blue, width: 1.5),
  ),
);

class _AuthShell extends StatelessWidget {
  const _AuthShell({required this.controller, required this.child});

  final AppController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF9F6),
    body: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _AuthBackground())),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 23),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: _AuthLanguageToggle(controller: controller),
                      ),
                      const SizedBox(height: 18),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 390),
                        child: child,
                      ),
                      const SizedBox(height: 22),
                      const LText(
                        'SENSEWORK · REAL-TIME COMFORT · CONNECTED SPACES',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.8,
                          color: Color(0xFF8A9AA3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(25, 22, 25, 21),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFDFE2E3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x180F2A3D),
          blurRadius: 26,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: child,
  );
}

class _SenseWorkLogo extends StatelessWidget {
  const _SenseWorkLogo();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const ZenIcon('logo', size: 28),
      const SizedBox(width: 9),
      RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          children: [
            TextSpan(
              text: 'Sense',
              style: TextStyle(color: ZenColors.navy),
            ),
            TextSpan(
              text: 'Work',
              style: TextStyle(color: ZenColors.blue),
            ),
          ],
        ),
      ),
    ],
  );
}

class _AuthHeading extends StatelessWidget {
  const _AuthHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LText(
        title,
        style: const TextStyle(
          fontSize: 26,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: ZenColors.navy,
        ),
      ),
      const SizedBox(height: 9),
      LText(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: ZenColors.muted,
        ),
      ),
    ],
  );
}

class _AuthLabel extends StatelessWidget {
  const _AuthLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: LText(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: ZenColors.navy,
      ),
    ),
  );
}

class _AuthPrimaryButton extends StatelessWidget {
  const _AuthPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 44,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: ZenColors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LText(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 11),
          const Icon(Icons.arrow_forward, size: 17),
        ],
      ),
    ),
  );
}

class _AuthSwitchLink extends StatelessWidget {
  const _AuthSwitchLink({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        LText(
          prompt,
          style: const TextStyle(fontSize: 11, color: ZenColors.muted),
        ),
        const SizedBox(width: 3),
        InkWell(
          onTap: onTap,
          child: LText(
            action,
            style: const TextStyle(
              fontSize: 11,
              color: ZenColors.navy,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AuthLegalFooter extends StatelessWidget {
  const _AuthLegalFooter();

  @override
  Widget build(BuildContext context) => Center(
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const LText(
          'By continuing you accept the ',
          style: TextStyle(fontSize: 10, color: ZenColors.muted),
        ),
        _LegalLink('Terms of Service'),
        const LText(
          ' and the ',
          style: TextStyle(fontSize: 10, color: ZenColors.muted),
        ),
        _LegalLink('Privacy Policy'),
        const LText(
          '.',
          style: TextStyle(fontSize: 10, color: ZenColors.muted),
        ),
      ],
    ),
  );
}

class _LegalLink extends StatelessWidget {
  const _LegalLink(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LegalScreen(title: title)),
    ),
    child: LText(
      title,
      style: const TextStyle(
        fontSize: 10,
        color: ZenColors.muted,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}

class _AdminRoleSwitch extends StatelessWidget {
  const _AdminRoleSwitch({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: value ? const Color(0xFFE6F4FB) : Colors.white,
      border: Border.all(
        color: value ? ZenColors.blue : const Color(0xFFD5DCDF),
      ),
      borderRadius: BorderRadius.circular(9),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value ? const Color(0xFFD0ECFA) : ZenColors.background,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                Icons.apartment_outlined,
                size: 18,
                color: value ? ZenColors.blue : ZenColors.muted,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LText(
                    'I manage a coworking space',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ZenColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  LText(
                    enabled
                        ? 'Monitor rooms, devices and alerts as an administrator.'
                        : 'Administrator access requires backend approval.',
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      color: ZenColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeTrackColor: ZenColors.blue,
              activeThumbColor: Colors.white,
            ),
          ],
        ),
      ),
    ),
  );
}

class _AuthLanguageToggle extends StatelessWidget {
  const _AuthLanguageToggle({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F2F1),
      border: Border.all(color: const Color(0xFFD9DEDF)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final language in [AppLanguage.spanish, AppLanguage.english])
          Semantics(
            button: true,
            selected: controller.language == language,
            label: language == AppLanguage.spanish ? 'Español' : 'English',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => controller.setLanguage(language),
              child: Container(
                width: 34,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: controller.language == language
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: controller.language == language
                      ? const [
                          BoxShadow(
                            color: Color(0x180F2A3D),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  language == AppLanguage.spanish ? 'ES' : 'EN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: controller.language == language
                        ? ZenColors.navy
                        : ZenColors.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _AuthBackground extends CustomPainter {
  const _AuthBackground();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE9EBEA).withValues(alpha: .48)
      ..strokeWidth = .7;
    for (double x = 0; x < size.width; x += 27) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 27) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final ring = Paint()
      ..color = const Color(0xFFCDD9DF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = const Color(0xFFDCEFF7);
    for (final center in [
      Offset(size.width * .12, size.height * .16),
      Offset(size.width * .88, size.height * .29),
      Offset(size.width * .10, size.height * .87),
    ]) {
      canvas.drawCircle(center, 15, ring);
      canvas.drawCircle(center, 5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
