import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talk_in/custom/custom_country_picker/country_picker.dart';
import 'package:talk_in/custom/progress_indicator/progress_dialog.dart';
import 'package:talk_in/ui/user_flow/edit_profile_screen/api/edit_profile_api.dart';
import 'package:talk_in/ui/user_flow/edit_profile_screen/model/edit_profile_model.dart';
import 'package:talk_in/ui/user_flow/splash_screen_page/api/fetch_login_user_profile_api.dart';
import 'package:talk_in/ui/user_flow/splash_screen_page/model/fetch_login_user_profile_model.dart';
import 'package:talk_in/utils/api.dart';
import 'package:talk_in/utils/app_asset.dart';
import 'package:talk_in/utils/app_color.dart';
import 'package:talk_in/utils/constant.dart';
import 'package:talk_in/utils/database.dart';
import 'package:talk_in/utils/enums.dart';
import 'package:talk_in/utils/font_style.dart';
import 'package:talk_in/utils/utils.dart';

class EditProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();
  TextEditingController dateController = TextEditingController();
  TextEditingController nickNameCnt = TextEditingController();
  TextEditingController nameCnt = TextEditingController();
  TextEditingController emailCnt = TextEditingController();
  TextEditingController genderCnt = TextEditingController();
  TextEditingController mobileNumberCnt = TextEditingController();
  TextEditingController flagController = TextEditingController();
  TextEditingController countryController = TextEditingController();

  // MainScreenController mainScreenController = Get.put(MainScreenController());
  XFile? xFiles;
  final ImagePicker imagePicker = ImagePicker();
  int selectedIndex = 0; // Already hase
  String? profilePic;
  String? pickImage;
  EditProfileModel? editProfileModel;
  String? dialCode;

  FetchLoginUserProfileModel? fetchLoginUserProfileModel;

  @override
  void onInit() {
    log("Database.loginUserNickName  :: ${Database.loginUserNickName}");
    log("Database.loginUserBirthDate :: ${Database.loginUserBirthDate}");
    log("Database.loginUserEmail  :: ${Database.loginUserEmail}");
    log("Database.loginUserNickName  :: ${Database.loginUserNickName}");
    log("Database.loginUserGender  :: ${Database.loginUserGender}");
    log("Database.loginUserPhoneNumber  :: ${Database.loginUserPhoneNumber}");
    log("Database.loginUserProfilePic  ::  ${Database.loginUserProfilePic}");
    log("fetchLoginUserProfileModel?.user?.country  ::  ${fetchLoginUserProfileModel?.user?.country ?? ''}");
    log("fetchLoginUserProfileModel?.user?.countryFlag  ::  ${fetchLoginUserProfileModel?.user?.countryFlag ?? ''}");

    dateController.text = Database.loginUserBirthDate;
    nameCnt.text = Database.loginUserName;
    emailCnt.text = Database.loginUserEmail;
    nickNameCnt.text = Database.loginUserNickName;
    genderCnt.text = Database.loginUserGender;
    mobileNumberCnt.text = Database.loginUserPhoneNumber;
    countryController.text = Database.country;
    flagController.text = Database.countryFlag;
    profilePic = Database.loginUserProfilePic;
    dialCode = Database.dialCode;

    if (Database.loginUserGender.toLowerCase() ==
        EnumLocale.txtFemale.name.tr.toLowerCase()) {
      selectedIndex = 1;
    } else {
      selectedIndex = 0;
    }

    super.onInit();
  }

  List<Map<String, dynamic>> gender = [
    {
      "txt": EnumLocale.txtMale.name.tr,
      "image": AppAsset.maleImage,
    },
    {
      "txt": EnumLocale.txtFemale.name.tr,
      "image": AppAsset.femaleImage,
    },
  ];

  /// select gender
  void selectGender(int index) {
    selectedIndex = index;
    final selectedGenderText = gender[selectedIndex]['txt'] ?? 'Male';
    genderCnt.text = selectedGenderText;

    // Save selected gender locally
    Database.onSetLoginUserGender(selectedGenderText ?? 'Male');

    log("Database.loginUserGender :: ${Database.loginUserGender}");

    update([Constant.idGenderSelect]);
    // update();
  }

  /// select date
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            dividerColor: Colors.transparent,
            colorScheme: ColorScheme.dark(
              primary: AppColors.lightPurple,      // selected date circle & header
              onPrimary: Colors.white,             // text ON the purple circle
              surface: const Color(0xFF1E1E2E),          // dialog background
              onSurface: Colors.white,             // calendar day numbers
              secondary: AppColors.lightPurple,
              onSecondary: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E2E),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,  // OK / CANCEL visible
                textStyle: AppFontStyle.fontStyleW600(
                  fontSize: 14,
                  fontColor: AppColors.lightPurple,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dateController.text =
      "${picked.day.toString().padLeft(2, '0')} / ${picked.month.toString().padLeft(2, '0')} / ${picked.year}";
      update();
    }
  }
  /// Image Picker from gallery
  getImageFromGallery() async {
    xFiles = await imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 100);
    if (xFiles != null) {
      pickImage = xFiles!.path;
      log("Gallery Image Path ::: $pickImage");
    }
    update();
  }

  /// Take Photo
  takePhoto() async {
    xFiles = await imagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 100);
    if (xFiles != null) {
      pickImage = xFiles!.path;
      log("Camera Image Path ::: $pickImage");
    }
    update();
  }

  /// save profile button on tap
  Future<void> onSaveProfile() async {
    Database.onSetFillProfile(true);

    Utils.showLog("Click On Save Profile => ${Database.loginUserId}");

    if (profilePic == "" && pickImage == null) {
      Utils.showToast(
          Get.context!, EnumLocale.txtPleaseSelectProfileImage.name.tr);
    } else if (nickNameCnt.text.trim().isEmpty) {
      Utils.showToast(Get.context!, EnumLocale.txtPleaseEnterNickName.name.tr);
    } else if (dateController.text.trim().isEmpty) {
      Utils.showToast(
          Get.context!, EnumLocale.txtPleaseSelectBirthDate.name.tr);
    } else if (mobileNumberCnt.text.trim().isEmpty) {
      Utils.showToast(
          Get.context!, EnumLocale.txtPleaseEnterMobileNumber.name.tr);
    } else {
      Get.dialog(const LoadingWidget(),
          barrierDismissible: false); // Start Loading...

      await callEditApi();
    }
  }

  /// edit profile api
  Future<void> callEditApi({String? image}) async {
    log('Database.countryCode  ::::  ${Database.selectedCountryCode}');
    log('countryController.text  ::::  ${countryController.text}');
    log('flagController.text  ::::  ${flagController.text}');

    debugPrint("Calling EditProfileApi with following data:");
    debugPrint("country: ${countryController.text}");
    debugPrint("countryFlag: ${flagController.text}");
    debugPrint("countryCode: ${Database.selectedCountryCode}");
    debugPrint("uid: ${Database.loginUserId}");
    debugPrint("birthDate: ${dateController.text}");
    debugPrint("image: ${pickImage == "" ? profilePic : pickImage}");
    debugPrint("nickName: ${nickNameCnt.text}");
    debugPrint("gender: ${Database.loginUserGender}");
    debugPrint("phoneNumber: ${mobileNumberCnt.text}");
    debugPrint("fullName: ${nameCnt.text}");

    final uidToUse = (Database.fetchLoginUserProfileModel?.user?.id != null &&
            Database.fetchLoginUserProfileModel!.user!.id!.isNotEmpty)
        ? Database.fetchLoginUserProfileModel!.user!.id!
        : (Database.loginUserId.isNotEmpty
            ? Database.loginUserId
            : Database.loginUserFirebaseId);

    editProfileModel = await EditProfileApi.callApi(
      country: countryController.text.isNotEmpty ? countryController.text : (Database.country.isNotEmpty ? Database.country : "India"),
      countryFlag: flagController.text.isNotEmpty ? flagController.text : (Database.countryFlag.isNotEmpty ? Database.countryFlag : "🇮🇳"),
      countryCode: Database.selectedCountryCode.isNotEmpty ? Database.selectedCountryCode : "IN",
      uid: uidToUse,
      birthDate: dateController.text,
      image: (pickImage != null && pickImage!.isNotEmpty) ? pickImage : profilePic,
      nickName: nickNameCnt.text,
      gender: Database.loginUserGender,
      phoneNumber: mobileNumberCnt.text,
      fullName: nameCnt.text,
      email: emailCnt.text,
    );

    if (editProfileModel?.status == true) {
      Utils.showToast(
          Get.context!, EnumLocale.txtProfileUpdateSuccessfully.name.tr);
      fetchLoginUserProfileModel = await FetchLoginUserProfileApi.callApi(
          loginUserId: uidToUse, token: Api.secretKey);

      if (fetchLoginUserProfileModel != null) {
        Database.onSetLoginUserProfilePic(
            fetchLoginUserProfileModel?.user?.profilePic ?? "");
        Database.onSetLoginUserName(
            fetchLoginUserProfileModel?.user?.fullName ?? nameCnt.text);
        Database.onSetLoginUserNickName(
            fetchLoginUserProfileModel?.user?.nickName ?? nickNameCnt.text);
        Database.onSetLoginUserEmail(
            fetchLoginUserProfileModel?.user?.email ?? emailCnt.text);
        Database.onSetLoginUserCountry(
            fetchLoginUserProfileModel?.user?.country ?? countryController.text);
        Database.onSetLoginUserCountryFlag(
            fetchLoginUserProfileModel?.user?.countryFlag ?? flagController.text);
        Database.onSetLoginUserBirthDate(
            fetchLoginUserProfileModel?.user?.birthDate ?? dateController.text);
        Database.onSetLoginUserGender(
            fetchLoginUserProfileModel?.user?.gender ?? Database.loginUserGender);
        Database.onSetLoginUserPhoneNumber(
            fetchLoginUserProfileModel?.user?.phoneNumber ?? mobileNumberCnt.text);
        Database.fetchLoginUserProfileModel = fetchLoginUserProfileModel;
      }

      update([Constant.idProfile]);

      if (Get.isDialogOpen ?? false) Get.back();
      Get.back();
      update();
    } else {
      if (Get.isDialogOpen ?? false) Get.back();
      final errorMessage = editProfileModel?.message ?? EnumLocale.txtSomeThingWentWrong.name.tr;
      Utils.showToast(Get.context!, errorMessage);
    }
  }

  /// Country
  Future<void> onChangeCountry(BuildContext context) async {
    CustomCountryPicker.pickCountry(
      context,
      false,
      (country) {
        flagController.text = country.flagEmoji;
        countryController.text = country.name;
        update([Constant.idChangeCountry]);
        debugPrint(
            "Country selected: ${country.name}, Flag: ${country.flagEmoji}");
        log("Selected Country => Flag: ${flagController.text}, Name: ${countryController.text}");
      },
    );

    update([Constant.idChangeCountry]);
  }
}
