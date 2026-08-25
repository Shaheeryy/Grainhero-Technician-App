import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'legal_page_components.dart';
import '../../config/grainhero_colors.dart';
import '../../config/typography.dart';
// =====================================================
// Open Source Licenses Screen
// Redesigned UI matching reference screenshots while dynamically
// retrieving Flutter and third-party license data.
// =====================================================

class OpenSourceLicensesScreen extends StatefulWidget {
  const OpenSourceLicensesScreen({super.key});

  @override
  State<OpenSourceLicensesScreen> createState() =>
      _OpenSourceLicensesScreenState();
}

class _OpenSourceLicensesScreenState extends State<OpenSourceLicensesScreen>
    with WidgetsBindingObserver {
  static _LicenseData? _cachedLicenseData;

  late Future<_LicenseData> _licenseData;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _searchResultsAnchorKey = GlobalKey();

  String _query = '';
  String? _selectedCategory;
  bool _expandAll = false;
  bool _showAdditionalNotices = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _licenseData = _loadLicenseData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<_LicenseData> _loadLicenseData() async {
    final _LicenseData? cachedData = _cachedLicenseData;
    if (cachedData != null) return cachedData;

    final Map<String, String> versions = await _loadPackageVersions();
    final Map<String, List<String>> packageTexts = {};
    final Stopwatch frameBudget = Stopwatch()..start();

    try {
      await for (final LicenseEntry entry in LicenseRegistry.licenses) {
        final String text = entry.paragraphs
            .map((LicenseParagraph paragraph) => paragraph.text)
            .join('\n\n')
            .trim();

        if (text.isEmpty) continue;

        for (final String package in entry.packages) {
          final List<String> texts = packageTexts.putIfAbsent(
            package,
            () => <String>[],
          );
          if (!texts.contains(text)) texts.add(text);
        }

        if (frameBudget.elapsedMicroseconds >= 6000) {
          await WidgetsBinding.instance.endOfFrame;
          frameBudget.reset();
        }
      }
    } catch (e) {
      debugPrint('Error reading license registry: $e');
    }

    // Safely attempt to load font OFL licenses if available
    try {
      final String lexendOfl =
          await rootBundle.loadString('assets/fonts/Lexend-OFL.txt');
      packageTexts['Lexend'] = <String>[lexendOfl];
      versions['Lexend'] = 'Google Fonts';
    } catch (_) {}

    try {
      final String pjsOfl =
          await rootBundle.loadString('assets/fonts/PlusJakartaSans-OFL.txt');
      packageTexts['Plus Jakarta Sans'] = <String>[pjsOfl];
      versions['Plus Jakarta Sans'] = 'Google Fonts';
    } catch (_) {}

    final List<_PackageLicense> packages = packageTexts.entries.map((entry) {
      final String completeText = entry.value.join(
        '\n\n────────────────────────\n\n',
      );
      return _PackageLicense(
        name: entry.key,
        version: versions[entry.key] ?? 'SDK component',
        copyright: _findCopyright(completeText),
        licenseType: _detectLicenseType(completeText),
        completeText: completeText,
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final data = _LicenseData(packages: packages);
    _cachedLicenseData = data;
    return data;
  }

  Future<Map<String, String>> _loadPackageVersions() async {
    try {
      final String lockfile = await rootBundle.loadString('pubspec.lock');
      final Map<String, String> versions = {};
      String? currentPackage;

      for (final String line in lockfile.split('\n')) {
        final RegExpMatch? packageMatch =
            RegExp(r'^  ([^\s:]+):\s*$').firstMatch(line);
        if (packageMatch != null) {
          currentPackage = packageMatch.group(1);
          continue;
        }

        final RegExpMatch? versionMatch =
            RegExp(r'^    version: "([^"]+)"\s*$').firstMatch(line);
        if (currentPackage != null && versionMatch != null) {
          versions[currentPackage] = versionMatch.group(1)!;
        }
      }

      return versions;
    } catch (_) {
      return const {};
    }
  }

  String _findCopyright(String text) {
    final RegExpMatch? match = RegExp(
      r'copyright[^\n\r]*',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(0)?.trim() ?? 'See full license text';
  }

  String _detectLicenseType(String text) {
    final String lower = text.toLowerCase();
    if (lower.contains('apache license') && lower.contains('version 2.0')) {
      return 'Apache 2.0';
    }
    if (lower.contains('mozilla public license')) {
      return 'MPL';
    }
    if (lower.contains('sil open font license')) {
      return 'OFL';
    }
    if (lower.contains('gnu lesser general public license')) {
      return 'LGPL';
    }
    if (lower.contains('gnu general public license')) {
      return 'GPL';
    }
    if (lower.contains('permission to use, copy, modify, and/or distribute') &&
        lower.contains('with or without fee')) {
      return 'ISC';
    }
    if (lower.contains('permission is hereby granted, free of charge')) {
      return 'MIT';
    }
    if (lower.contains('redistribution and use in source and binary forms')) {
      if (lower.contains('neither the name of') ||
          lower.contains('names of its contributors may be used to endorse')) {
        return 'BSD 3-Clause';
      }
      return 'BSD 2-Clause';
    }
    return 'Other';
  }

  void _retry() {
    setState(() {
      _cachedLicenseData = null;
      _licenseData = _loadLicenseData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LicenseData>(
      future: _licenseData,
      builder: (context, snapshot) {
        final List<_PackageLicense> allPackages =
            snapshot.data?.packages ?? const <_PackageLicense>[];

        final String normalizedQuery = _query.trim().toLowerCase();
        final List<_PackageLicense> visiblePackages = allPackages.where((item) {
          final bool matchesCategory = _selectedCategory == null ||
              item.licenseType == _selectedCategory;
          final bool matchesQuery = normalizedQuery.isEmpty ||
              item.name.toLowerCase().contains(normalizedQuery) ||
              item.licenseType.toLowerCase().contains(normalizedQuery);
          return matchesCategory && matchesQuery;
        }).toList();

        // Calculate counts by license type
        final Map<String, int> counts = {};
        for (final pkg in allPackages) {
          counts[pkg.licenseType] = (counts[pkg.licenseType] ?? 0) + 1;
        }

        return LegalPageScaffold(
          title: 'Open-Source Licenses',
          titleFontSize: 20,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // =====================================================
            // Hero Card Component
            // =====================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _HeroNoticeCard(
                  showAdditionalNotices: _showAdditionalNotices,
                  onToggleAdditionalNotices: () {
                    setState(() {
                      _showAdditionalNotices = !_showAdditionalNotices;
                    });
                  },
                ),
              ),
            ),

            if (snapshot.connectionState != ConnectionState.done)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: GrainHeroColors.primaryDark,
                    ),
                  ),
                ),
              )
            else if (snapshot.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load licenses',
                        style: AppTypography.headingStyle(
                          color: GrainHeroColors.dark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // =====================================================
              // Controls & Filters Area
              // =====================================================
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    key: _searchResultsAnchorKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Third-Party Components',
                        style: AppTypography.headingStyle(
                          color: GrainHeroColors.dark,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${visiblePackages.length} of ${allPackages.length} licensed components shown.',
                        style: AppTypography.bodyStyle(
                          color: GrainHeroColors.mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Input
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (val) => setState(() => _query = val),
                        style: AppTypography.bodyStyle(
                          color: GrainHeroColors.dark,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search packages or license types',
                          hintStyle: AppTypography.bodyStyle(
                            color: GrainHeroColors.mutedText,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: GrainHeroColors.primaryDark,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: GrainHeroColors.mutedText,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: GrainHeroColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: GrainHeroColors.outline.withValues(alpha: 0.4),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: GrainHeroColors.outline.withValues(alpha: 0.4),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: GrainHeroColors.primaryDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Filter Chips and Expand All Action
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FilterChipItem(
                                    label: 'All · ${allPackages.length}',
                                    isSelected: _selectedCategory == null,
                                    onTap: () =>
                                        setState(() => _selectedCategory = null),
                                  ),
                                  const SizedBox(width: 8),
                                  for (final entry in counts.entries) ...[
                                    _FilterChipItem(
                                      label: '${entry.key} · ${entry.value}',
                                      isSelected:
                                          _selectedCategory == entry.key,
                                      onTap: () => setState(
                                        () => _selectedCategory =
                                            _selectedCategory == entry.key
                                                ? null
                                                : entry.key,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Expand / Collapse All Toggle
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _expandAll = !_expandAll;
                              });
                            },
                            icon: Icon(
                              _expandAll
                                  ? Icons.unfold_less_rounded
                                  : Icons.unfold_more_rounded,
                              size: 18,
                            ),
                            label: Text(_expandAll ? 'Collapse' : 'Expand all'),
                            style: FilledButton.styleFrom(
                              foregroundColor: GrainHeroColors.surface,
                              backgroundColor: GrainHeroColors.primaryDark,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              textStyle: AppTypography.bodyStyle(
                                color: GrainHeroColors.surface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // =====================================================
              // Package Cards List
              // =====================================================
              if (visiblePackages.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: GrainHeroColors.mutedText,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No matching licenses found',
                            style: AppTypography.bodyStyle(
                              color: GrainHeroColors.mutedText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = visiblePackages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PackageLicenseCard(
                            key: ValueKey('${item.name}_${item.licenseType}_${index}_$_expandAll'),
                            package: item,
                            initiallyExpanded: _expandAll,
                          ),
                        );
                      },
                      childCount: visiblePackages.length,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

// =====================================================
// Hero Notice Card
// Card with green icon, notices overview, and collapsible detail accordion
// =====================================================
class _HeroNoticeCard extends StatelessWidget {
  const _HeroNoticeCard({
    required this.showAdditionalNotices,
    required this.onToggleAdditionalNotices,
  });

  final bool showAdditionalNotices;
  final VoidCallback onToggleAdditionalNotices;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GrainHeroColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: GrainHeroColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(
          color: GrainHeroColors.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: GrainHeroColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Open-Source Software Notices',
                    style: AppTypography.headingStyle(
                      color: GrainHeroColors.dark,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'GrainHero Technician is built using open-source software created and '
              'maintained by independent developers and communities. We appreciate '
              'their contributions and acknowledge the copyright holders of the software '
              'components included in this application.',
              style: AppTypography.bodyStyle(
                color: GrainHeroColors.bodyText,
                fontSize: 13.5,
                height: 1.55,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Each component remains governed by its respective license. Nothing in '
              'these notices changes or replaces the rights and obligations provided '
              'under those licenses.',
              style: AppTypography.bodyStyle(
                color: GrainHeroColors.bodyText,
                fontSize: 13.5,
                height: 1.55,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),

            // Additional Notices Accordion Header Button
            InkWell(
              onTap: onToggleAdditionalNotices,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: GrainHeroColors.tonedEggshell,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: GrainHeroColors.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: GrainHeroColors.primaryDark,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Additional notices',
                        style: AppTypography.bodyStyle(
                          color: GrainHeroColors.dark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      showAdditionalNotices
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: GrainHeroColors.dark,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Additional Notices Content
            if (showAdditionalNotices) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GrainHeroColors.tonedEggshell,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disclaimer',
                      style: AppTypography.headingStyle(
                        color: GrainHeroColors.primaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Open-source components are provided by their respective authors under '
                      'the terms of their individual licenses. Unless required by the applicable '
                      'license, contributors provide their software without warranties or conditions '
                      'of any kind.',
                      style: AppTypography.bodyStyle(
                        color: GrainHeroColors.bodyText,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Copyright Notice',
                      style: AppTypography.headingStyle(
                        color: GrainHeroColors.primaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Copyright © 2026 GrainHero Systems Inc. GrainHero\'s original application '
                      'code, branding and content are not made open source merely because the '
                      'application contains open-source components.',
                      style: AppTypography.bodyStyle(
                        color: GrainHeroColors.bodyText,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Contact',
                      style: AppTypography.headingStyle(
                        color: GrainHeroColors.primaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => launchUrl(
                        Uri(scheme: 'mailto', path: 'legal@grainhero.com'),
                      ),
                      child: Text(
                        'Questions concerning third-party software notices can be sent to legal@grainhero.com.',
                        style: AppTypography.bodyStyle(
                          color: GrainHeroColors.primaryDark,
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ).copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================
// Category Filter Chip Component
// =====================================================
class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? GrainHeroColors.dark
              : GrainHeroColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? GrainHeroColors.dark
                : GrainHeroColors.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyStyle(
            color: isSelected
                ? GrainHeroColors.surface
                : GrainHeroColors.dark,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Individual Package License Card Widget
// =====================================================
class _PackageLicenseCard extends StatefulWidget {
  const _PackageLicenseCard({
    super.key,
    required this.package,
    required this.initiallyExpanded,
  });

  final _PackageLicense package;
  final bool initiallyExpanded;

  @override
  State<_PackageLicenseCard> createState() => _PackageLicenseCardState();
}

class _PackageLicenseCardState extends State<_PackageLicenseCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GrainHeroColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: GrainHeroColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: GrainHeroColors.outline.withValues(alpha: 0.25),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (val) => setState(() => _isExpanded = val),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: const Border(),
        title: Text(
          widget.package.name,
          style: AppTypography.headingStyle(
            color: GrainHeroColors.dark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                'Version: ${widget.package.version}',
                style: AppTypography.bodyStyle(
                  color: GrainHeroColors.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: GrainHeroColors.tonedEggshell,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: GrainHeroColors.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  widget.package.licenseType,
                  style: AppTypography.bodyStyle(
                    color: GrainHeroColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          _isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          color: GrainHeroColors.dark,
        ),
        children: [
          const Divider(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              widget.package.completeText,
              style: AppTypography.bodyStyle(
                color: GrainHeroColors.bodyText,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// Internal Data Holders
// =====================================================
class _LicenseData {
  const _LicenseData({required this.packages});
  final List<_PackageLicense> packages;
}

class _PackageLicense {
  const _PackageLicense({
    required this.name,
    required this.version,
    required this.copyright,
    required this.licenseType,
    required this.completeText,
  });

  final String name;
  final String version;
  final String copyright;
  final String licenseType;
  final String completeText;
}
