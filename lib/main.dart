import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const UIApp());
}

class UIApp extends StatelessWidget {
  const UIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Project',
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum Speed { slow, normal, fast }

class _HomePageState extends State<HomePage> {
  Speed _selectedSpeed = Speed.normal;
  double speed = 0.7;
  Timer? _timer;
  DateTime? _pressTime;

  final Map<String, bool> _buttonPressed = {
    'F': false, 'B': false, 'L': false, 'R': false,
    'FL': false, 'FR': false, 'BL': false, 'BR': false,
  };

  double _lastLinear = 0;
  double _lastAngular = 0;
  bool _estopActive = false;

  static const String baseUrl = 'http://192.168.10.10:9001/api/joy_control';

  Future<void> sendCommand(double angular, double linear) async {
    _lastAngular = angular;
    _lastLinear = linear;
    final url = Uri.parse(
        '$baseUrl?angular_velocity=$angular&linear_velocity=$linear');
    try {
      await http.get(url);
    } catch (e) {}
  }

  Future<void> toggleEstop() async {
    setState(() {
      _estopActive = !_estopActive;
    });
    final flag = _estopActive ? 'true' : 'false';
    final url = Uri.parse('http://192.168.10.10:9001/api/estop?flag=$flag');
    try {
      await http.get(url);
    } catch (e) {}
  }

