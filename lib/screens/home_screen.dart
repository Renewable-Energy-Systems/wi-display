import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors pulled from SVG
    const blueMain = Color(0xFF0A66FF); // header + bottom bar
    const bgGradientTop = Color(0xFFF7FAFF); // page bg start
    const bgGradientBottom = Color(0xFFF2F6FF); // page bg end
    const cardBorder = Color(0xFFE6ECFF);
    const panelBorder = Color(0xFFE1E8FF);
    const headingText = Color(0xFF1C3366); // "Sensor Information" etc.
    const labelText = Color(0xFF5A6B8A); // labels in left card
    const valueText = Color(0xFF103B8C); // values in left card
    const captionText = Color(0xFF7A8AA6); // "Updated: ..."
    const dewBg = Color(0xFFF4F8FF); // right card bg
    const dewBorder = Color(0xFFDFE8FF);
    const dewLabelText = Color(0xFF1C3FAA); // "Dew Point"
    const dewBigNumber = Color(0xFF0A66FF); // 20°C
    const liveGreen = Color(0xFF247A3E); // "Live"

    // Hardcoded demo values (later -> API)
    const workstationName = 'WS-001';
    const probeId = 'PRB-2024-001';
    const calibrationDate = '15/01/2024';
    const calibrationDue = '15/01/2025';
    const updatedAt = '27/09/2025 11:41';
    const dewPointDisplay = '20°C';

    return Container(
      // full-screen background gradient like SVG
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgGradientTop, bgGradientBottom],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // ===== Top App Bar =====
              _TopHeader(blueMain: blueMain),

              const SizedBox(height: 16),

              // ===== Main White Panel with 2 cards inside =====
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: panelBorder, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // We want two columns: left card (400w) and right card (~380w)
                      // On tablet landscape this will be fine in a Row.
                      // If screen gets too narrow, we'll wrap to Column just to avoid overflow.
                      final isNarrow = constraints.maxWidth < 780;
                      final inner = isNarrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SensorCard(
                                  headingText: headingText,
                                  labelText: labelText,
                                  valueText: valueText,
                                  captionText: captionText,
                                  cardBorder: cardBorder,
                                  workstationName: workstationName,
                                  probeId: probeId,
                                  calibrationDate: calibrationDate,
                                  calibrationDue: calibrationDue,
                                  updatedAt: updatedAt,
                                ),
                                const SizedBox(height: 24),
                                _DewPointCard(
                                  dewBg: dewBg,
                                  dewBorder: dewBorder,
                                  dewLabelText: dewLabelText,
                                  dewBigNumber: dewBigNumber,
                                  liveGreen: liveGreen,
                                  dewPointDisplay: dewPointDisplay,
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left card ~400 wide
                                Flexible(
                                  flex: 4,
                                  child: _SensorCard(
                                    headingText: headingText,
                                    labelText: labelText,
                                    valueText: valueText,
                                    captionText: captionText,
                                    cardBorder: cardBorder,
                                    workstationName: workstationName,
                                    probeId: probeId,
                                    calibrationDate: calibrationDate,
                                    calibrationDue: calibrationDue,
                                    updatedAt: updatedAt,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Right card ~380 wide
                                Flexible(
                                  flex: 4,
                                  child: _DewPointCard(
                                    dewBg: dewBg,
                                    dewBorder: dewBorder,
                                    dewLabelText: dewLabelText,
                                    dewBigNumber: dewBigNumber,
                                    liveGreen: liveGreen,
                                    dewPointDisplay: dewPointDisplay,
                                  ),
                                ),
                              ],
                            );
                      return inner;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== Bottom blue strip =====
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: blueMain,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.blueMain});

  final Color blueMain;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: blueMain,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // SVG filter: subtle shadow (0,2,4, 0.12)
          BoxShadow(
            color: const Color(0x1F1B2B65), // rgba-ish: #1b2b65 with ~0.12
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left: blue circle icon that mimics the <image> in SVG.
          // We'll fake a circular brand badge here.
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'RES',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Center title
          Expanded(
            child: Text(
              'Renewable Energy Systems Limited',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Right spacer (to balance left icon)
          const SizedBox(width: 72), // same-ish width as icon+gap
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.headingText,
    required this.labelText,
    required this.valueText,
    required this.captionText,
    required this.cardBorder,
    required this.workstationName,
    required this.probeId,
    required this.calibrationDate,
    required this.calibrationDue,
    required this.updatedAt,
  });

  final Color headingText;
  final Color labelText;
  final Color valueText;
  final Color captionText;
  final Color cardBorder;

  final String workstationName;
  final String probeId;
  final String calibrationDate;
  final String calibrationDue;
  final String updatedAt;

  TextStyle get _headingStyle =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: headingText);

  TextStyle get _labelStyle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: labelText,
  );

  TextStyle get _valueStyle => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.3,
    color: valueText,
  );

  TextStyle get _captionStyle =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: captionText);

  @override
  Widget build(BuildContext context) {
    return Container(
      // ~400 x 336 in SVG
      constraints: const BoxConstraints(
        minWidth: 320,
        maxWidth: 480,
        minHeight: 200,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // cardGrad in SVG was subtle white -> very light blue.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: const [
          // elev2 style
          BoxShadow(
            color: Color.fromARGB(31, 27, 43, 101), // #1b2b65 @~0.12
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text('Sensor Information', style: _headingStyle),
          const SizedBox(height: 24),

          // Info rows block
          _twoColRow('Workstation name:', workstationName),
          const SizedBox(height: 16),
          _twoColRow('Probe ID:', probeId),
          const SizedBox(height: 16),
          _twoColRow('Calibration Date:', calibrationDate),
          const SizedBox(height: 16),
          _twoColRow('Calibration Due:', calibrationDue),
          const SizedBox(height: 24),

          // EXTRA: Glovebox status block (not in the SVG,
          // but you said you'll show glovebox info later from API.
          // I'm placing it here cleanly so it's ready.)
          // Text('Glovebox Status:', style: _labelStyle),
          // const SizedBox(height: 6),
          const Spacer(),

          // Updated timestamp at bottom-left
          Text('Updated: $updatedAt', style: _captionStyle),
        ],
      ),
    );
  }

  Widget _twoColRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // left label
        Expanded(flex: 2, child: Text(label, style: _labelStyle)),
        const SizedBox(width: 12),
        // right value
        Expanded(flex: 3, child: Text(value, style: _valueStyle)),
      ],
    );
  }
}

