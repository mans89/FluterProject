import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const WaffirliApp());
}

// ─── Brand Colors ─────────────────────────────────────────────────────────────
class C {
  static const bg          = Color(0xFFF4F8F6);
  static const surface     = Color(0xFFFFFFFF);
  static const card        = Color(0xFFFFFFFF);
  static const border      = Color(0xFFD6EDE2);
  static const green       = Color(0xFF2BAE72);
  static const greenDark   = Color(0xFF1A8A55);
  static const greenDeep   = Color(0xFF0F6B40);
  static const greenPale   = Color(0xFFE6F7EE);
  static const purple      = Color(0xFF7B61C8);
  static const purpleLight = Color(0xFFA08EE0);
  static const purplePale  = Color(0xFFEDE9F9);
  static const gold        = Color(0xFFF5C800);
  static const goldLight   = Color(0xFFFFE14D);
  static const goldPale    = Color(0xFFFFF8D6);
  static const textColor   = Color(0xFF1A2E22);
  static const muted       = Color(0xFF6B8878);
  static const mutedLight  = Color(0xFFA8C0B0);
  static const red         = Color(0xFFE74C3C);

  static const gradGreen  = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [greenDeep, green],
  );
  static const gradGreenBtn = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [green, greenDark],
  );
  static const gradPurple = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [purple, purpleLight],
  );
  static const gradGold = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [gold, goldLight],
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
String genOTP() => (100000 + Random().nextInt(900000)).toString();
String genMemberNum() => 'VF${100000 + Random().nextInt(900000)}';

List<List<int>> genQR(String text) {
  const cells = 21;
  final seed = text.codeUnits.fold(0, (a, b) => a + b);
  return List.generate(cells, (r) => List.generate(cells, (c) {
    final corner = (r < 7 && c < 7) || (r < 7 && c > 13) || (r > 13 && c < 7);
    final inner  = (r >= 2 && r <= 4 && c >= 2 && c <= 4) ||
                   (r >= 2 && r <= 4 && c >= 16 && c <= 18) ||
                   (r >= 16 && r <= 18 && c >= 2 && c <= 4);
    final b1 = (r == 0 || r == 6 || c == 0 || c == 6) && r <= 6 && c <= 6;
    final b2 = (r == 0 || r == 6 || c == 14 || c == 20) && r <= 6 && c >= 14;
    final b3 = (r == 14 || r == 20 || c == 0 || c == 6) && r >= 14 && c <= 6;
    if (corner || b1 || b2 || b3 || inner) return 1;
    return ((seed * (r + 1) * (c + 1) + r * 37 + c * 53) % 3 == 0) ? 1 : 0;
  }));
}

// ─── App Shell ────────────────────────────────────────────────────────────────
class WaffirliApp extends StatelessWidget {
  const WaffirliApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'وفّرلي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: C.green),
      ),
      home: const AppNavigator(),
    );
  }
}

// ─── Navigator / State Machine ────────────────────────────────────────────────
enum AppScreen { splash, landing, phone, otp, customerDash, business }

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});
  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppScreen _screen = AppScreen.splash;
  String _phone = '';
  String _otp   = '';

  void _go(AppScreen s) => setState(() => _screen = s);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: switch (_screen) {
        AppScreen.splash      => SplashScreen(onDone: () => _go(AppScreen.landing)),
        AppScreen.landing     => LandingScreen(
            onCustomer: () => _go(AppScreen.phone),
            onBusiness: () => _go(AppScreen.business),
          ),
        AppScreen.phone       => PhoneScreen(
            onSent: (p, o) { _phone = p; _otp = o; _go(AppScreen.otp); },
            onBack: () => _go(AppScreen.landing),
          ),
        AppScreen.otp         => OtpScreen(
            phone: _phone, otp: _otp,
            onVerified: () => _go(AppScreen.customerDash),
            onBack: () => _go(AppScreen.phone),
          ),
        AppScreen.customerDash => CustomerDashboard(
            phone: _phone,
            onLogout: () => _go(AppScreen.landing),
          ),
        AppScreen.business    => BusinessPortal(onLogout: () => _go(AppScreen.landing)),
      },
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

