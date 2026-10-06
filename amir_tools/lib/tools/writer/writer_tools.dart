import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'writer_tool.dart';

List<ToolDef> get writerTools => [
      ToolDef(
          id: 'writer',
          name: t('مساعد الكاتب', 'مساعد الكاتب', "Writer's Studio"),
          sub: t('روايتك: شخصيات وفصول ومشاهد وحبكة', 'روايتك: شخصيات وفصول ومشاهد وحبكة', 'Characters, chapters, scenes & plot'),
          cat: ToolCat.media,
          icon: Icons.auto_stories_rounded,
          color: SD.purple,
          keywords: 'كاتب كتابة رواية قصة قصيرة مسرحية سيناريو شعر حجوة أحاجي شخصيات فصول مشاهد حبكة مسودة مخطوطة إلهام عالم '
              'writer writing novel story short story play screenplay script poetry characters chapters scenes plot outline manuscript draft prompts worldbuilding hero journey save the cat',
          builder: (_) => const WriterTool()),
    ];
