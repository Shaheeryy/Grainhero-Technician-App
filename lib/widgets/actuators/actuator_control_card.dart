// import 'package:flutter/material.dart';
// import '../../config/app_theme.dart';

// /// A modern card widget for controlling actuators (fans, lids, ventilation)
// /// Features toggle switch, status indicator, and action controls
// class ActuatorControlCard extends StatelessWidget {
//   final String id;
//   final String name;
//   final String type; // 'fan', 'lid', 'ventilation'
//   final String? siloName;
//   final bool isOn;
//   final String status; // 'active', 'offline', 'error'
//   final String? lastAction;
//   final bool isLoading;
//   final ValueChanged<bool>? onToggle;
//   final VoidCallback? onTap;

//   const ActuatorControlCard({
//     super.key,
//     required this.id,
//     required this.name,
//     required this.type,
//     this.siloName,
//     required this.isOn,
//     required this.status,
//     this.lastAction,
//     this.isLoading = false,
//     this.onToggle,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final statusColor = AppTheme.getStatusColor(status);
//     final accentColor = isOn ? AppTheme.successColor : AppTheme.textSecondary;

//     return Container(
//       margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
//       decoration: BoxDecoration(
//         color: AppTheme.cardColor,
//         borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
//         boxShadow: AppTheme.cardShadow,
//         border: Border(
//           left: BorderSide(color: accentColor, width: 4),
//         ),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
//           child: Padding(
//             padding: const EdgeInsets.all(AppTheme.spacingL),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header row
//                 Row(
//                   children: [
//                     // Actuator icon
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: accentColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
//                       ),
//                       child: Icon(
//                         _getActuatorIcon(),
//                         size: 24,
//                         color: accentColor,
//                       ),
//                     ),
                    
//                     const SizedBox(width: AppTheme.spacingM),
                    
//                     // Name and silo
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             name,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: AppTheme.textPrimary,
//                             ),
//                           ),
//                           if (siloName != null) ...[
//                             const SizedBox(height: 2),
//                             Text(
//                               siloName!,
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: AppTheme.textSecondary,
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
                    
//                     // Toggle switch
//                     if (isLoading)
//                       const SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     else
//                       Switch(
//                         value: isOn,
//                         onChanged: status != 'offline' && status != 'error' ? onToggle : null,
//                         activeColor: AppTheme.successColor,
//                         activeTrackColor: AppTheme.successColor.withOpacity(0.4),
//                         inactiveThumbColor: AppTheme.textSecondary,
//                         inactiveTrackColor: AppTheme.textSecondary.withOpacity(0.3),
//                       ),
//                   ],
//                 ),

//                 const SizedBox(height: AppTheme.spacingM),
//                 const Divider(height: 1),
//                 const SizedBox(height: AppTheme.spacingM),

//                 // Status row
//                 Row(
//                   children: [
//                     // Status indicator
//                     _StatusIndicator(status: status, statusColor: statusColor),
                    
//                     const Spacer(),
                    
//                     // Last action
//                     if (lastAction != null)
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.access_time,
//                             size: 14,
//                             color: AppTheme.textHint,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             lastAction!,
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: AppTheme.textHint,
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   IconData _getActuatorIcon() {
//     switch (type.toLowerCase()) {
//       case 'fan':
//         return Icons.air;
//       case 'lid':
//         return Icons.door_sliding_outlined;
//       case 'ventilation':
//         return Icons.hvac;
//       case 'heater':
//         return Icons.local_fire_department_outlined;
//       case 'cooler':
//         return Icons.ac_unit;
//       default:
//         return Icons.settings_input_component;
//     }
//   }
// }

// class _StatusIndicator extends StatelessWidget {
//   final String status;
//   final Color statusColor;

//   const _StatusIndicator({
//     required this.status,
//     required this.statusColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 8,
//           height: 8,
//           decoration: BoxDecoration(
//             color: statusColor,
//             shape: BoxShape.circle,
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(
//           _getStatusLabel(),
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//             color: statusColor,
//           ),
//         ),
//       ],
//     );
//   }

//   String _getStatusLabel() {
//     switch (status.toLowerCase()) {
//       case 'active':
//         return 'Active';
//       case 'offline':
//         return 'Offline';
//       case 'error':
//         return 'Error';
//       case 'running':
//         return 'Running';
//       default:
//         return status.toUpperCase();
//     }
//   }
// }

// /// Compact version for grid display
// class ActuatorControlCardCompact extends StatelessWidget {
//   final String name;
//   final String type;
//   final bool isOn;
//   final String status;
//   final bool isLoading;
//   final ValueChanged<bool>? onToggle;
//   final VoidCallback? onTap;

//   const ActuatorControlCardCompact({
//     super.key,
//     required this.name,
//     required this.type,
//     required this.isOn,
//     required this.status,
//     this.isLoading = false,
//     this.onToggle,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final accentColor = isOn ? AppTheme.successColor : AppTheme.textSecondary;

//     return Container(
//       decoration: AppTheme.cardDecoration,
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
//           child: Padding(
//             padding: const EdgeInsets.all(AppTheme.spacingL),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Icon
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: accentColor.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     _getActuatorIcon(),
//                     size: 28,
//                     color: accentColor,
//                   ),
//                 ),
                
//                 const SizedBox(height: AppTheme.spacingM),
                
//                 // Name
//                 Text(
//                   name,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: AppTheme.textPrimary,
//                   ),
//                   textAlign: TextAlign.center,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
                
//                 const SizedBox(height: AppTheme.spacingS),
                
//                 // Toggle
//                 if (isLoading)
//                   const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 else
//                   Switch(
//                     value: isOn,
//                     onChanged: status != 'offline' && status != 'error' ? onToggle : null,
//                     activeColor: AppTheme.successColor,
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   IconData _getActuatorIcon() {
//     switch (type.toLowerCase()) {
//       case 'fan':
//         return Icons.air;
//       case 'lid':
//         return Icons.door_sliding_outlined;
//       case 'ventilation':
//         return Icons.hvac;
//       default:
//         return Icons.settings_input_component;
//     }
//   }
// }