/// Gradient button
class GradBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Gradient gradient;
  final Color textColor;
  const GradBtn({
    super.key,
    required this.label,
    required this.onTap,
    required this.gradient,
    this.textColor = Colors.white,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onTap != null
                ? [BoxShadow(color: gradient.colors.first.withOpacity(.3), blurRadius: 16, offset: const Offset(0, 6))]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
        ),
      ),
    );
  }
}

/// Outlined ghost button
class GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  const GhostBtn({super.key, required this.label, required this.onTap, required this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    ),
  );
}

/// Rounded white card
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Decoration? decoration;
  const AppCard({super.key, required this.child, this.padding, this.decoration});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(18),
    decoration: decoration ?? BoxDecoration(
      color: C.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: C.border),
      boxShadow: [BoxShadow(color: C.green.withOpacity(.08), blurRadius: 16, offset: const Offset(0, 3))],
    ),
    child: child,
  );
}

/// Gradient page header with rounded bottom corners
class GradHeader extends StatelessWidget {
  final Gradient gradient;
  final Widget child;
  final double bottomRadius;
  const GradHeader({super.key, required this.gradient, required this.child, this.bottomRadius = 28});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(bottomRadius),
        bottomRight: Radius.circular(bottomRadius),
      ),
      boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(.22), blurRadius: 24, offset: const Offset(0, 6))],
    ),
    child: SafeArea(bottom: false, child: child),
  );
}

