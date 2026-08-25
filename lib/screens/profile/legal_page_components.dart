import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/grainhero_colors.dart';
import '../../config/typography.dart';

// =====================================================
// Legal Block Types & Data Structures
// Defines structured blocks (paragraphs, headers, bullets, email)
// for legal documents while preserving all content.
// =====================================================

enum LegalBlockType { paragraph, subheading, bullets, email, disclosure }

class LegalBlock {
  const LegalBlock.paragraph(this.text)
    : type = LegalBlockType.paragraph,
      items = const [],
      supportingText = '',
      footerText = '',
      label = '',
      isPrimary = false;

  const LegalBlock.subheading(this.text)
    : type = LegalBlockType.subheading,
      items = const [],
      supportingText = '',
      footerText = '',
      label = '',
      isPrimary = false;

  const LegalBlock.bullets(this.items)
    : type = LegalBlockType.bullets,
      text = '',
      supportingText = '',
      footerText = '',
      label = '',
      isPrimary = false;

  const LegalBlock.email(this.text, {this.label = '', this.isPrimary = false})
    : type = LegalBlockType.email,
      items = const [],
      supportingText = '',
      footerText = '';

  const LegalBlock.disclosure(
    this.text, {
    this.supportingText = '',
    this.items = const [],
    this.footerText = '',
  }) : type = LegalBlockType.disclosure,
       label = '',
       isPrimary = false;

  final LegalBlockType type;
  final String text;
  final List<String> items;
  final String supportingText;
  final String footerText;
  final String label;
  final bool isPrimary;
}

class LegalSectionData {
  const LegalSectionData({required this.title, required this.blocks});

  final String title;
  final List<LegalBlock> blocks;
}

// =====================================================
// Legal Page Scaffold
// Shared scaffold structure with top dark app bar and
// light eggshell rounded content body.
// =====================================================
class LegalPageScaffold extends StatelessWidget {
  const LegalPageScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.titleFontSize = 21,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  final String title;
  final List<Widget> slivers;
  final double titleFontSize;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrainHeroColors.dark,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: GrainHeroColors.dark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 76,
        elevation: 0,
        scrolledUnderElevation: 3,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            key: const ValueKey('legal-page-back-button'),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Go back',
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.headingStyle(
            color: Colors.white,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: ColoredBox(
          color: GrainHeroColors.pageBackground,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: keyboardDismissBehavior,
            slivers: slivers,
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Legal Document Page
// Screen component supporting hero header card, jump-to-section
// modal sheet, and document section cards.
// =====================================================
class LegalDocumentPage extends StatefulWidget {
  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.icon,
    required this.introduction,
    required this.effectiveDate,
    required this.lastUpdated,
    required this.sections,
    this.bodyFontWeight = FontWeight.w500,
    this.showSectionNavigator = false,
  });

  final String title;
  final IconData icon;
  final String introduction;
  final String effectiveDate;
  final String lastUpdated;
  final List<LegalSectionData> sections;
  final FontWeight bodyFontWeight;
  final bool showSectionNavigator;

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}


class _LegalDocumentPageState extends State<LegalDocumentPage> {
  late List<GlobalKey> _sectionKeys;

  @override
  void initState() {
    super.initState();
    _sectionKeys = List<GlobalKey>.generate(
      widget.sections.length,
      (_) => GlobalKey(),
    );
  }

  @override
  void didUpdateWidget(covariant LegalDocumentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections.length != widget.sections.length) {
      _sectionKeys = List<GlobalKey>.generate(
        widget.sections.length,
        (_) => GlobalKey(),
      );
    }
  }