  void handlePress(String label) {
    setState(() {
      _buttonPressed[label] = true;
    });
    _pressTime = DateTime.now();
    _timer?.cancel();

    Duration period = const Duration(milliseconds: 100);

    if (label == 'F') {
      sendCommand(0, speed);
      _timer = Timer.periodic(period, (_) {
        sendCommand(0, speed);
      });
    } else if (label == 'B') {
      sendCommand(3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 4000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'L') {
      sendCommand(3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 2000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'R') {
      sendCommand(-3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 2000) {
          sendCommand(-3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'FL') {
      sendCommand(3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 1000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'FR') {
      sendCommand(-3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 1000) {
          sendCommand(-3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'BL') {
      sendCommand(3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 3000) {
          sendCommand(3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    } else if (label == 'BR') {
      sendCommand(-3.1415926 / 4, 0);
      _timer = Timer.periodic(period, (timer) {
        final elapsed = DateTime.now().difference(_pressTime!).inMilliseconds;
        if (elapsed <= 3000) {
          sendCommand(-3.1415926 / 4, 0);
        } else {
          sendCommand(0, speed);
        }
      });
    }
  }

  void handleRelease(String label) async {
    setState(() {
      _buttonPressed[label] = false;
    });
    _timer?.cancel();

    if (_lastAngular == 0 && _lastLinear.abs() > 0.01) {
      double currentLinear = _lastLinear;
      double step = currentLinear.abs() / 10;
      if (step < 0.01) step = 0.01;
      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (currentLinear.abs() <= 0.01) {
          sendCommand(0, 0);
          timer.cancel();
        } else {
          if (currentLinear > 0) {
            currentLinear -= step;
            if (currentLinear < 0) currentLinear = 0;
          } else {
            currentLinear += step;
            if (currentLinear > 0) currentLinear = 0;
          }
          sendCommand(0, currentLinear);
        }
      });
    } else {
      await sendCommand(0, 0);
    }
    _pressTime = null;
  }

  void _openWebPageInApp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WebPageScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color black = Colors.black;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DirectionPad(
                onDirectionPressed: (dir) {
                  debugPrint('Pressed: $dir');
                },
                onCenterPressed: toggleEstop,
                color: black,
                onDirectionTapDown: handlePress,
                onDirectionTapUp: handleRelease,
                estopActive: _estopActive,
                buttonPressed: _buttonPressed,
              ),
              const SizedBox(height: 80),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Speed：',
                        style: TextStyle(color: black, fontSize: 24),
                      ),
                      const SizedBox(width: 20),
                      _buildSpeedOption('slow', Speed.slow, black),
                      const SizedBox(width: 24),
                      _buildSpeedOption('normal', Speed.normal, black),
                      const SizedBox(width: 24),
                      _buildSpeedOption('fast', Speed.fast, black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                     '''ESTOP: Press to lock the robot - other direction buttons will be disabled and the background turns red. Press again to unlock.''',
                    style: TextStyle(
                      color: black,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _openWebPageInApp,
                  child: Container(
                    width: 180,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: black, width: 2),
                      borderRadius: BorderRadius.circular(32),
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Text(
                        'Webpage',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '0',
                  style: TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedOption(String label, Speed value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 22),
        ),
        Radio<Speed>(
          value: value,
          groupValue: _selectedSpeed,
          activeColor: color,
          onChanged: (Speed? v) {
            setState(() {
              _selectedSpeed = v!;
              if (_selectedSpeed == Speed.slow) {
                speed = 0.4;
              } else if (_selectedSpeed == Speed.normal) {
                speed = 0.7;
              } else if (_selectedSpeed == Speed.fast) {
                speed = 1.0;
              }
            });
          },
        ),
      ],
    );
  }
}

class WebPageScreen extends StatefulWidget {
  const WebPageScreen({super.key});

  @override
  State<WebPageScreen> createState() => _WebPageScreenState();
}

class _WebPageScreenState extends State<WebPageScreen> {
  bool _isLoading = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            _isLoading = true;
          });
        },
        onPageFinished: (url) {
          setState(() {
            _isLoading = false;
          });
        },
      ))
      ..loadRequest(Uri.parse('http://192.168.10.10:8085'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebPage'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class DirectionPad extends StatelessWidget {
  final void Function(String direction) onDirectionPressed;
  final VoidCallback onCenterPressed;
  final Color color;
  final void Function(String label)? onDirectionTapDown;
  final void Function(String label)? onDirectionTapUp;
  final bool estopActive;
  final Map<String, bool> buttonPressed;

  DirectionPad({
    required this.onDirectionPressed,
    required this.onCenterPressed,
    required this.color,
    this.onDirectionTapDown,
    this.onDirectionTapUp,
    this.estopActive = false,
    required this.buttonPressed,
  });

  final List<_DirectionLabel> _labels = const [
    _DirectionLabel('F', 0),
    _DirectionLabel('FR', 45),
    _DirectionLabel('R', 90),
    _DirectionLabel('BR', 135),
    _DirectionLabel('B', 180),
    _DirectionLabel('BL', 225),
    _DirectionLabel('L', 270),
    _DirectionLabel('FL', 315),
  ];

  @override
  Widget build(BuildContext context) {
    double screen = MediaQuery.of(context).size.shortestSide;
    double size = screen * 0.7;
    double innerCircle = size * 0.36;
    double directionFontSize = size * 0.09;
    Color pressedColor = Colors.red;
    Color pressedBg = const Color(0xFFFFA0A0);
    double highlightRadius = size * 0.12;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
          ),
          ..._labels.map((label) {
            double rad = label.angle * pi / 180;
            double r = size/2 - highlightRadius - 12;
            double cx = (size / 2) + r * sin(rad);
            double cy = (size / 2) - r * cos(rad);
            bool isPressed = buttonPressed[label.text] ?? false;

            return Positioned(
              left: cx - highlightRadius,
              top: cy - highlightRadius,
              child: GestureDetector(
                onTap: () => onDirectionPressed(label.text),
                onTapDown: onDirectionTapDown != null
                    ? (_) => onDirectionTapDown!(label.text)
                    : null,
                onTapUp: onDirectionTapUp != null
                    ? (_) => onDirectionTapUp!(label.text)
                    : null,
                onTapCancel: onDirectionTapUp != null
                    ? () => onDirectionTapUp!(label.text)
                    : null,
                child: Container(
                  width: highlightRadius * 2,
                  height: highlightRadius * 2,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isPressed)
                        Container(
                          width: highlightRadius * 2,
                          height: highlightRadius * 2,
                          decoration: BoxDecoration(
                            color: pressedBg,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        label.text,
                        style: TextStyle(
                          color: isPressed ? pressedColor : color,
                          fontSize: directionFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: onCenterPressed,
            child: Container(
              width: innerCircle,
              height: innerCircle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: estopActive ? pressedBg : Colors.white,
                border: Border.all(
                  color: estopActive ? Colors.red : color,
                  width: 4,
                ),
              ),
              child: Text(
                'ESTOP',
                style: TextStyle(
                  color: estopActive ? Colors.red : color,
                  fontSize: 44 * 0.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionLabel {
  final String text;
  final double angle;

  const _DirectionLabel(this.text, this.angle);
}