/// Waffirli shopping-bag logo painted widget
class WaffarLogo extends StatelessWidget {
  final double size;
  const WaffarLogo({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _LogoPainter(),
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size sz) {
    final s = sz.width / 56;
    // bag body
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [C.green, C.greenDark],
      ).createShader(Rect.fromLTWH(8 * s, 20 * s, 40 * s, 30 * s));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8*s,20*s,40*s,30*s), Radius.circular(7*s)),
      bodyPaint,
    );
    // handle
    final handlePaint = Paint()
      ..color = C.greenDark
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final handlePath = Path()
      ..moveTo(20*s, 20*s)
      ..cubicTo(20*s,12*s, 36*s,12*s, 36*s,20*s);
    canvas.drawPath(handlePath, handlePaint);
    // eyes
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(22*s,32*s), 2*s, eyePaint);
    canvas.drawCircle(Offset(34*s,32*s), 2*s, eyePaint);
    // smile
    final smilePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.8*s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final smilePath = Path()
      ..moveTo(20*s,37*s)
      ..quadraticBezierTo(28*s,44*s, 36*s,37*s);
    canvas.drawPath(smilePath, smilePaint);
    // gold coin
    final coinPaint = Paint()..color = C.gold;
    canvas.drawCircle(Offset(42*s,20*s), 7*s, coinPaint);
    final tp = TextPainter(
      text: const TextSpan(text:'ر', style: TextStyle(color: Color(0xFF1A1400), fontSize: 9, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(canvas, Offset(42*s - tp.width/2, 20*s - tp.height/2));
  }
  @override
  bool shouldRepaint(_) => false;
}

/// QR code painter
class QrPainter extends CustomPainter {
  final List<List<int>> grid;
  final Color color;
  const QrPainter({required this.grid, this.color = C.greenDeep});
  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / grid.length;
    final paint = Paint()..color = color;
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        if (grid[r][c] == 1) {
          canvas.drawRect(Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize), paint);
        }
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── SCREEN 1 — Splash ────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _floatAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(_fadeCtrl);
    Future.delayed(const Duration(milliseconds: 2800), widget.onDone);
  }

  @override
  void dispose() { _floatCtrl.dispose(); _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: C.gradGreen),
      child: Stack(children: [
        // blobs
        Positioned(top: -60, right: -60, child: _blob(200, C.purple.withOpacity(.2))),
        Positioned(bottom: -40, left: -40, child: _blob(160, C.gold.withOpacity(.15))),
        // content
        Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, child) => Transform.translate(offset: Offset(0, _floatAnim.value), child: child),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // logo container
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(.3)),
                  ),
                  child: const Center(child: WaffarLogo(size: 70)),
                ),
                const SizedBox(height: 20),
                const Text('وفّرلي', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white)),
                const Text('Waffirli', style: TextStyle(fontSize: 15, color: Colors.white54, letterSpacing: 3)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(gradient: C.gradGold, borderRadius: BorderRadius.circular(50)),
                  child: const Text('خصومات أكثر.. حياة أوفر ✨',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1200))),
                ),
              ]),
            ),
          ),
        ),
        // spinner
        Positioned(bottom: 56, left: 0, right: 0,
          child: Column(children: [
            SizedBox(width: 28, height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: C.gold.withOpacity(.8))),
            const SizedBox(height: 8),
            const Text('جاري التحميل...', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ]),
        ),
      ]),
    ),
  );

  Widget _blob(double sz, Color color) => Container(
    width: sz, height: sz,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ─── SCREEN 2 — Landing ───────────────────────────────────────────────────────
class LandingScreen extends StatelessWidget {
  final VoidCallback onCustomer;
  final VoidCallback onBusiness;
  const LandingScreen({super.key, required this.onCustomer, required this.onBusiness});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      // Hero header
      GradHeader(
        gradient: C.gradGreen, bottomRadius: 44,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
          child: Column(children: [
            Row(children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(.3)),
                ),
                child: const Center(child: WaffarLogo(size: 42)),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('وفّرلي', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                Text('خصومات أكثر.. حياة أوفر', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ]),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(gradient: C.gradGold, borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: C.gold.withOpacity(.35), blurRadius: 14, offset: const Offset(0,4))]),
              child: const Text('✨ خصم ١٥٪ أوتوماتيكي عند كل طلب',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1200))),
            ),
          ]),
        ),
      ),
      // Buttons
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
        child: Column(children: [
          GradBtn(label: '👤  بوابة العملاء', onTap: onCustomer, gradient: C.gradGreenBtn),
          const SizedBox(height: 16),
          GradBtn(label: '🏪  بوابة الأعمال', onTap: onBusiness, gradient: C.gradPurple),
        ]),
      ),
      const SizedBox(height: 24),
      // Feature chips
      Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
        children: const [
          _Chip('🏬 خصومات لدى 1000+ محل', C.greenPale, C.greenDark),
          _Chip('📍 محلات قريبة منك', C.purplePale, C.purple),
          _Chip('💳 بطاقة رقمية فورية', C.goldPale, Color(0xFFa07800)),
        ],
      ),
      const Spacer(),
      const Padding(
        padding: EdgeInsets.only(bottom: 32),
        child: Text('🔒 المدفوعات محمية ومشفرة بالكامل',
            style: TextStyle(color: C.mutedLight, fontSize: 12)),
      ),
    ]),
  );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color tc;
  const _Chip(this.text, this.bg, this.tc);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
    child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tc)),
  );
}

