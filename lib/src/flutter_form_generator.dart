// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_form_generator/src/annotations.dart';
import 'package:source_gen/source_gen.dart';

class FlutterFormGenerator extends GeneratorForAnnotation<FormWidget> {
  final BuilderOptions builderOptions;
  String widget = '';
  String bloc = '';
  List<String> fields = [];
  final _coreChecker = const TypeChecker.fromRuntime(Field);
  String className = '';

  FlutterFormGenerator(this.builderOptions);

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    className = element.displayName;
    writeWidget(element);
    writeBloc(element);
    handleMethodsAnnotation(element);
    updateImports(buildStep);
    return widget + bloc;
  }

  void handleMethodsAnnotation(Element element) {
    for (MethodElement field in (element as ClassElement).methods) {
      // print(field);
    }
  }

  String handleFieldsAnnotation(Element element) {
    fields = [];
    for (var field in (element as ClassElement).fields) {
      if (_coreChecker.hasAnnotationOfExact(field)) {
        handleField(element, field);
      }
    }
    // widget = widget.replaceAll(
    //     "// #fields#", fields.join(',SizedBox(height: 4.0),'));
    return fields
        .join(',SizedBox(height: widget.verticalMarginBetweenFields),');
  }

  bool _hasMethod(Element element, String methodName) {
    return (element as ClassElement)
        .methods
        .where((e) => e.displayName == methodName)
        .isNotEmpty;
  }

  void handleField(Element element, FieldElement fieldElement) {
    final fields = _coreChecker.annotationsOf(fieldElement).toList();
    for (final field in fields) {
      final type = ConstantReader(field).read('type').literalValue as String;

      final validators = ConstantReader(field.getField('validators'))
          .objectValue
          .toListValue();

      final decoration = ConstantReader(field.getField('decoration'))
          .literalValue as Map<dynamic, dynamic>;
      final inputDecorationBuffer = StringBuffer();

      for (final key in decoration.keys) {
        inputDecorationBuffer.writeln(
            "${key.toStringValue()}: \'${decoration[key].toStringValue()}\',");
      }
      final inputDecorationStr = inputDecorationBuffer.toString();
      final label = ConstantReader(field.getField('label')).literalValue;
      String _field = '''const Padding(
            padding: EdgeInsets.symmetric(horizontal:16.0, 
            vertical: 4.0),child: 
            Text("${label}", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.0))),''';

      if (type == "dropdown") {
        _field += writeDropdownField(fieldElement, field, validators,
            inputDecorations: inputDecorationStr);
      } else if (type == 'filter_chip') {
        _field += writeFilterChipField(fieldElement, field,
            inputDecorations: inputDecorationStr);
      } else if (type == 'choice_chip') {
        _field += writeChoiceChipField(fieldElement, field,
            inputDecorations: inputDecorationStr);
      } else if (type == 'date') {
        _field += writeDateTimePickerField(fieldElement, field, 'InputType.date',
          inputDecorations: inputDecorationStr, );
      } else if (type == 'date_time') {
        _field += writeDateTimePickerField(fieldElement, field, 'InputType.time',
            inputDecorations: inputDecorationStr, );
      } else if (type == 'date_range') {
        _field += writeDateRangePickerField(fieldElement, field,
            inputDecorations: inputDecorationStr);
      } else if (type == 'slider') {
        _field += writeSliderField(element, fieldElement, field,
            inputDecorations: inputDecorationStr);
      } else if (type == 'checkbox') {
        _field += writeCheckboxField(fieldElement, field, validators,
            inputDecorations: inputDecorationStr);
      } else if (type == 'image') {
        _field += writeImageField(fieldElement, field,
            inputDecorations: inputDecorationStr);
      } else if (type == 'chips_input') {
        _field += writeChipsInputField(fieldElement, field,
            inputDecorations: inputDecorationStr);
      } else {
        _field += writeTextField(fieldElement, validators,
            type: type, inputDecorations: inputDecorationStr);
      }
      this.fields.add(_field);
    }
  }

  String writeDropdownField(
      FieldElement fieldElement, DartObject field, validators,
      {inputDecorations = ''}) {
    final bloc = ConstantReader(field).read('bloc').literalValue as String;
    return '''
    ${(bloc != '') ? '''BlocBuilder<${bloc}Bloc, ${bloc}State>(builder: (context, state) {
    return''' : ''}
     
          FormBuilderDropdown(
                name: '${fieldElement.displayName}',
                decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
                // initialValue: 'Male',
                allowClear: true,
                hint: Text('${field.getField('hint')?.toStringValue()}'),
                validator: ${(validators != null) ? writeValidators(validators) : ''},
                items: ${className}.${fieldElement.displayName}Items(context${(bloc != '') ? ', state' : ''}),
                onChanged: (value) {
                    BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                  },
              )
               ${(bloc != '') ? ';})' : ''}
              
          '''
        .replaceAll(
            '${(validators != null) ? writeValidators(validators) : ''}',
            (validators != null) ? writeValidators(validators) : '');
  }

  String writeChoiceChipField(FieldElement fieldElement, DartObject field,
      {inputDecorations = ''}) {
    final bloc = ConstantReader(field).read('bloc').literalValue as String;
    return '''
       ${(bloc != '') ? '''BlocBuilder<${bloc}Bloc, ${bloc}State>(builder: (context, state) {
          return ''' : ''}
            FormBuilderChoiceChip(
                  name: '${fieldElement.displayName}',
                  decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
                  options: ${className}.${fieldElement.displayName}Options(context${(bloc != '') ? ', state' : ''}),
                  onChanged: (value) {
                      BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                    },
                )
                ${(bloc != '') ? ';})' : ''}
          ''';
  }

  String writeFilterChipField(FieldElement fieldElement, DartObject field,
      {inputDecorations = ''}) {
    final bloc = ConstantReader(field).read('bloc').literalValue as String;
    return '''
     ${(bloc != '') ? '''BlocBuilder<${bloc}Bloc, ${bloc}State>(builder: (context, state) {
    return''' : ''}
          FormBuilderFilterChip(
                name: '${fieldElement.displayName}',
                 spacing: 4.0,
                decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
                options: ${className}.${fieldElement.displayName}Options(context${(bloc != '') ? ', state' : ''}),
                onChanged: (value) {
                    BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                  },
              )
           ${(bloc != '') ? ';})' : ''}
          ''';
  }

  String writeDateTimePickerField(FieldElement fieldElement, DartObject field, String type,
      {inputDecorations = ''}) {
    return '''
          FormBuilderDateTimePicker(
                name: '${fieldElement.displayName}',
                inputType: ${type},
                decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
                initialTime: TimeOfDay(hour: 8, minute: 0),
                onChanged: (value) {
                    BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                  },
              )
          ''';
  }

  String writeDateRangePickerField(FieldElement fieldElement, DartObject field,
      {inputDecorations = ''}) {
    return '''
          FormBuilderDateRangePicker(
                name: '${fieldElement.displayName}',
                firstDate: DateTime(1970),
                lastDate: DateTime(2030),
                format: DateFormat('yyyy-MM-dd'),
                pickerBuilder: (BuildContext context, Widget? child) {
                    child ??= SizedBox.shrink();
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: Theme.of(context).colorScheme),
                      child: child,
                    );
                  },
                onChanged: (value) {
                  BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                },
                decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
              )
          ''';
  }

  String writeSliderField(
      Element element, FieldElement fieldElement, DartObject field,
      {inputDecorations = ''}) {
    final max = ConstantReader(field).read('max').literalValue as double;
    final min = ConstantReader(field).read('min').literalValue as double;
    return '''
          FormBuilderSlider(
                name: '${fieldElement.displayName}',
                onChanged: (value) {
                  BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                },
                min: ${_hasMethod(element, '${fieldElement.displayName}Min') ? "${element.displayName}.${fieldElement.displayName}Min(context)" : "${min}"},
                max: ${_hasMethod(element, '${fieldElement.displayName}Max') ? "${element.displayName}.${fieldElement.displayName}Max(context)" : "${max}"},
                initialValue: 7.0,
                divisions: 20,
                activeColor: Colors.red,
                inactiveColor: Colors.pink[100],
                decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
                
              )
          ''';
  }

  String writeImageField(FieldElement fieldElement, DartObject field,
      {inputDecorations = ''}) {
    final maxImages =
        ConstantReader(field).read('maxImages').literalValue as int;
    final aspectRatio = ConstantReader(field).read('aspectRatio').literalValue;
    String cropImage = '''
                    final file = value?.last;
                    final size = ImageSizeGetter.getSize(FileInput(File(file.path)));
                    if(num.parse((size.width/size.height).toStringAsFixed(2)) == num.parse(${aspectRatio}.toStringAsFixed(2))){
                      return;
                    }
                    File? croppedFile = await ImageCropper.cropImage(
                        sourcePath: value?.last.path,
                        aspectRatioPresets: [
                          CropAspectRatioPreset.ratio4x3,
                        ],
                        androidUiSettings: const AndroidUiSettings(
                            toolbarTitle: 'Cropper',
                            toolbarColor: Colors.black,
                            toolbarWidgetColor: Colors.white,
                            initAspectRatio: CropAspectRatioPreset.ratio4x3,
                            lockAspectRatio: false),
                        iosUiSettings: const IOSUiSettings(
                          minimumAspectRatio: 1.0,
                        )
                    );
                    value![value.length - 1] = XFile(croppedFile?.path ??'');
                    _formKey.currentState?.fields['images']?.didChange(value);
                  
    ''';
    return '''
          FormBuilderImagePicker(
            name: '${fieldElement.displayName}',
            decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
            maxImages: ${maxImages},
            onChanged: (value) async {
              ${(aspectRatio != null) ? cropImage : ''}
            },
          )
          ''';
  }

  String writeChipsInputField(FieldElement fieldElement, DartObject field, {String inputDecorations = ''}) {
    // final max = ConstantReader(field).read().literalValue as double;
    final bloc = ConstantReader(field).read('bloc').literalValue as String;
    final searchField = ConstantReader(field).read('searchField').literalValue as String;
    final template = ConstantReader(field).read('template').literalValue as String;
    return '''
    ${(bloc != '') ? '''BlocBuilder<${bloc}Bloc, ${bloc}State>(builder: (context, state) {
    return''' : ''}
          ChipsInputField<$template>(
               name: '${fieldElement.displayName}',
              decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
              chipBuilder: (context, state, $template profile) {
                return InputChip(
                  key: ObjectKey(profile),
                  label: Text((profile != null) ? profile.name: ''),
                  onDeleted: () => state.deleteChip(profile),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
              suggestionBuilder: (context, $template profile) {
                return ListTile(
                  key: ObjectKey(profile),
                  title: Text((profile != null) ? profile.name: ''),
                );
              },
              findSuggestions: (String query) {
                if (query.isNotEmpty) {
                  var lowercaseQuery = query.toLowerCase();
                  final results = $className.${fieldElement.displayName}Items(context${(bloc != '') ? ', state' : ''}).where((profile) {
                    return profile.$searchField
                        .toLowerCase()
                        .contains(query.toLowerCase());
                  }).toList(growable: false)
                    ..sort((a, b) => a.$searchField
                        .toLowerCase()
                        .indexOf(lowercaseQuery)
                        .compareTo(
                        ((b != null) ? b.name: '').toLowerCase().indexOf(lowercaseQuery)));
                  return results;
                }
                return $className.${fieldElement.displayName}Items(context${(bloc != '') ? ', state' : ''});
              }
            )
             ${(bloc != '') ? ';})' : ''}
    ''';
  }
  String writeCheckboxField(
      FieldElement fieldElement, DartObject field, validators,
      {inputDecorations = ''}) {
    return '''
          FormBuilderCheckbox(
                name: '${fieldElement.displayName}',
                initialValue: false,
                onChanged: (value) {
                  BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                },
                title: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'I have read and agree to the ',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                validator: ${(validators != null) ? writeValidators(validators) : ''},
              )
          ''';
  }

  String writeTextField(FieldElement fieldElement, validators,
      {type: 'text', inputDecorations = ''}) {
    dynamic keyboardType;
    String valueTransformer = '';
    switch (type) {
      case 'text':
        keyboardType = 'TextInputType.text';
        break;
      case 'name':
        keyboardType = 'TextInputType.name';
        break;
      case 'emailAddress':
        keyboardType = 'TextInputType.emailAddress';
        break;
      case 'multiline':
        keyboardType = 'TextInputType.multiline';
        break;
      case 'phone':
        keyboardType = 'TextInputType.phone';
        break;
      case 'url':
        keyboardType = 'TextInputType.url';
        break;
      case 'number':
        keyboardType = 'TextInputType.number';
        valueTransformer = "valueTransformer: (value) => (value != null)? num.tryParse(value): value,";
        break;
      case 'double':
        keyboardType = 'TextInputType.number';
        valueTransformer = "valueTransformer: (value) => (value != null)? double.tryParse(value): value,";
        break;
    }
    return '''
            FormBuilderTextField(
                  name: '${fieldElement.displayName}',
                  decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
                  validator: ${(validators != null) ? writeValidators(validators) : ''},
                  ${valueTransformer}
                  keyboardType: ${keyboardType},
                  onChanged: (value) {
                    BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                  },
            )
        ''';
  }

  String _writeFormDialog(Element element) {
    return '''
    static ${element.displayName[0].toLowerCase()}${element.displayName.substring(1)}FormDialog(cxt, {Function? onBusinessCreated, Widget? title, Function? onSubmit, Map<String, dynamic>? payload}) {
      showMaterialModalBottomSheet(
        context: cxt,
        shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        builder: (context) =>
         Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(),
            body: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => ${element.displayName}Cubit(),
                ), ...${_hasMethod(element, 'providers') ? "${element.displayName}.providers(context)" : "[]"}
              ],
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom * 0.001),
                child: Builder(builder: (context) {
                  return SingleChildScrollView(
                    child: Padding(
                        padding: EdgeInsets.all(16.0), 
                        child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if(title != null)
                                  title,
                                ${element.displayName}Form(
                                onSubmit:  (value) async {
                                  ${(_hasMethod(element, 'submit')) ? "final response = await _\$${element.displayName}FromJson(value).submit(context, payload: payload);" : "final response = null;"}
                                  onSubmit?.call(response);
                                }),
                              ]), 
                             ),
                   );
                }),
              ),
            ),
           ),
          ),  
        ),
      );
    }
    ''';
  }

  void writeWidget(Element element) {
    final decoratorMethod = (element as ClassElement)
        .methods
        .where((e) => e.displayName == 'decoration')
        .toList();

    widget = '''
    class ${element.displayName}Form extends StatefulWidget {
      InputDecoration? decoration;
      Function? onSubmit;
      double verticalMarginBetweenFields;
      ${element.displayName}Form({Key? key, this.decoration = null, this.onSubmit = null, this.verticalMarginBetweenFields = 8.0}) : super(key: key){
        if(decoration == null){
          decoration = ${decoratorMethod.isNotEmpty ? '${element.displayName}.decoration();' : 'InputDecoration();'}
        }
      }
      ${_writeFormDialog(element)}
      @override
      _${element.displayName}FormState createState() => _${element.displayName}FormState();
    }
    
    class _${element.displayName}FormState extends State<${element.displayName}Form> {
      final _formKey = GlobalKey<FormBuilderState>();
      @override
      Widget build(BuildContext context) {
        return SingleChildScrollView(
            child: Column(
            children: <Widget>[
              FormBuilder(
                key: _formKey,
                autovalidateMode: AutovalidateMode.always,
                child:SingleChildScrollView(
            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ${handleFieldsAnnotation(element)}
                      ],
                    ),),
              ),
              ${writeSubmitButton(element)}
            ],
          )
        );
      }
      @override
      void initState() {
      ${(_hasMethod(element, 'init')) ? "${className}.init(context);" : ""}
      }
      ${writeSubmittingFunction(element)}
    }
    ''';
  }

  String writeSubmitButton(element) {
    return '''
    Row(
          children: <Widget>[
            Expanded(
            child: Padding(
           padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: BlocBuilder<${className}Cubit, ${className}State>(
                builder: (context, state) {
                  return Button(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state is ${className}SubmittingState)
                          const SizedBox(
                            height: 18.0,
                            width: 18.0,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          ),
                        if (state is ${className}SubmittingState)
                          const SizedBox(width: 16.0,),
                        const Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    onPressed: (state is ${className}SubmittingState)? null: _submit,
                  );
                },
              ),
              ),
            ),
          ],
        )
    ''';
  }

  String writeSubmittingFunction(element) {
    return '''
           Future<String?> _submit() async {
                    _formKey.currentState?.save();
                    if (_formKey.currentState!.validate()) {
                      print(_formKey.currentState?.value);
                      final value = _formKey.currentState?.value;
                      BlocProvider.of<${className}Cubit>(context).submitting();
                      if (widget.onSubmit != null){
                        final response = await widget.onSubmit?.call(value);
                        BlocProvider.of<${className}Cubit>(context).submit(response);
                      }
                      BlocProvider.of<${className}Cubit>(context).submit(value);
                    } else {
                      print("validation failed");
                    }
                  }
    ''';
  }

  Future<void> updateImports(buildStep) async {
    var imports = [
      'import \'package:flutter/material.dart\';',
      'import \'package:flutter_form_builder/flutter_form_builder.dart\';',
      'import \'package:form_builder_validators/form_builder_validators.dart\';',
      'import \'package:intl/intl.dart\';',
      'import \'package:flutter_bloc/flutter_bloc.dart\';',
      'import \'package:equatable/equatable.dart\';',
      'import \'package:form_builder_image_picker/form_builder_image_picker.dart\';',
      'import \'package:image_size_getter/image_size_getter.dart\';',
      'import \'package:image_cropper/image_cropper.dart\';',
      'import \'package:image_size_getter/file_input.dart\';',
      'import \'package:cross_file/cross_file.dart\';',
      'import \'package:modal_bottom_sheet/modal_bottom_sheet.dart\';',
      'import \'package:form_builder_chips_input/form_builder_chips_input.dart\';',
    ];
    StringBuffer importsBuffer = new StringBuffer();
    String file = await buildStep.readAsString(buildStep.inputId);
    for (String import in imports) {
      if (!file.contains(import)) {
        importsBuffer.writeln(import);
      }
    }

    final editedText = importsBuffer.toString() + file;
    try {
      File outputFile = File(buildStep.inputId.path);
      outputFile.writeAsStringSync(editedText);
    } catch (e) {
      // print(e);
    }
  }

  String writeValidators(List<DartObject>? validators) {
    const validatorsCode = 'FormBuilderValidators.compose([#validators#])';
    StringBuffer validatorBuffer = StringBuffer();
    if (validators != null && validators.isNotEmpty) {
      for (DartObject validator in validators) {
        final validatorsStr = validator.toStringValue()?.split(":");
        if (validatorsStr != null) {
          String validatorTypes = validatorsStr[0];
          validatorsStr[0] = 'context';
          switch (validatorTypes) {
            case 'required':
              validatorBuffer.writeln(
                  "FormBuilderValidators.required(${validatorsStr.join(',')}),");
              break;
            case 'numeric':
              validatorBuffer.writeln(
                  "FormBuilderValidators.numeric(${validatorsStr.join(',')}),");
              break;
            case 'max':
              validatorBuffer.writeln(
                  "FormBuilderValidators.max(${validatorsStr.join(',')}),");
              break;
          }
        }
      }
      return validatorsCode.replaceAll(
          "#validators#", validatorBuffer.toString());
    }
    return 'null';
    // FormBuilderValidators.required(context),
    // FormBuilderValidators.numeric(context),
    // FormBuilderValidators.max(context, 70),
  }

  void writeBloc(Element element) {
    this.bloc = '''
    \n// ${className}Cubit \n\n
    class ${className}Cubit extends Cubit<${className}State> {
      ${className}Cubit() : super(${className}State());
      
      ${writeEventMethod(element)}
    }
    
    ${writeState(element)}
    ''';
  }

  String writeState(Element element) {
    StringBuffer fieldsBuffer = StringBuffer();
    StringBuffer paramsBuffer = StringBuffer();
    StringBuffer argsBuffer = StringBuffer();
    StringBuffer paramsNullableBuffer = StringBuffer();
    for (var field in (element as ClassElement).fields) {
      if (_coreChecker.hasAnnotationOfExact(field)) {
        paramsBuffer.writeln('this.${field.displayName},');
        paramsNullableBuffer.writeln(
            'final ${field.type.toString().replaceAll('?', '')}? ${field.displayName},');
        fieldsBuffer.writeln(
            'final ${field.type.toString().replaceAll('?', '')}? ${field.displayName};');
        argsBuffer.writeln(
            '${field.displayName}: ${field.displayName} ?? this.${field.displayName},');
      }
    }
    final state = '''
        class ${className}State extends Equatable{
          ${fieldsBuffer.toString()}
          
          ${className}State({${paramsBuffer.toString()}});

          ${className}State copyWith({
            ${paramsNullableBuffer.toString()}
          }) {
            return ${className}State(
              ${argsBuffer.toString()}
            );
          }
           
          @override
          List<Object?> get props => [${paramsBuffer.toString().replaceAll('this.', '')}];
        }
        
        class ${className}SubmittingState extends ${className}State{
          
          ${className}SubmittingState();
          
          @override
          List<Object> get props => [];
        }
        
        class ${className}SubmittedState extends ${className}State{
          final response;
          
          ${className}SubmittedState(this.response);
          
          @override
          List<Object?> get props => [response];
        }
        ''';

    return state.toString();
  }

  String writeEventMethod(Element element) {
    StringBuffer stringBuffer = StringBuffer();
    for (var field in (element as ClassElement).fields) {
      if (_coreChecker.hasAnnotationOfExact(field)) {
        final state = '''
        void ${field.displayName}Changed(value) => emit(state.copyWith(${field.displayName}: value));\n
        
        ''';
        stringBuffer.writeln(state);
      }
    }
    stringBuffer.writeln('''
    void submit(response) => emit(${className}SubmittedState(response));

    void submitting() => emit(${className}SubmittingState());
    ''');
    return stringBuffer.toString();
  }


}
