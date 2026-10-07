import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DayPages extends StatelessWidget {
  const DayPages({
    super.key,
    required this.controller,
    required this.pageCount,
    required this.pageBuilder,
  });

  final PageController controller;
  final int pageCount;
  final NullableIndexedWidgetBuilder pageBuilder;

  @override
  Widget build(BuildContext context) {
    final axisDirection = textDirectionToAxisDirection(
      Directionality.of(context),
    );
    return Scrollable(
      axisDirection: axisDirection,
      controller: controller,
      physics: const PageScrollPhysics(),
      excludeFromSemantics: true,
      scrollBehavior: ScrollConfiguration.of(context)
          .copyWith(scrollbars: false),
      viewportBuilder: (context, position) => Viewport(
        axisDirection: axisDirection,
        offset: position,
        scrollCacheExtent: const ScrollCacheExtent.viewport(0),
        slivers: [
          SliverFillViewport(
            delegate: SliverChildBuilderDelegate(
              pageBuilder,
              childCount: pageCount,
            ),
          ),
        ],
      ),
    );
  }
}
