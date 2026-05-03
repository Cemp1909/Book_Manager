import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/actividad_app.dart';
import 'package:book_manager/compartido/servicios/servicio_historial.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final _historyService = ActivityLogService.instance;
  ActivityType? _filter;
  bool _isLoading = true;

  List<AppActivity> get _filteredActivities {
    final activities = _historyService.activities;
    final filter = _filter;
    if (filter == null) return activities;
    return activities.where((activity) => activity.type == filter).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _historyService.load();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _historyService,
      builder: (context, _) {
        final activities = _filteredActivities;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildHeader(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFilters(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : activities.isEmpty
                        ? const _EmptyHistoryState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: activities.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _ActivityTile(
                                activity: activities[index],
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.command,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.lifted(AppColors.navy),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.history, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historial de actividad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Registro de cambios importantes de la operacion.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterPill(
            label: 'Todo',
            icon: Icons.all_inclusive,
            selected: _filter == null,
            onTap: () => setState(() => _filter = null),
          ),
          const SizedBox(width: 8),
          for (final type in ActivityType.values) ...[
            _FilterPill(
              label: type.label,
              icon: _iconForType(type),
              selected: _filter == type,
              onTap: () => setState(() => _filter = type),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AppActivity activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(activity.type);

    return Card(
      elevation: 0,
      color: AppColors.surface.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_iconForType(activity.type), color: color),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity.detail),
              const SizedBox(height: 6),
              Text(
                '${activity.actorName} - ${activity.actorRole} - ${_formatDate(activity.createdAt)}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(icon, size: 17, color: AppColors.ink),
      label: Text(label),
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.white,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppColors.teal : AppColors.border),
      checkmarkColor: AppColors.ink,
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Aun no hay actividad registrada.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

IconData _iconForType(ActivityType type) {
  return switch (type) {
    ActivityType.inventory => Icons.inventory_2_outlined,
    ActivityType.orders => Icons.shopping_cart_outlined,
    ActivityType.users => Icons.manage_accounts_outlined,
    ActivityType.settings => Icons.settings_outlined,
  };
}

Color _colorForType(ActivityType type) {
  return switch (type) {
    ActivityType.inventory => AppColors.teal,
    ActivityType.orders => AppColors.amber,
    ActivityType.users => AppColors.navy,
    ActivityType.settings => AppColors.leaf,
  };
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}
