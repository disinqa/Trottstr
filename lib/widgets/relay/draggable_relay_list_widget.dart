import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/multi_relay_connection_models.dart';
import 'package:trottstr/providers/multi_relay_providers.dart';
import 'package:trottstr/widgets/relay/multi_relay_tile_widget.dart';

/// Draggable list widget for reordering relays with priority management
class DraggableRelayListWidget extends ConsumerStatefulWidget {
  final List<ConnectedRelay> relays;
  final bool isDragEnabled;
  final Function(String, String)? onMenuAction;
  final VoidCallback? onOrderChanged;

  const DraggableRelayListWidget({
    super.key,
    required this.relays,
    this.isDragEnabled = true,
    this.onMenuAction,
    this.onOrderChanged,
  });

  @override
  ConsumerState<DraggableRelayListWidget> createState() => _DraggableRelayListWidgetState();
}

class _DraggableRelayListWidgetState extends ConsumerState<DraggableRelayListWidget>
    with TickerProviderStateMixin {
  late AnimationController _dragAnimationController;
  late AnimationController _dropAnimationController;
  
  @override
  void initState() {
    super.initState();
    _dragAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _dropAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _dragAnimationController.dispose();
    _dropAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiRelayManager = ref.watch(multiRelayManagerProvider);
    final selectionState = ref.watch(relaySelectionStateProvider);

    if (widget.relays.isEmpty) {
      return _buildEmptyState(context);
    }

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onReorder: _handleReorder,
        proxyDecorator: _buildDragProxy,
        itemCount: widget.relays.length,
        itemBuilder: (context, index) {
          final relay = widget.relays[index];
          return _buildDraggableRelayItem(
            context,
            relay,
            index,
            multiRelayManager,
            selectionState,
          );
        },
      ),
    );
  }

  Widget _buildDraggableRelayItem(
    BuildContext context,
    ConnectedRelay relay,
    int index,
    MultiRelayManager multiRelayManager,
    RelaySelectionState selectionState,
  ) {
    final isDraggedItem = selectionState.draggedRelayId == relay.relayId;
    
    return AnimatedContainer(
      key: ValueKey(relay.relayId),
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(
        bottom: isDraggedItem ? 60 : 8, // Extra space when dragging
      ),
      child: Material(
        elevation: isDraggedItem ? 8 : 0,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedScale(
          scale: isDraggedItem ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: MultiRelayTileWidget(
            connectedRelay: relay,
            isInConnection: true,
            isSelectable: false,
            isDraggable: widget.isDragEnabled,
            visualIndex: index,
            onMenuAction: (action) => widget.onMenuAction?.call(relay.relayId, action),
          ),
        ),
      ),
    );
  }

  Widget _buildDragProxy(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final scale = Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        );
        
        return Transform.scale(
          scale: scale.value,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.drag_indicator,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No relays selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select relays from the available list to create a multi-relay connection',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (!widget.isDragEnabled) return;
    
    final multiRelayManager = ref.read(multiRelayManagerProvider);
    
    // Adjust newIndex if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    // Trigger haptic feedback
    _provideDragFeedback();
    
    // Update the relay order
    multiRelayManager.reorderRelays(oldIndex, newIndex);
    
    // Notify parent of order change
    widget.onOrderChanged?.call();
    
    // Animate the drop
    _animateDrop();
  }

  void _provideDragFeedback() {
    // Provide haptic feedback during drag operations
    // You can implement platform-specific haptic feedback here
  }

  void _animateDrop() {
    _dropAnimationController.reset();
    _dropAnimationController.forward();
  }
}

/// Widget for priority indicators and drag handles
class PriorityDragHandle extends StatelessWidget {
  final int priority;
  final bool isDragging;
  final VoidCallback? onDragStart;

  const PriorityDragHandle({
    super.key,
    required this.priority,
    this.isDragging = false,
    this.onDragStart,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDragging
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getPriorityColor(context, priority),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                priority.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.drag_handle,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(
              isDragging ? 1.0 : 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(BuildContext context, int priority) {
    switch (priority) {
      case 1:
        return Colors.amber; // Primary
      case 2:
        return Colors.orange; // Secondary
      case 3:
        return Colors.deepOrange; // Tertiary
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }
}

/// Animated placeholder for drop targets during drag operations
class RelayDropTarget extends StatefulWidget {
  final bool isActive;
  final int targetIndex;
  final VoidCallback? onDrop;

  const RelayDropTarget({
    super.key,
    required this.isActive,
    required this.targetIndex,
    this.onDrop,
  });

  @override
  State<RelayDropTarget> createState() => _RelayDropTargetState();
}

class _RelayDropTargetState extends State<RelayDropTarget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RelayDropTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Drop here for priority ${widget.targetIndex + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}