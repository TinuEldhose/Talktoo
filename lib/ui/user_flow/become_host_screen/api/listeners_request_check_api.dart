import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:talk_in/ui/user_flow/become_host_screen/model/listeners_request_check_model.dart';
import 'package:talk_in/utils/api.dart';
import 'package:talk_in/utils/api_params.dart';
import 'package:talk_in/utils/database.dart';
import 'package:talk_in/utils/utils.dart';

class ListenersRequestCheckApi {
  static Future<ListenersRequestCheckModel?> callApi({String? uid}) async {
    Utils.showLog("Listeners Request check Api Calling...");

    final String userId = (uid != null && uid.isNotEmpty)
        ? uid
        : (Database.loginUserId.isNotEmpty
            ? Database.loginUserId
            : (Database.fetchLoginUserProfileModel?.user?.id ?? ""));

    Utils.showLog("Listeners Request check Api UID :: $userId");

    if (userId.isEmpty) {
      Utils.showLog("Listeners Request check Api: No valid loginUserId found");
      return ListenersRequestCheckModel(
        status: false,
        message: "Request not found for that user!",
      );
    }

    final uri = Uri.parse(Api.listenersRequestCheck);

    final headers = {
      ApiParams.key: Api.secretKey,
      ApiParams.authToken: "Bearer ${Api.secretKey}",
      ApiParams.authUid: userId,
      ApiParams.contentType: "application/json",
    };
    Utils.showLog("Listeners Request check Api uri :: $uri");
    Utils.showLog("Listeners Request check Api headers :: $headers");

    try {
      final response = await http.get(uri, headers: headers);

      log('Listeners Request check API STATUS CODE :: ${response.statusCode} \n RESPONSE :: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ListenersRequestCheckModel.fromJson(jsonResponse);
      } else {
        Utils.showLog("Listeners Request check API status code :: ${response.statusCode}");
        return ListenersRequestCheckModel(
          status: false,
          message: "Request not found for that user!",
        );
      }
    } catch (e) {
      log("Listeners Request check error :: $e");
      return ListenersRequestCheckModel(
        status: false,
        message: "Request not found for that user!",
      );
    }
  }
}