// ─── SCREEN 3 — Phone ─────────────────────────────────────────────────────────
class PhoneScreen extends StatefulWidget {
  final void Function(String phone, String otp) onSent;
  final VoidCallback onBack;
  const PhoneScreen({super.key, required this.onSent, required this.onBack});
  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      GradHeader(
        gradient: C.gradGreen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_forward, color: Colors.white70, size: 18),
              label: const Text('رجوع', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('📱', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('أدخل رقم جوالك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('سنرسل لك رمز التحقق عبر SMS', style: TextStyle(fontSize: 13, color: Colors.white70)),
              ]),
            ]),
          ]),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('رقم الجوال', style: TextStyle(color: C.muted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // phone row
            Row(textDirection: TextDirection.ltr, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  color: C.card, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: C.border),
                  boxShadow: [BoxShadow(color: C.green.withOpacity(.08), blurRadius: 8)],
                ),
                child: const Text('🇸🇦 +966', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.textColor)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 3, color: C.textColor),
                  decoration: InputDecoration(
                    hintText: '5XXXXXXXX',
                    hintStyle: TextStyle(color: C.mutedLight, letterSpacing: 1),
                    filled: true, fillColor: C.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.green, width: 2)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            ValueListenableBuilder(
              valueListenable: _ctrl,
              builder: (_, val, __) => GradBtn(
                label: 'إرسال رمز التحقق ←',
                gradient: C.gradGreenBtn,
                onTap: val.text.length >= 9 ? () => widget.onSent(val.text, genOTP()) : null,
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('بالمتابعة توافق على الشروط وسياسة الخصوصية',
                style: TextStyle(color: C.mutedLight, fontSize: 12))),
          ]),
        ),
      ),
    ]),
  );
}

// ─── SCREEN 4 — OTP ───────────────────────────────────────────────────────────
class OtpScreen extends StatefulWidget {
  final String phone, otp;
  final VoidCallback onVerified, onBack;
  const OtpScreen({super.key, required this.phone, required this.otp, required this.onVerified, required this.onBack});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  bool _error = false;

  void _onChanged(int i, String val) {
    if (val.isNotEmpty && i < 5) { FocusScope.of(context).requestFocus(_nodes[i + 1]); }
    final code = _ctrls.map((c) => c.text).join();
    if (code.length == 6) {
      if (code == widget.otp) { Future.delayed(const Duration(milliseconds: 300), widget.onVerified); }
      else {
        setState(() => _error = true);
        Future.delayed(const Duration(milliseconds: 900), () {
          for (var c in _ctrls) c.clear();
          setState(() => _error = false);
          FocusScope.of(context).requestFocus(_nodes[0]);
        });
      }
    } else { setState(() {}); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      GradHeader(
        gradient: C.gradGreen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_forward, color: Colors.white70, size: 18),
              label: const Text('رجوع', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('🔐', style: TextStyle(fontSize: 24)))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('رمز التحقق', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('أُرسل الرمز إلى +966 ${widget.phone}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ]),
            ]),
          ]),
        ),
      ),
      Expanded(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // hint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: C.greenPale,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.green.withOpacity(.3)),
            ),
            child: Text('💡 الرمز التجريبي:  ${widget.otp}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.greenDark, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2)),
          ),
          const SizedBox(height: 24),
          // OTP boxes
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (i) {
              final filled = _ctrls[i].text.isNotEmpty;
              return Container(
                width: 48, height: 58, margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _ctrls[i], focusNode: _nodes[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center, maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: _error ? C.red : C.textColor,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _error ? C.red.withOpacity(.08) : filled ? C.greenPale : C.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _error ? C.red : C.border, width: 2.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _error ? C.red : filled ? C.green : C.border, width: 2.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _error ? C.red : C.green, width: 2.5)),
                  ),
                  onChanged: (v) => _onChanged(i, v),
                  onTap: () { _ctrls[i].selection = TextSelection.fromPosition(TextPosition(offset: _ctrls[i].text.length)); },
                ),
              );
            })),
          ),
          const SizedBox(height: 28),
          GhostBtn(label: 'إعادة الإرسال بعد ٠:٣٠', onTap: null, color: C.green),
        ]),
      )),
    ]),
  );
}

// ─── SCREEN 5 — Customer Dashboard ───────────────────────────────────────────
class CustomerDashboard extends StatefulWidget {
  final String phone;
  final VoidCallback onLogout;
  const CustomerDashboard({super.key, required this.phone, required this.onLogout});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _tab = 0;
  late final String _memberId;
  late final List<List<int>> _qr;