  Future<void> _showSectionNavigator() async {
    final int? sectionIndex = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Material(
          color: GrainHeroColors.pageBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GrainHeroColors.dark.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: GrainHeroColors.dark,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.segment_rounded,
                          color: GrainHeroColors.surface,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Jump to section',
                        style: AppTypography.headingStyle(
                          color: GrainHeroColors.dark,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: widget.sections.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => Material(
                      color: GrainHeroColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: GrainHeroColors.outline.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          await Future<void>.delayed(
                            const Duration(milliseconds: 120),
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop(index);
                          }
                        },
                        overlayColor: WidgetStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(WidgetState.pressed)) {
                            return GrainHeroColors.dark.withValues(
                              alpha: 0.12,
                            );
                          }
                          return null;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    SizedBox(
                                      width: 34,
                                      child: Text(
                                        '${index + 1}',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.bodyStyle(
                                          color: GrainHeroColors.primaryDark,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.sections[index].title
                                            .replaceFirst(
                                              RegExp(r'^\d+\.\s*'),
                                              '',
                                            ),
                                        style: AppTypography.bodyStyle(
                                          color: GrainHeroColors.bodyText,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: GrainHeroColors.primaryDark,
                                size: 21,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (sectionIndex == null || !mounted) return;
    final BuildContext? sectionContext =
        _sectionKeys[sectionIndex].currentContext;
    if (sectionContext == null || !sectionContext.mounted) return;
    await Scrollable.ensureVisible(
      sectionContext,
      alignment: 0.02,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openSectionNavigatorWithFeedback() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) {
      await _showSectionNavigator();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LegalPageScaffold(
      title: widget.title,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DocumentIntroduction(
                  icon: widget.icon,
                  title: widget.title,
                  introduction: widget.introduction,
                  effectiveDate: widget.effectiveDate,
                  lastUpdated: widget.lastUpdated,
                  bodyFontWeight: widget.bodyFontWeight,
                ),
                if (widget.showSectionNavigator) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _openSectionNavigatorWithFeedback,
                      icon: const Icon(Icons.segment_rounded, size: 20),
                      label: const Text('Jump to section'),
                      style: FilledButton.styleFrom(
                        foregroundColor: GrainHeroColors.surface,
                        backgroundColor: GrainHeroColors.dark,
                        side: BorderSide(
                          color: GrainHeroColors.surface.withValues(
                            alpha: 0.30,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: AppTypography.bodyStyle(
                          color: GrainHeroColors.surface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(WidgetState.pressed)) {
                            return GrainHeroColors.surface.withValues(
                              alpha: 0.20,
                            );
                          }
                          return null;
                        }),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                for (
                  int index = 0;
                  index < widget.sections.length;
                  index++
                ) ...[
                  KeyedSubtree(
                    key: _sectionKeys[index],
                    child: _LegalSectionCard(
                      section: widget.sections[index],
                      bodyFontWeight: widget.bodyFontWeight,
                    ),
                  ),
                  if (index != widget.sections.length - 1)
                    const SizedBox(height: 14),
                ],
                const SizedBox(height: 30),
                Text(
                  '© GrainHero Systems Inc.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyStyle(
                    color: GrainHeroColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// Document Hero Introduction Card
// Header card with document icon, title, intro text, and date badge
// =====================================================
class _DocumentIntroduction extends StatelessWidget {
  const _DocumentIntroduction({
    required this.icon,
    required this.title,
    required this.introduction,
    required this.effectiveDate,
    required this.lastUpdated,
    required this.bodyFontWeight,
  });

  final IconData icon;
  final String title;
  final String introduction;
  final String effectiveDate;
  final String lastUpdated;
  final FontWeight bodyFontWeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GrainHeroColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: GrainHeroColors.primary.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40),
        side: BorderSide(
          color: GrainHeroColors.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    icon,
                    color: GrainHeroColors.primaryDark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.headingStyle(
                      color: GrainHeroColors.dark,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              introduction,
              style: AppTypography.bodyStyle(
                color: GrainHeroColors.bodyText,
                fontSize: 14,
                height: 1.55,
                fontWeight: bodyFontWeight,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (effectiveDate.isNotEmpty && effectiveDate != lastUpdated)
                  _DateChip(label: 'Effective', value: effectiveDate),
                if (lastUpdated.isNotEmpty)
                  _DateChip(label: 'Updated', value: lastUpdated),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: GrainHeroColors.tonedEggshell,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GrainHeroColors.outline.withValues(alpha: 0.62),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: AppTypography.bodyStyle(
                    color: GrainHeroColors.dark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: AppTypography.bodyStyle(
                    color: GrainHeroColors.primaryDark,
                    fontSize: 11,
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
}

// =====================================================
// Section Card
// Container for section heading and its constituent blocks
// =====================================================
class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({
    required this.section,
    required this.bodyFontWeight,
  });

  final LegalSectionData section;
  final FontWeight bodyFontWeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GrainHeroColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: GrainHeroColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(
          color: GrainHeroColors.outline.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: AppTypography.headingStyle(
                color: GrainHeroColors.dark,
                fontSize: 19,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            for (int index = 0; index < section.blocks.length; index++) ...[
              _LegalBlockView(
                block: section.blocks[index],
                bodyFontWeight: bodyFontWeight,
              ),
              if (index != section.blocks.length - 1)
                const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================
// Legal Block View
// Renders individual block types (paragraphs, headings, bullet lists, email)
// =====================================================
class _LegalBlockView extends StatelessWidget {
  const _LegalBlockView({required this.block, required this.bodyFontWeight});

  final LegalBlock block;
  final FontWeight bodyFontWeight;

  @override
  Widget build(BuildContext context) {
    return switch (block.type) {
      LegalBlockType.paragraph => SelectableText(
        block.text,
        style: AppTypography.bodyStyle(
          color: GrainHeroColors.bodyText,
          fontSize: 13.5,
          height: 1.58,
          fontWeight: bodyFontWeight,
        ),
      ),
      LegalBlockType.subheading => Text(
        block.text,
        style: AppTypography.headingStyle(
          color: GrainHeroColors.primaryDark,
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
      LegalBlockType.bullets => Column(
        children: [
          for (final String item in block.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      color: GrainHeroColors.primary,
                      size: 6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      item,
                      style: AppTypography.bodyStyle(
                        color: GrainHeroColors.bodyText,
                        fontSize: 13.5,
                        height: 1.52,
                        fontWeight: bodyFontWeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      LegalBlockType.email => _EmailLink(address: block.text),
      LegalBlockType.disclosure => _LegalDisclosure(
        block: block,
        bodyFontWeight: bodyFontWeight,
      ),
    };
  }
}



class _LegalDisclosure extends StatelessWidget {
  const _LegalDisclosure({required this.block, required this.bodyFontWeight});

  final LegalBlock block;
  final FontWeight bodyFontWeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GrainHeroColors.tonedEggshell,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: GrainHeroColors.outline.withValues(alpha: 0.42),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: GrainHeroColors.primaryDark,
        collapsedIconColor: GrainHeroColors.primaryDark,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          block.text,
          style: AppTypography.headingStyle(
            color: GrainHeroColors.dark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          if (block.supportingText.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                block.supportingText,
                style: AppTypography.bodyStyle(
                  color: GrainHeroColors.bodyText,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: bodyFontWeight,
                ),
              ),
            ),
            if (block.items.isNotEmpty) const SizedBox(height: 10),
          ],
          if (block.items.isNotEmpty)
            for (final String item in block.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        color: GrainHeroColors.primary,
                        size: 6,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodyStyle(
                          color: GrainHeroColors.bodyText,
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: bodyFontWeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          if (block.footerText.isNotEmpty) ...[
            if (block.items.isNotEmpty) const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                block.footerText,
                style: AppTypography.bodyStyle(
                  color: GrainHeroColors.bodyText,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: bodyFontWeight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _EmailLink extends StatelessWidget {
  const _EmailLink({required this.address});

  final String address;

  Future<void> _openEmail() async {
    await launchUrl(Uri(scheme: 'mailto', path: address));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openEmail,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.email_outlined,
              color: GrainHeroColors.primaryDark,
              size: 19,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                address,
                style: AppTypography.bodyStyle(
                  color: GrainHeroColors.primaryDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
