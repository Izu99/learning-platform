import 'package:flutter/material.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/modern_avatar.dart';

class LiveSessionScreen extends StatefulWidget {
  final String studentName;
  final String topic;
  final String? level;
  final String? imageUrl;

  const LiveSessionScreen({super.key, required this.studentName, required this.topic, this.level, this.imageUrl});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  bool _isMicOn = true;
  bool _isCamOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Live Session'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(32),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1571260899304-425eee4c7efc?w=800&q=80'),
                    fit: BoxFit.cover,
                    opacity: 0.4,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 20, left: 20,
                      child: StatusBadge(label: 'CONNECTED', color: AppTheme.primaryTeal),
                    ),
                    const Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 40),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ModernCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                ModernAvatar(
                  imageUrl: widget.imageUrl,
                  fallbackText: widget.studentName,
                  radius: 24,
                ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(widget.topic, style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  if (widget.level != null)
                    StatusBadge(label: widget.level!.toUpperCase(), color: AppTheme.primaryBlue),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                  active: _isMicOn,
                  onTap: () => setState(() => _isMicOn = !_isMicOn),
                ),
                const SizedBox(width: 20),
                _ControlButton(
                  icon: _isCamOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                  active: _isCamOn,
                  onTap: () => setState(() => _isCamOn = !_isCamOn),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(color: AppTheme.accentRed, shape: BoxShape.circle),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            EduPrimaryButton(
              label: 'Start Zoom Meeting',
              onPressed: () {},
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? Colors.white : AppTheme.textMuted.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: active ? AppTheme.primaryBlue : AppTheme.textSecondary, size: 24),
      ),
    );
  }
}
