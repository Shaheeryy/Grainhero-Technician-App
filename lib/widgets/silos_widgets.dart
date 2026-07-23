import 'package:flutter/material.dart';
import '../config/auth_theme.dart';

class SilosHeader extends StatelessWidget {
  const SilosHeader({
    super.key,
    required this.searchController,
    required this.selectedFilter,
    required this.filters,
    required this.isRefreshing,
    required this.onRefreshPressed,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterSelected,
  });

  final TextEditingController searchController;
  final String selectedFilter;
  final List<String> filters;
  final bool isRefreshing;

  final VoidCallback onRefreshPressed;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, statusBarHeight + 18, 20, 30),
      decoration: BoxDecoration(
        color: AuthTheme.greenOverlay,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(54)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Silos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                _RefreshButton(
                  isRefreshing: isRefreshing,
                  onPressed: onRefreshPressed,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SiloSearchField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    onClearPressed: onClearSearch,
                  ),
                ),
                const SizedBox(width: 12),
                SiloFilterButton(
                  selectedFilter: selectedFilter,
                  filters: filters,
                  onSelected: onFilterSelected,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.isRefreshing, required this.onPressed});

  final bool isRefreshing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isRefreshing ? null : onPressed,
      tooltip: 'Refresh silos',
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white70,
        backgroundColor: Colors.white.withValues(alpha: 0.10),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
        shape: const CircleBorder(),
      ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: isRefreshing
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.refresh_rounded,
                key: ValueKey('refresh'),
                size: 25,
              ),
      ),
    );
  }
}

class SiloSearchField extends StatefulWidget {
  const SiloSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClearPressed,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearPressed;

  @override
  State<SiloSearchField> createState() => _SiloSearchFieldState();
}

class _SiloSearchFieldState extends State<SiloSearchField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusNode.hasFocus;
    final bool hasText = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: 52,
      decoration: BoxDecoration(
        color: isFocused
            ? Colors.white.withValues(alpha: 0.17)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFocused
              ? AuthTheme.primaryGreen.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.08),
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onTapOutside: (_) => _focusNode.unfocus(),
        onChanged: (value) {
          widget.onChanged(value);
          setState(() {});
        },
        cursorColor: AuthTheme.primaryGreen,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search Silos',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.52),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isFocused ? AuthTheme.primaryGreen : Colors.white70,
          ),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: () {
                    widget.onClearPressed();
                    setState(() {});
                  },
                  tooltip: 'Clear search',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

class SiloFilterButton extends StatelessWidget {
  const SiloFilterButton({
    super.key,
    required this.selectedFilter,
    required this.filters,
    required this.onSelected,
  });

  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Filter silos',
      initialValue: selectedFilter,
      onSelected: onSelected,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      itemBuilder: (context) {
        return filters.map((filter) {
          final bool isSelected = filter == selectedFilter;

          return PopupMenuItem<String>(
            value: filter,
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 20,
                  color: isSelected
                      ? AuthTheme.primaryGreen
                      : AuthTheme.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  filter,
                  style: TextStyle(
                    color: AuthTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedFilter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.filter_list_rounded,
              color: AuthTheme.primaryGreen,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class EmptySilosState extends StatelessWidget {
  const EmptySilosState({
    super.key,
    required this.hasSearchOrFilter,
    required this.onClearPressed,
  });

  final bool hasSearchOrFilter;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        child: Column(
          key: ValueKey(hasSearchOrFilter),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.48),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
                boxShadow: [
                  BoxShadow(
                    color: AuthTheme.primaryGreen.withValues(alpha: 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: 62,
                    color: AuthTheme.textPrimary.withValues(alpha: 0.40),
                  ),
                  Transform.rotate(
                    angle: -0.78,
                    child: Container(
                      width: 82,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AuthTheme.textPrimary.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearchOrFilter ? 'No matching silos found' : 'No silos found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AuthTheme.textPrimary,
                fontSize: 21,
                height: 1.3,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: Text(
                hasSearchOrFilter
                    ? 'Adjust your search or clear filters to see your storage units.'
                    : 'Your connected grain storage units will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AuthTheme.textPrimary.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
            if (hasSearchOrFilter) ...[
              const SizedBox(height: 22),
              FilledButton.tonalIcon(
                onPressed: onClearPressed,
                style: FilledButton.styleFrom(
                  foregroundColor: AuthTheme.primaryDark,
                  backgroundColor: AuthTheme.primaryGreen.withValues(
                    alpha: 0.14,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text(
                  'Clear filters',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
