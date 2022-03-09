library flutter_form_generator;

import 'package:build/build.dart';
import 'package:flutter_form_generator/src/flutter_form_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder formBuilder(BuilderOptions options) =>
    SharedPartBuilder([FlutterFormGenerator(options)], 'form');