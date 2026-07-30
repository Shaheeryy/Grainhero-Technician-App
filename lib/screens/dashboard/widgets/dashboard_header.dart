import 'package:flutter/material.dart';
import '../../../../config/grainhero_colors.dart';
import '../../../../widgets/dashboard/dashboard_widgets.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.techName,
    required this.alertsCount,
    required this.onQrPressed,
    required this.onAlertsPressed,
    required this.silosCount,
    required this.batchesCount,
    required this.sensorsCount,
  });

  final String techName;
  final int alertsCount;
  final VoidCallback onQrPressed;
  final VoidCallback onAlertsPressed;
  final int silosCount;
  final int batchesCount;
  final int sensorsCount;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 14, 16, 32),
      decoration: BoxDecoration(
        color: GrainHeroColors.dark,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(56)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: GrainHeroColors.surfaceContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: GrainHeroColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: GrainHeroColors.bodyText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  techName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.qr_code_scanner_rounded,
                tooltip: 'Scan QR code',
                onPressed: onQrPressed,
              ),
              const SizedBox(width: 8),
              _NotificationButton(
                onPressed: onAlertsPressed,
                alertsCount: alertsCount,
              ),
            ],
          ),
          const SizedBox(height: 24),
          StatusOverview(
            silosCount: silosCount,
            alertsCount: alertsCount,
            batchesCount: batchesCount,
            sensorsCount: sensorsCount,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        fixedSize: const Size(42, 42),
        backgroundColor: Colors.white.withValues(alpha: 0.10),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),
      icon: Icon(icon),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.onPressed,
    required this.alertsCount,
  });

  final VoidCallback onPressed;
  final int alertsCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onPressed: onPressed,
        ),
        if (alertsCount > 0)
          Positioned(
            top: 3,
            right: 3,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GrainHeroColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: GrainHeroColors.dark, width: 1.5),
              ),
              child: Text(
                alertsCount > 9 ? '9+' : alertsCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
