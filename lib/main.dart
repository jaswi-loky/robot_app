import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;

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

  // 新增speed变量
  double speed = 0.7;

  // 机器人控制相关
  Timer? _timer;
  DateTime? _pressTime;

  static const String baseUrl = 'http://192.168.10.10:9001/api/joy_control';

  Future<void> sendCommand(double angular, double linear) async {
    final url = Uri.parse(
        '$baseUrl?angular_velocity=$angular&linear_velocity=$linear');
    try {
      await http.get(url);
    } catch (e) {
      // 可以加日志
    }
  }

  Future<void> stopRobot() async {
    await sendCommand(0, 0);
  }

  void handlePress(String label) {
    _pressTime = DateTime.now();
    _timer?.cancel();

    Duration period = const Duration(milliseconds: 100);

    if (label == 'F') {
      // 一直前进
      sendCommand(0, speed);
      _timer = Timer.periodic(period, (_) {
        sendCommand(0, speed);
      });
    } else if (label == 'B') {
      // B：<=4秒一直转动，>4秒前4秒转动，后面前进
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
      // 左：<=2秒一直转动，>2秒前2秒转动，后面前进
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
      // 右：<=2秒一直负角速度转动，>2秒前2秒转动，后面前进
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
      // FL：<=1秒一直转动，>1秒前1秒转动，后面前进
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
      // FR：<=1秒一直负角速度转动，>1秒前1秒转动，后面前进
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
    _timer?.cancel();
    await stopRobot();
    _pressTime = null;
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
              // 圆形方向按钮
              DirectionPad(
                onDirectionPressed: (dir) {
                  debugPrint('Pressed: $dir');
                },
                // 改动1：Stop按钮功能，调用stopRobot
                onCenterPressed: () async {
                  await stopRobot();
                  debugPrint('Pressed: 停');
                },
                color: black,
                onDirectionTapDown: handlePress,
                onDirectionTapUp: handleRelease,
              ),
              const SizedBox(height: 80),
              // 速度选项
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
              // 说明文字
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                     '''Stop button: If a bug occurs (e.g., the robot keeps moving even after the button is released),
pressing "Stop" will halt the robot.''',
                    style: TextStyle(
                      color: black,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.left,
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
              // 根据选择设置speed变量
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

class DirectionPad extends StatelessWidget {
  final void Function(String direction) onDirectionPressed;
  final VoidCallback onCenterPressed;
  final Color color;
  final void Function(String label)? onDirectionTapDown;
  final void Function(String label)? onDirectionTapUp;

  DirectionPad({
    required this.onDirectionPressed,
    required this.onCenterPressed,
    required this.color,
    this.onDirectionTapDown,
    this.onDirectionTapUp,
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
    double size = 320 * 1.5;
    double innerCircle = 140 * 1.2;
    double directionFontSize = 32;
    double stopFontSize = 44 * 1.2;
    double btnWidth = 56 * 1.2;
    double btnHeight = 56 * 1.2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 大圆背景
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
          ),
          // 8个方向按钮
          ..._labels.asMap().entries.map((entry) {
            final label = entry.value;
            double rad = label.angle * pi / 180;
            double r = size / 2 - 36 * 1.5;
            double cx = (size / 2) + r * sin(rad);
            double cy = (size / 2) - r * cos(rad);

            // 绑定长按控制（所有8个方向按钮都支持）
            bool isControl = true;

            return Positioned(
              left: cx - btnWidth / 2,
              top: cy - btnHeight / 2,
              child: GestureDetector(
                onTap: () => onDirectionPressed(label.text),
                onTapDown: isControl && onDirectionTapDown != null
                    ? (_) => onDirectionTapDown!(label.text)
                    : null,
                onTapUp: isControl && onDirectionTapUp != null
                    ? (_) => onDirectionTapUp!(label.text)
                    : null,
                onTapCancel: isControl && onDirectionTapUp != null
                    ? () => onDirectionTapUp!(label.text)
                    : null,
                child: Container(
                  width: btnWidth,
                  height: btnHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(btnHeight / 2),
                  ),
                  child: Text(
                    label.text,
                    style: TextStyle(
                      color: color,
                      fontSize: directionFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            );
          }).toList(),
          // 小圆背景
          Container(
            width: innerCircle,
            height: innerCircle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              color: Colors.white,
            ),
          ),
          // 中间“停”按钮
          GestureDetector(
            // 改动2：Stop按钮功能，调用onCenterPressed
            onTap: onCenterPressed,
            child: Container(
              width: innerCircle - 10,
              height: innerCircle - 10,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Text(
                'Stop',
                style: TextStyle(
                  color: color,
                  fontSize: stopFontSize,
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