  final _purchases = const [
    {'place':'ديلامو كافيه',  'icon':'☕', 'amount':42.0,  'saved':6.30,  'date':'اليوم، ٢:١٥ م',  'cat':'مقهى'},
    {'place':'شاورما الأصيل','icon':'🥙', 'amount':35.0,  'saved':5.25,  'date':'أمس، ٨:٤٤ م',    'cat':'مطعم'},
    {'place':'ديلامو كافيه',  'icon':'☕', 'amount':55.0,  'saved':8.25,  'date':'٣ يونيو',          'cat':'مقهى'},
    {'place':'برغر هاوس',    'icon':'🍔', 'amount':78.0,  'saved':11.70, 'date':'١ يونيو',          'cat':'مطعم'},
    {'place':'ديلامو كافيه',  'icon':'☕', 'amount':38.0,  'saved':5.70,  'date':'٢٩ مايو',          'cat':'مقهى'},
  ];

  @override
  void initState() {
    super.initState();
    _memberId = genMemberNum();
    _qr = genQR(widget.phone + _memberId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      // Header
      GradHeader(gradient: C.gradGreen, child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        child: Row(children: [
          const WaffarLogo(size: 36),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('أهلاً بك 👋', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text('+966 ${widget.phone}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
          ]),
          const Spacer(),
          _outlineBtn('خروج', widget.onLogout),
        ]),
      )),

      // Body
      Expanded(child: IndexedStack(index: _tab, children: [
        _DashTab(phone: widget.phone, memberId: _memberId, qr: _qr),
        _PurchasesTab(purchases: _purchases),
        const _SavingsTab(),
      ])),

      // Bottom nav
      _BottomNav(active: _tab, onTap: (i) => setState(() => _tab = i)),
    ]),
  );

  Widget _outlineBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(.3)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
    ),
  );
}

class _BottomNav extends StatelessWidget {
  final int active;
  final void Function(int) onTap;
  const _BottomNav({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: C.border, width: 1.5)),
      boxShadow: [BoxShadow(color: C.green.withOpacity(.1), blurRadius: 24, offset: const Offset(0,-4))],
    ),
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 10),
    child: Row(children: [
      _NavItem(icon: '🏠', label: 'الرئيسية', active: active == 0, onTap: () => onTap(0)),
      _NavItem(icon: '🛍',  label: 'مشترياتي',  active: active == 1, onTap: () => onTap(1)),
      _NavItem(icon: '💰',  label: 'توفيراتي',  active: active == 2, onTap: () => onTap(2)),
    ]),
  );
}

class _NavItem extends StatelessWidget {
  final String icon, label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? C.green : C.mutedLight)),
        const SizedBox(height: 2),
        if (active) Container(width: 20, height: 3, decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(3))),
      ]),
    ),
  );
}

// Dashboard tab
class _DashTab extends StatelessWidget {
  final String phone, memberId;
  final List<List<int>> qr;
  const _DashTab({required this.phone, required this.memberId, required this.qr});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    child: Column(children: [
      // Stats row
      Row(children: [
        Expanded(child: AppCard(child: Column(children: [
          const Text('🏅', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 2),
          const Text('23', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.purple)),
          const Text('إجمالي الزيارات', style: TextStyle(fontSize: 11, color: C.muted)),
        ]))),
        const SizedBox(width: 12),
        Expanded(child: AppCard(child: Column(children: [
          const Text('💰', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 2),
          const Text('184', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.gold)),
          const Text('وفّرت (ر.س)', style: TextStyle(fontSize: 11, color: C.muted)),
        ]))),
      ]),
      const SizedBox(height: 16),

      // Membership card
      _MemberCard(memberId: memberId, qr: qr),
      const SizedBox(height: 16),

      // Wallet buttons
      Row(children: [
        Expanded(child: _walletBtn('🍎 Apple Wallet', Colors.black, Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: _walletBtn('🟡 Google Wallet', const Color(0xFF1A73E8), Colors.white)),
      ]),
    ]),
  );

  Widget _walletBtn(String label, Color bg, Color tc) => Container(
    height: 50,
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
    child: Center(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tc))),
  );
}

