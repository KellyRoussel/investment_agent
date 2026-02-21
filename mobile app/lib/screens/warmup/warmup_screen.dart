import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/warmup_provider.dart';

class WarmupScreen extends StatefulWidget {
  const WarmupScreen({super.key});

  @override
  State<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends State<WarmupScreen>
    with SingleTickerProviderStateMixin {
  int _dotCount = 1;
  Timer? _dotTimer;
  bool _showAnswer = false;
  ContentItem? _displayedItem;
  Timer? _answerRevealTimer;

  @override
  void initState() {
    super.initState();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount % 3) + 1);
    });
  }

  void _onNewContent(ContentItem item) {
    _answerRevealTimer?.cancel();
    setState(() {
      _displayedItem = item;
      _showAnswer = !item.isTrivia;
    });
    if (item.isTrivia && item.label != null) {
      _answerRevealTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showAnswer = true);
      });
    }
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    _answerRevealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WarmupProvider>(
      builder: (context, warmup, _) {
        final item = warmup.currentContent;

        if (item != null && item != _displayedItem) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onNewContent(item);
          });
        }

        final dots = '.' * _dotCount;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.gradientCyanPurple.createShader(bounds),
                    child: const Text(
                      'InvestTrack',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Starting up$dots',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Content card
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: _displayedItem == null
                        ? const SizedBox(
                            key: ValueKey('empty'),
                            height: 160,
                          )
                        : _ContentCard(
                            key: ValueKey(_displayedItem!.content),
                            item: _displayedItem!,
                            showAnswer: _showAnswer,
                          ),
                  ),

                  const Spacer(flex: 1),

                  // Polling status
                  Text(
                    warmup.failCount == 0
                        ? 'Connecting to server\u2026'
                        : 'Connecting\u2026 (attempt ${warmup.failCount + 1})',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.border,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentItem item;
  final bool showAnswer;

  const _ContentCard({super.key, required this.item, required this.showAnswer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.isTrivia ? 'Did you know?' : 'Quote',
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Content text
          Text(
            item.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),

          // Author / answer
          if (item.label != null) ...[
            const SizedBox(height: 12),
            AnimatedOpacity(
              opacity: showAnswer ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                item.isTrivia ? 'Answer: ${item.label}' : item.label!,
                style: TextStyle(
                  color: item.isTrivia ? AppColors.cyan : AppColors.textSecondary,
                  fontSize: 13,
                  fontStyle:
                      item.isTrivia ? FontStyle.normal : FontStyle.italic,
                  fontWeight:
                      item.isTrivia ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
