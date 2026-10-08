import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:talk_in/ui/user_flow/edit_profile_screen/model/edit_profile_model.dart';
import 'package:talk_in/utils/api.dart';
import 'package:talk_in/utils/api_params.dart';
import 'package:talk_in/utils/utils.dart';

class EditProfileApi {
  static Future<List<int>?> _compressImageFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      Utils.showLog("Edit Profile Api Original Image Size => ${bytes.lengthInBytes} bytes");

      // Decode the image
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        Utils.showLog("Edit Profile Api Image decode failed, using original bytes");
        return bytes;
      }

      // Max dimensions for profile picture (1024x1024)
      img.Image resized = decodedImage;
      const int maxDimension = 1024;

      if (decodedImage.width > maxDimension || decodedImage.height > maxDimension) {
        if (decodedImage.width > decodedImage.height) {
          resized = img.copyResize(decodedImage, width: maxDimension);
        } else {
          resized = img.copyResize(decodedImage, height: maxDimension);
        }
      }

      // Compress to JPEG with quality 80
      final compressedBytes = img.encodeJpg(resized, quality: 80);
      Utils.showLog("Edit Profile Api Compressed Image Size => ${compressedBytes.length} bytes");
      return compressedBytes;
    } catch (e) {
      Utils.showLog("Edit Profile Api Image compression exception => $e");
      try {
        return await file.readAsBytes();
      } catch (_) {
        return null;
      }
    }
  }

  static Future<EditProfileModel?> callApi({
    required String uid,
    String? loginUserId,
    required String nickName,
    required String gender,
    required String phoneNumber,
    required String birthDate,
    required String? country,
    required String? countryFlag,
    String? countryCode,
    String? image,
    String? fullName,
    String? email,
  }) async {
    Utils.showLog("Edit Profile Api Calling...");

    try {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse(Api.editProfile),
      );
      Utils.showLog("Edit Profile Api URL => ${request.url}");

      var headers = {
        ApiParams.key: Api.secretKey,
        ApiParams.authToken: 'Bearer ${Api.secretKey}',
        ApiParams.authUid: uid,
      };
      Utils.showLog("Edit Profile Api Headers => $headers");

      request.fields.addAll({
        ApiParams.userId: uid,
        ApiParams.email: email ?? '',
        ApiParams.fullName: fullName ?? "",
        ApiParams.nickName: nickName,
        ApiParams.birthDate: birthDate,
        ApiParams.gender: gender,
        ApiParams.phoneNumber: phoneNumber,
        ApiParams.countryCode: countryCode ?? '',
        ApiParams.country: country ?? '',
        ApiParams.countryFlag: countryFlag ?? '',
      });

      // Safely check if image is a local file before adding as MultipartFile
      if (image != null &&
          image.isNotEmpty &&
          !image.startsWith('http://') &&
          !image.startsWith('https://') &&
          !image.startsWith('assets/')) {
        final file = File(image);
        if (file.existsSync()) {
          final compressedBytes = await _compressImageFile(file);
          if (compressedBytes != null && compressedBytes.isNotEmpty) {
            final fileName = file.path.split('/').last;
            request.files.add(
              http.MultipartFile.fromBytes(
                'profilePic',
                compressedBytes,
                filename: fileName.isNotEmpty ? fileName : 'profile.jpg',
              ),
            );
            Utils.showLog("Edit Profile Api Added Compressed File => $image (${compressedBytes.length} bytes)");
          } else {
            request.files.add(await http.MultipartFile.fromPath('profilePic', image));
            Utils.showLog("Edit Profile Api Added File from path => $image");
          }
        } else {
          request.fields[ApiParams.profilePic] = image;
        }
      } else if (image != null && image.isNotEmpty) {
        request.fields[ApiParams.profilePic] = image;
      }

      request.headers.addAll(headers);
      log("Edit Profile Api Request Fields => ${request.fields}");

      final response = await request.send();
      log("Edit Profile Api Response StatusCode => ${response.statusCode}");

      final responseBody = await response.stream.bytesToString();
      log("Edit Profile Api Response Body => $responseBody");

      if (response.statusCode == 413) {
        Utils.showLog("Edit Profile Api Server error 413: Request Entity Too Large");
        return EditProfileModel(
          status: false,
          message: "Image file size is too large. Please select a smaller image.",
        );
      }

      try {
        final jsonResult = jsonDecode(responseBody);
        Utils.showLog("Edit Profile Api Parsed JSON => $jsonResult");
        if (jsonResult is Map<String, dynamic>) {
          return EditProfileModel.fromJson(jsonResult);
        } else {
          Utils.showLog("Edit Profile Api Parsed JSON is not a Map");
          return EditProfileModel(
            status: false,
            message: "Unexpected response format from server.",
          );
        }
      } catch (e) {
        Utils.showLog("Edit Profile Api Non-JSON response or JSON decode error => $e");
        return EditProfileModel(
          status: false,
          message: response.statusCode == 200
              ? "Failed to parse server response."
              : "Server error (${response.statusCode})",
        );
      }
    } catch (e, stackTrace) {
      Utils.showLog("Edit Profile Api Error => $e");
      log("Edit Profile Api StackTrace => $stackTrace");
      return null;
    }
  }
}

