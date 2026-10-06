import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'bills_tool.dart';
import 'building_tool.dart';
import 'farming_tool.dart';
import 'shopping_tool.dart';

List<ToolDef> get homeTools => [
      ToolDef(
        id: 'shopping',
        name: tr('قائمة المشتريات', 'Shopping List'),
        sub: t('السوق والبقالة والخضار', 'السوق والبقالة والخضار', 'Market, grocery & veg'),
        cat: ToolCat.home,
        icon: Icons.shopping_cart_rounded,
        color: SD.green,
        sudan: true,
        keywords: 'مشتريات قائمة سوق بقالة خضار دكان سكر زيت دقيق عدس فول بصل شاي بن لبن صابون واتساب shopping list grocery market vegetables checklist share whatsapp',
        builder: (_) => const ShoppingTool(),
      ),
      ToolDef(
        id: 'bills',
        name: tr('الفواتير الشهرية', 'Monthly Bills'),
        sub: t('ما تنسى الكهرباء والإيجار', 'لا تنسَ الكهرباء والإيجار', 'Never miss power or rent'),
        cat: ToolCat.home,
        icon: Icons.receipt_long_rounded,
        color: SD.indigo,
        keywords: 'فواتير فاتورة كهرباء موية مياه نت انترنت إيجار ايجار رسوم مدارس تلفون اشتراك تذكير سداد bills bill electricity water internet rent school fees phone subscription reminder due',
        builder: (_) => const BillsTool(),
      ),
      ToolDef(
        id: 'building',
        name: t('حاسبة مواد البناء', 'حاسبة مواد البناء', 'Building Materials'),
        sub: t('طوب وأسمنت ورملة وسيخ', 'طوب وإسمنت ورمل وحديد', 'Bricks, cement, sand & steel'),
        cat: ToolCat.home,
        icon: Icons.foundation_rounded,
        color: SD.henna,
        sudan: true,
        keywords: 'بناء مواد طوب أحمر بلك بلوك أسمنت اسمنت رملة رمل حصى خرصانة خرسانة سيخ حديد سقف بلاطة لياسة مونة غرفة سور حيطة جدار building construction bricks blocks cement sand gravel concrete steel slab plaster mortar wall fence room estimate',
        builder: (_) => const BuildingTool(),
      ),
      ToolDef(
        id: 'farming',
        name: t('حاسبة الزراعة', 'حاسبة الزراعة', 'Farm Calculator'),
        sub: t('التكلفة والربح وزكاة الزرع', 'التكلفة والربح وزكاة الزروع', 'Cost, profit & crop zakat'),
        cat: ToolCat.home,
        icon: Icons.agriculture_rounded,
        color: SD.green,
        sudan: true,
        keywords: 'زراعة مزرعة فدان هكتار ذرة عيش دخن سمسم فول سوداني قطن قمح بصل طماطم عباد الشمس تقاوي بذور سماد يوريا داب حصاد ربح زكاة زروع farming farm crop feddan hectare sorghum millet sesame groundnut cotton wheat onion tomato sunflower seed fertilizer urea dap yield profit zakat',
        builder: (_) => const FarmingTool(),
      ),
    ];
