import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hubster_app/core/api/api_client.dart';
import 'package:injectable/injectable.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class UploadResponse {
  final String imageUrl;
  UploadResponse({required this.imageUrl});

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(imageUrl: json['image_url']);
  }
}

@lazySingleton
class UploadService {
  final ApiClient _apiClient;
  UploadService(this._apiClient);

  Future<String?> uploadImage(File imageFile) async {
    print("UploadService: Uploading image");
    try {
      String fileName = path.basename(imageFile.path);
      String fileExtension = path.extension(imageFile.path).toLowerCase();
      MediaType? contentType;

      if (fileExtension == ".jpg" || fileExtension == ".jpeg") {
        contentType = MediaType('image', 'jpeg');
      } else if (fileExtension == ".png") {
        contentType = MediaType('image', 'png');
      } else {
        print(
          "UploadService: Unsupported file extension '$fileExtension' for content type setting.",
        );
      }

      print(
        "UploadService: Determined filename: $fileName, extension: $fileExtension, attempting content type: $contentType",
      );
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: contentType,
        ),
      });

      final response = await _apiClient.dio.post(
        '/uploads/images',
        data: formData,
      );
      final uploadResponse = UploadResponse.fromJson(response.data);
      print("UploadService: Image uploaded, URL: ${uploadResponse.imageUrl}");
      return uploadResponse.imageUrl;
    } on DioException catch (e) {
      print(
        "UploadService: uploadImage DioException - Status: ${e.response?.statusCode}, Data: ${e.response?.data}, Message: ${e.message}",
      );
      throw Exception(
        e.response?.data['error'] ?? e.message ?? 'Failed to upload image',
      );
    } catch (e) {
      print("UploadService: uploadImage general error - $e");
      throw Exception('An unexpected error occurred during image upload.');
    }
  }
}