class _DewPointCard extends StatelessWidget {
  const _DewPointCard({
    required this.dewBg,
    required this.dewBorder,
    required this.dewLabelText,
    required this.dewBigNumber,
    required this.liveGreen,
    required this.dewPointDisplay,
  });

  final Color dewBg;
  final Color dewBorder;
  final Color dewLabelText;
  final Color dewBigNumber;
  final Color liveGreen;

  final String dewPointDisplay;

  TextStyle get _headingStyle =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: dewLabelText);

  TextStyle get _bigNumberStyle => TextStyle(
    fontSize: 108,
    fontWeight: FontWeight.w900,
    height: 1.0,
    color: dewBigNumber,
    letterSpacing: -2,
  );

  TextStyle get _liveStyle =>
      TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: liveGreen);

  @override
  Widget build(BuildContext context) {
    return Container(
      // ~380 x 336 in SVG
      constraints: const BoxConstraints(
        minWidth: 300,
        maxWidth: 480,
        minHeight: 200,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dewBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dewBorder, width: 1),
        boxShadow: const [
          // elev3: stronger shadow
          BoxShadow(
            color: Color.fromARGB(41, 27, 43, 101), // #1b2b65 @~0.16
            offset: Offset(0, 8),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        children: [
          // Row with icon + "Dew Point"
          Row(
            children: [
              // little droplet icon approximating SVG path
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A8DFF).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.opacity_rounded,
                  size: 20,
                  color: const Color(0xFF5A8DFF),
                ),
              ),
              const SizedBox(width: 12),
              Text('Dew Point', style: _headingStyle),
            ],
          ),

          const Spacer(),

          // Big centered dew point number
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dewPointDisplay,
              style: _bigNumberStyle,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Live indicator row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF1F9D55), // ~green dot
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('Live', style: _liveStyle),
            ],
          ),
        ],
      ),
    );
  }
}
