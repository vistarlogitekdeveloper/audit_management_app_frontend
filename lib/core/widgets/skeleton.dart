import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// A single shimmering rectangle. Use it as a placeholder for any element
/// where the rendered shape is known but the content is still loading.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.greyTint,
      highlightColor: AppColors.cardBackground,
      period: const Duration(milliseconds: 1300),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.greyTint,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Skeleton row that mimics a list item with optional avatar + two text lines.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key, this.showAvatar = false});

  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showAvatar) ...[
          const Skeleton(width: 36, height: 36, radius: 18),
          const SizedBox(width: 12),
        ],
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(height: 12, radius: 4),
              SizedBox(height: 8),
              Skeleton(width: 180, height: 10, radius: 4),
            ],
          ),
        ),
      ],
    );
  }
}

/// Generic card-shaped placeholder for KPI tiles and dashboard widgets.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 88});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Skeleton(width: 32, height: 32, radius: 8),
              Spacer(),
              Skeleton(width: 48, height: 12, radius: 4),
            ],
          ),
          Spacer(),
          Skeleton(width: 80, height: 22, radius: 6),
          SizedBox(height: 6),
          Skeleton(width: 120, height: 10, radius: 4),
        ],
      ),
    );
  }
}

/// Stack of [SkeletonRow]s wrapped in an AppPanel-style container, useful
/// while a list is loading.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 4,
    this.showAvatar = false,
    this.spacing = 18,
  });

  final int count;
  final bool showAvatar;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : spacing),
          child: SkeletonRow(showAvatar: showAvatar),
        ),
      ),
    );
  }
}

/// Grid of [SkeletonCard]s; matches the KPI row pattern used on dashboards.
class SkeletonKpiGrid extends StatelessWidget {
  const SkeletonKpiGrid({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1100
        ? 4
        : width >= 760
            ? 3
            : width >= 480
                ? 2
                : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.6,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}
