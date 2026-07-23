import 'package:flutter/material.dart';
import '../config/auth_theme.dart';

// ============================================================
// STATUS OVERVIEW
// ============================================================

class StatusOverview extends StatelessWidget {
  const StatusOverview({
    super.key,
    required this.silosCount,
    required this.alertsCount,
    required this.batchesCount,
    required this.sensorsCount,
  });

  final int silosCount;
  final int alertsCount;
  final int batchesCount;
  final int sensorsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      decoration: BoxDecoration(
        color: AuthTheme.darkContainer,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: StatusItem(
              icon: Icons.storage_rounded,
              iconColor: const Color(0xFF39D20F),
              value: silosCount.toString(),
              label: 'SILOS',
            ),
          ),
          const _StatusDivider(),
          Expanded(
            child: StatusItem(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFFF5C5C),
              value: alertsCount.toString(),
              label: 'ALERTS',
            ),
          ),
          const _StatusDivider(),
          Expanded(
            child: StatusItem(
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFF4D9FFF),
              value: batchesCount.toString(),
              label: 'BATCHES',
            ),
          ),
          const _StatusDivider(),
          Expanded(
            child: StatusItem(
              icon: Icons.sensors_rounded,
              iconColor: const Color(0xFFA970FF),
              value: sensorsCount.toString(),
              label: 'SENSORS',
            ),
          ),
        ],
      ),
    );
  }
}

class StatusItem extends StatelessWidget {
  const StatusItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 23),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusDivider extends StatelessWidget {
  const _StatusDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}

// ============================================================
// SECTION HEADERS
// ============================================================

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AuthTheme.textPrimary,
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AuthTheme.primaryGreen,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

// ============================================================
// EMPTY SILO CARD
// ============================================================

class EmptySiloCard extends StatelessWidget {
  const EmptySiloCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AuthTheme.surface,
        elevation: 3,
        shadowColor: AuthTheme.primaryGreen.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: AuthTheme.primaryGreen.withValues(alpha: 0.20),
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AuthTheme.primaryGreen.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storage_rounded, size: 38, color: AuthTheme.primaryGreen),
                ),
                const SizedBox(height: 18),
                const Text(
                  'No silos available',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AuthTheme.greenOverlay,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: const Text(
                    'Connect your hardware or manually add a silo to begin monitoring.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AuthTheme.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACTIVE ALERT
// ============================================================

class ActiveAlertCard extends StatelessWidget {
  const ActiveAlertCard({
    super.key, 
    required this.title,
    required this.description,
    required this.onAcknowledge,
  });

  final String title;
  final String description;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AuthTheme.surface,
      elevation: 3,
      shadowColor: AuthTheme.primaryGreen.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: AuthTheme.primaryGreen.withValues(alpha: 0.20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -42,
            right: -42,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AuthTheme.primaryGreen.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AuthTheme.primaryGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_rounded, color: AuthTheme.primaryGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AuthTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: const TextStyle(
                              color: AuthTheme.textPrimary,
                              fontSize: 18,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onAcknowledge,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: AuthTheme.primaryGreen,
                      side: BorderSide(
                        color: AuthTheme.primaryGreen.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    child: const Text('ACKNOWLEDGE'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BATCH CARD
// ============================================================

class BatchCard extends StatelessWidget {
  const BatchCard({
    super.key,
    required this.grainName,
    required this.quantity,
    required this.siloName,
    required this.riskLevel,
    required this.onPressed,
  });

  final String grainName;
  final String quantity;
  final String siloName;
  final String riskLevel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AuthTheme.surface,
      elevation: 3,
      shadowColor: AuthTheme.primaryGreen.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: AuthTheme.primaryGreen.withValues(alpha: 0.14),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AuthTheme.primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AuthTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 1,
                height: 36,
                color: AuthTheme.greenOverlay.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grainName,
                      style: const TextStyle(
                        color: AuthTheme.greenOverlay,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$quantity • $siloName',
                      style: const TextStyle(
                        color: AuthTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AuthTheme.primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  riskLevel,
                  style: const TextStyle(
                    color: AuthTheme.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