class _MemberCard extends StatelessWidget {
  final String memberId;
  final List<List<int>> qr;
  const _MemberCard({required this.memberId, required this.qr});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Column(children: [
      // Top — green
      Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(gradient: C.gradGreen),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Left info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width:38,height:38,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(11)),
                child: const Center(child: WaffarLogo(size: 24))),
              const SizedBox(width: 10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('وفّرلي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('خصومات أكثر.. حياة أوفر', style: TextStyle(fontSize: 10, color: Colors.white60)),
              ]),
            ]),
            const SizedBox(height: 14),
            _infoRow('🏬', 'خصومات لدى', '1000+ محل'),
            const SizedBox(height: 8),
            _infoRow('📍', 'محلات قريبة منك', ''),
          ])),
          const SizedBox(width: 12),
          // QR
          Column(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: C.green.withOpacity(.2), blurRadius: 12)]),
              child: SizedBox(width: 110, height: 110,
                child: CustomPaint(painter: QrPainter(grid: qr))),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(gradient: C.gradGold, borderRadius: BorderRadius.circular(8)),
              child: const Text('خصم ١٥٪ تلقائي', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1A1200))),
            ),
          ]),
        ]),
      ),
      // Bottom bar
      Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.green, C.greenDark])),
        child: Row(children: [
          Expanded(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(width:34,height:34,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(9)),
                child: const Center(child: Text('🪪', style: TextStyle(fontSize: 18)))),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('رقم العضوية', style: TextStyle(color: Colors.white60, fontSize: 10)),
                Text(memberId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
              ]),
            ]),
          )),
          Container(width:1, height:56, color: Colors.white.withOpacity(.15)),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(width:34,height:34,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(9)),
                child: const Center(child: Text('🏙', style: TextStyle(fontSize: 18)))),
              const SizedBox(width: 8),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('المحلات المشاركة', style: TextStyle(color: Colors.white60, fontSize: 10)),
                Text('1000+', style: TextStyle(color: C.gold, fontWeight: FontWeight.w900, fontSize: 15)),
              ]),
            ]),
          )),
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(gradient: C.gradGold),
            child: const Center(child: Text('🏙', style: TextStyle(fontSize: 24))),
          ),
        ]),
      ),
    ]),
  );

  Widget _infoRow(String icon, String title, String val) => Row(children: [
    Container(width:30,height:30,
      decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 15)))),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      if (val.isNotEmpty) Text(val, style: const TextStyle(color: C.gold, fontSize: 13, fontWeight: FontWeight.w900)),
    ]),
  ]);
}

