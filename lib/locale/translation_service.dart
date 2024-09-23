import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/locale/lang/ar.dart';
import 'package:gpspro/locale/lang/es_ES.dart';
import 'package:gpspro/locale/lang/fa.dart';
import 'package:gpspro/locale/lang/fr.dart';
import 'package:gpspro/locale/lang/pl.dart';
import 'package:gpspro/locale/lang/pt.dart';
import 'package:gpspro/locale/lang/tr.dart';

import 'lang/en_US.dart';

class TranslationService extends Translations {
  static Locale? get locale => Get.deviceLocale;
  static const fallbackLocale = Locale('en', 'US');
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en_US,
        'es_ES': es_ES,
        'fr_FR': fr_FR,
        'ar': ar,
        'fa': fa,
        'pl': pl,
        'pt': pt,
        'tr': tr,
      };
}
