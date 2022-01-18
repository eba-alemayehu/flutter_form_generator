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
      print(field);
    }
  }

  String handleFieldsAnnotation(Element element) {
    for (var field in (element as ClassElement).fields) {
      if (_coreChecker.hasAnnotationOfExact(field)) {
        handleField(field);
      }
    }
    // widget = widget.replaceAll(
    //     "// #fields#", fields.join(',SizedBox(height: 4.0),'));
    return fields.join(',SizedBox(height: 4.0),');
  }

  void handleField(FieldElement fieldElement) {
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

      if (type == "dropdown") {
        this.fields.add(writeDropdownField(fieldElement, field, validators,
            inputDecorations: inputDecorationStr));
      } else if (type == 'filter_chip') {
        this.fields.add(writeFilterChipField(fieldElement, field,
            inputDecorations: inputDecorationStr));
      } else if (type == 'choice_chip') {
        this.fields.add(writeChoiceChipField(fieldElement, field,
            inputDecorations: inputDecorationStr));
      } else if (type == 'date_time') {
        this.fields.add(writeDateTimePickerField(fieldElement, field,
            inputDecorations: inputDecorationStr));
      } else if (type == 'date_range') {
        this.fields.add(writeDateRangePickerField(fieldElement, field,
            inputDecorations: inputDecorationStr));
      } else if (type == 'slider') {
        this.fields.add(writeSliderField(fieldElement, field,
            inputDecorations: inputDecorationStr));
      } else if (type == 'checkbox') {
        this.fields.add(writeCheckboxField(fieldElement, field, validators,
            inputDecorations: inputDecorationStr));
      } else {
        this.fields.add(writeTextField(fieldElement, validators,
            type: type, inputDecorations: inputDecorationStr));
      }
    }
  }

  String writeDropdownField(
      FieldElement fieldElement, DartObject field, validators,
      {inputDecorations = ''}) {
    return '''
          FormBuilderDropdown(
                name: '${fieldElement.displayName}',
                decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
                // initialValue: 'Male',
                allowClear: true,
                hint: Text('${field.getField('hint')?.toStringValue()}'),
                validator: ${(validators != null) ? writeValidators(validators) : ''},
                items: ${className}.${fieldElement.displayName}Items(),
                onChanged: (value) {
                    BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                  },
              )
          '''
        .replaceAll(
            '${(validators != null) ? writeValidators(validators) : ''}',
            (validators != null) ? writeValidators(validators) : '');
  }

  String writeChoiceChipField(FieldElement fieldElement, DartObject field,
      {inputDecorations = ''}) {
    return '''
          FormBuilderChoiceChip(
                name: '${fieldElement.displayName}',
                decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
                options: ${className}.${fieldElement.displayName}Options(),
                onChanged: (value) {
                    BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                  },
              )
          ''';
  }

  String writeFilterChipField(FieldElement fieldElement, DartObject field,
      {inputDecorations = ''}) {
    return '''
          FormBuilderFilterChip(
                name: '${fieldElement.displayName}',
                decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
                options: ${className}.${fieldElement.displayName}Options(),
                onChanged: (value) {
                    BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                  },
              )
          ''';
  }

  String writeDateTimePickerField(FieldElement fieldElement, DartObject field,
      {inputDecorations = ''}) {
    return '''
          FormBuilderDateTimePicker(
                name: '${fieldElement.displayName}',
                inputType: InputType.time,
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
                onChanged: (value) {
                  BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                },
                decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
              )
          ''';
  }

  String writeSliderField(FieldElement fieldElement, DartObject field,
      {inputDecorations = ''}) {
    return '''
          FormBuilderSlider(
                name: '${fieldElement.displayName}',
                onChanged: (value) {
                  BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                },
                min: 0.0,
                max: 10.0,
                initialValue: 7.0,
                divisions: 20,
                activeColor: Colors.red,
                inactiveColor: Colors.pink[100],
                decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
              )
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
        break;
    }
    return '''
            FormBuilderTextField(
                  name: '${fieldElement.displayName}',
                  decoration: (widget.decoration ?? InputDecoration()).copyWith(${inputDecorations}),
                  validator: ${(validators != null) ? writeValidators(validators) : ''},
                  keyboardType: ${keyboardType},
                  onChanged: (value) {
                    BlocProvider.of<${className}Cubit>(context).${fieldElement.displayName}Changed(value);
                  },
            )
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
      ${element.displayName}Form({Key? key, this.decoration = null, this.onSubmit = null}) : super(key: key){
        if(decoration == null){
          decoration = ${decoratorMethod.isNotEmpty ? '${element.displayName}.decoration();' : 'InputDecoration();'}
        }
      }
    
      @override
      _${element.displayName}FormState createState() => _${element.displayName}FormState();
    }
    
    class _${element.displayName}FormState extends State<${element.displayName}Form> {
      final _formKey = GlobalKey<FormBuilderState>();
      @override
      Widget build(BuildContext context) {
        return Container(
          child: Column(
            children: <Widget>[
              FormBuilder(
                key: _formKey,
                autovalidateMode: AutovalidateMode.always,
                child: Column(
                  children: <Widget>[
                    ${handleFieldsAnnotation(element)}
                  ],
                ),
              ),
              ${writeSubmitButton(element)}
            ],
          )
        );
      }
      
      ${writeSubmittingFunction()}
    }
    ''';
  }

  String writeSubmitButton(element) {
    return '''
          Row(
            children: <Widget>[
              Expanded(
                child: MaterialButton(
                  color: Theme.of(context).colorScheme.secondary,
                  child: Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _submit,
                ),
              ),
            ],
          )
    ''';
  }

  String writeSubmittingFunction() {
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
      print(e);
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
        print(field.type);
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
