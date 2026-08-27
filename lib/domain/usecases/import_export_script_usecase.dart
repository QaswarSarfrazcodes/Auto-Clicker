import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import '../../core/error/failure.dart';
import '../../core/util/logger.dart';
import '../entities/script_entity.dart';
import 'script_validator.dart';

/// UseCase for importing and exporting script JSON files off-thread safely.
class ImportExportScriptUseCase {
  /// Import a script from a user-selected `.json` file.
  static Future<Result<Failure, ScriptEntity>> importScriptFromFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return const Result.failure(StorageFailure('File selection cancelled.'));
      }

      final fileBytes = result.files.first.bytes;
      final filePath = result.files.first.path;
      String jsonContent;

      if (fileBytes != null) {
        jsonContent = utf8.decode(fileBytes);
      } else if (filePath != null) {
        jsonContent = await File(filePath).readAsString();
      } else {
        return const Result.failure(StorageFailure('Unable to read file data.'));
      }

      if (jsonContent.isEmpty) {
        return const Result.failure(ValidationFailure('Selected file is empty.'));
      }

      final ScriptEntity script = ScriptEntity.decodeJson(jsonContent);

      // Validate imported script rules
      final validationResult = ScriptValidator.validateEntity(script);
      if (validationResult.isFailure) {
        return Result.failure(validationResult.failureOrNull!);
      }

      logDebug('Successfully imported script "${script.name}"');
      return Result.success(script);
    } catch (e) {
      logDebug('importScriptFromFile error: $e');
      return Result.failure(ValidationFailure('Malformed JSON script file: $e'));
    }
  }

  /// Export a script into a formatted JSON string.
  static String exportScriptToJson(ScriptEntity script) {
    return script.encodeJson();
  }
}