// Purchases tab
class _PurchasesTab extends StatelessWidget {
  final List<Map<String,dynamic>> purchases;
  const _PurchasesTab({required this.purchases});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    children: [
      const Text('🛍 سجل مشترياتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.textColor)),
      const SizedBox(height: 14),
      ...purchases.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(child: Row(children: [
          Container(width:46,height:46, decoration: BoxDecoration(color:C.greenPale, borderRadius: BorderRadius.circular(13)),
            child: Center(child: Text(p['icon'], style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['place'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.textColor)),
            Text('${p['date']} · ${p['cat']}', style: const TextStyle(color: C.muted, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${p['amount'].toInt()} ر.س', style: const TextStyle(fontWeight: FontWeight.w800, color: C.textColor)),
            Text('وفّرت ${p['saved']} ر.س', style: const TextStyle(color: C.green, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ])),
      )),
    ],
  );
}

// Savings tab
class _SavingsTab extends StatelessWidget {
  const _SavingsTab();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    children: [
      const Text('💰 توفيراتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.textColor)),
      const SizedBox(height: 14),
      // Total card
      AppCard(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [C.greenPale, Colors.white]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.green.withOpacity(.2)),
        ),
        child: const Column(children: [
          Text('إجمالي ما وفّرته', style: TextStyle(color: C.muted, fontSize: 14)),
          SizedBox(height: 4),
          Text('184.50', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: C.green)),
          Text('ريال سعودي 🎉', style: TextStyle(color: C.green, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ),
      const SizedBox(height: 14),
      // Bar chart
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('التوفير الشهري', style: TextStyle(fontWeight: FontWeight.w700, color: C.textColor)),
        const SizedBox(height: 14),
        SizedBox(height: 80,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (int i = 0; i < 6; i++) ...[
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Expanded(child: FractionallySizedBox(
                  heightFactor: [22,18,35,28,42,40][i] / 42,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: i == 5 ? null : C.green.withOpacity(.25),
                      gradient: i == 5 ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.green, C.greenDeep]) : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                )),
                const SizedBox(height: 4),
                Text(['يناير','فبراير','مارس','أبريل','مايو','يونيو'][i].substring(0,3),
                    style: const TextStyle(fontSize: 9, color: C.muted)),
              ])),
              if (i < 5) const SizedBox(width: 7),
            ],
          ]),
        ),
      ])),
      const SizedBox(height: 14),
      // By category
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('حسب النوع', style: TextStyle(fontWeight: FontWeight.w700, color: C.textColor)),
        const SizedBox(height: 14),
        _CategoryBar('مقاهي ☕', 112.5, .61, C.green),
        const SizedBox(height: 12),
        _CategoryBar('مطاعم 🍽', 72, .39, C.purple),
      ])),
    ],
  );
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final double saved, pct;
  final Color color;
  const _CategoryBar(this.label, this.saved, this.pct, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.textColor)),
      Text('$saved ر.س', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    ]),
    const SizedBox(height: 6),
    ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: LinearProgressIndicator(
        value: pct, minHeight: 7,
        backgroundColor: C.border,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    ),
  ]);
}

// ─── SCREEN 6 — Business Portal ───────────────────────────────────────────────
class BusinessPortal extends StatefulWidget {
  final VoidCallback onLogout;
  const BusinessPortal({super.key, required this.onLogout});
  @override
  State<BusinessPortal> createState() => _BusinessPortalState();
}

class _BusinessPortalState extends State<BusinessPortal> {
  bool _loggedIn = false;
  String _brand = '';
  String _type  = '';
  final _brandCtrl = TextEditingController();

  final _scans = const [
    {'time':'٢:١٥ م',   'name':'+966 55 ****66', 'saved':6.30,  'amount':42},
    {'time':'١:٥٠ م',   'name':'+966 50 ****12', 'saved':5.25,  'amount':35},
    {'time':'١:٢٢ م',   'name':'+966 54 ****88', 'saved':12.00, 'amount':80},
    {'time':'١٢:٤٥ م',  'name':'+966 59 ****34', 'saved':4.50,  'amount':30},
    {'time':'١١:٣٠ ص',  'name':'+966 56 ****77', 'saved':7.50,  'amount':50},
  ];

  @override
  Widget build(BuildContext context) => _loggedIn ? _dashboard() : _login();

