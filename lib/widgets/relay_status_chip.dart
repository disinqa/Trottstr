import 'package:flutter/material.dart';
import 'package:trottstr/models/relay_models.dart';

/// Widget to display relay connection status as a chip
class RelayStatusChip extends StatelessWidget {
  final RelayStatus status;
  final bool isCompact;

  const RelayStatusChip({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusInfo.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 6 : 8,
            height: isCompact ? 6 : 8,
            decoration: BoxDecoration(
              color: statusInfo.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            statusInfo.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: statusInfo.color,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(RelayStatus status) {
    switch (status) {
      case RelayStatus.connected:
        return _StatusInfo(
          label: 'Connected',
          color: Colors.green,
        );
      case RelayStatus.connecting:
        return _StatusInfo(
          label: 'Connecting',
          color: Colors.orange,
        );
      case RelayStatus.disconnected:
        return _StatusInfo(
          label: 'Disconnected',
          color: Colors.grey,
        );
      case RelayStatus.error:
        return _StatusInfo(
          label: 'Error',
          color: Colors.red,
        );
      case RelayStatus.testing:
        return _StatusInfo(
          label: 'Testing',
          color: Colors.blue,
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;

  _StatusInfo({required this.label, required this.color});
}