  Widget _login() => Scaffold(
    backgroundColor: C.bg,
    body: Column(children: [
      GradHeader(gradient: C.gradPurple, child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.arrow_forward, color: Colors.white70, size: 18),
            label: const Text('رجوع', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Container(width:52,height:52,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(15)),
              child: const Center(child: Text('🏪', style: TextStyle(fontSize: 26)))),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('بوابة الأعمال', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('سجّل منشأتك واحصل على عملاء أكثر', style: TextStyle(fontSize: 13, color: Colors.white70)),
            ]),
          ]),
        ]),
      )),
      Expanded(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('اسم المنشأة', style: TextStyle(color: C.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _brandCtrl,
            style: const TextStyle(fontSize: 16, color: C.textColor),
            decoration: InputDecoration(
              hintText: 'مثال: ديلامو كافيه',
              hintStyle: const TextStyle(color: C.mutedLight),
              filled: true, fillColor: C.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.purple, width: 2)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          const Text('نوع المنشأة', style: TextStyle(color: C.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _typeBtn('cafe', 'مقهى ☕')),
            const SizedBox(width: 12),
            Expanded(child: _typeBtn('restaurant', 'مطعم 🍽')),
          ]),
          const SizedBox(height: 28),
          ValueListenableBuilder(
            valueListenable: _brandCtrl,
            builder: (_, val, __) => GradBtn(
              label: 'الدخول إلى لوحة التحكم ←',
              gradient: C.gradPurple,
              onTap: val.text.isNotEmpty && _type.isNotEmpty
                ? () { setState(() { _brand = val.text; _loggedIn = true; }); }
                : null,
            ),
          ),
        ]),
      )),
    ]),
  );

  Widget _typeBtn(String val, String label) => GestureDetector(
    onTap: () => setState(() => _type = val),
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: _type == val ? C.purplePale : C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _type == val ? C.purple : C.border, width: 2.5),
      ),
      child: Center(child: Text(label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _type == val ? C.purple : C.textColor))),
    ),
  );

  Widget _dashboard() {
    final total   = _scans.fold(0.0, (a, s) => a + (s['amount'] as num));
    final savings = _scans.fold(0.0, (a, s) => a + (s['saved'] as num));

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(children: [
        GradHeader(gradient: C.gradPurple, child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Row(children: [
            const WaffarLogo(size: 36),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('لوحة الأعمال · ${_type=="cafe"?"مقهى ☕":"مطعم 🍽"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(_brand, style: const TextStyle(color: C.gold, fontWeight: FontWeight.w900, fontSize: 20)),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() { _loggedIn=false; _brand=''; _type=''; _brandCtrl.clear(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(.3))),
                child: const Text('خروج', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ]),
        )),
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          children: [
            // Stats
            Row(children: [
              Expanded(child: AppCard(child: Column(children: [
                const Text('📡', style: TextStyle(fontSize: 26)),
                Text('${_scans.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.purple)),
                const Text('مسح اليوم', style: TextStyle(fontSize: 11, color: C.muted)),
              ]))),
              const SizedBox(width: 12),
              Expanded(child: AppCard(child: Column(children: [
                const Text('💳', style: TextStyle(fontSize: 26)),
                Text('${total.toInt()} ر.س', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.green)),
                const Text('إجمالي المبيعات', style: TextStyle(fontSize: 11, color: C.muted)),
              ]))),
            ]),
            const SizedBox(height: 14),
            AppCard(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [C.greenPale, Colors.white]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.green.withOpacity(.2)),
              ),
              child: Column(children: [
                const Text('إجمالي خصومات العملاء اليوم', style: TextStyle(color: C.muted, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${savings.toStringAsFixed(2)} ر.س', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: C.green)),
                const Text('✦ ١٥٪ خصم تلقائي لكل عميل مسجّل', style: TextStyle(color: C.muted, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 14),
            const Text('📡 مسح اليوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.textColor)),
            const SizedBox(height: 10),
            ..._scans.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(child: Row(children: [
                Container(width:40,height:40,
                  decoration: BoxDecoration(color: C.purplePale, borderRadius: BorderRadius.circular(11)),
                  child: const Center(child: Text('👤', style: TextStyle(fontSize: 18)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: C.textColor)),
                  Text(s['time'] as String, style: const TextStyle(color: C.muted, fontSize: 12)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${s['amount']} ر.س', style: const TextStyle(fontWeight: FontWeight.w800, color: C.textColor)),
                  Text('−${s['saved']} ر.س', style: const TextStyle(color: C.green, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ])),
            )),
            const SizedBox(height: 6),
            Opacity(opacity: .65, child: AppCard(child: Column(children: [
              const Text('🚀 ميزات قادمة (الإصدار ٢.٠)', style: TextStyle(color: C.muted, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ...['تحليلات متقدمة 📊','إشعارات العملاء 🔔','نظام النقاط والمكافآت ⭐','التكامل مع POS 💻']
                .map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: C.purplePale, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(f, style: const TextStyle(color: C.purple, fontSize: 13, fontWeight: FontWeight.w600))),
                )),
            ]))),
          ],
        )),
      ]),
    );
  }
}
