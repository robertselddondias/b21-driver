// lib/ui/chat_screen/chat_screen.dart - Versão com temas e responsividade
import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/conversation_model.dart';
import 'package:driver/model/inbox_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/chat_screen/FullScreenImageViewer.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/firebase_pagination/src/firestore_pagination.dart';
import 'package:driver/widget/firebase_pagination/src/models/view_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ChatScreens extends StatefulWidget {
  final String? orderId;
  final String? customerId;
  final String? customerName;
  final String? customerProfileImage;
  final String? driverId;
  final String? driverName;
  final String? driverProfileImage;
  final String? token;

  const ChatScreens(
      {super.key,
      this.orderId,
      this.customerId,
      this.customerName,
      this.driverName,
      this.driverId,
      this.customerProfileImage,
      this.driverProfileImage,
      this.token});

  @override
  State<ChatScreens> createState() => _ChatScreensState();
}

class _ChatScreensState extends State<ChatScreens> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    if (_controller.hasClients) {
      Timer(const Duration(milliseconds: 500),
          () => _controller.jumpTo(_controller.position.maxScrollExtent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeChange.getThem()
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 2,
        title: Text(
          "${widget.customerName.toString()}\n#${widget.orderId.toString()}",
          maxLines: 2,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: Responsive.width(3.5, context),
          ),
        ),
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: Responsive.width(6, context),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: themeChange.getThem()
              ? AppColors.darkBackground
              : AppColors.background,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: Responsive.width(2, context),
            right: Responsive.width(2, context),
            bottom: Responsive.width(2, context),
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      // currentRecordingState = RecordingState.HIDDEN;
                    });
                  },
                  child: FirestorePagination(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, documentSnapshots, index) {
                      ConversationModel inboxModel = ConversationModel.fromJson(
                          documentSnapshots[index].data()
                              as Map<String, dynamic>);
                      return chatItemView(
                          inboxModel.senderId == FireStoreUtils.getCurrentUid(),
                          inboxModel);
                    },
                    onEmpty: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: Responsive.width(15, context),
                            color: AppColors.subTitleColor,
                          ),
                          SizedBox(height: Responsive.height(2, context)),
                          Text(
                            "No Conversion found".tr,
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.width(4, context),
                              color: AppColors.subTitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    query: FirebaseFirestore.instance
                        .collection(CollectionName.chat)
                        .doc(widget.orderId)
                        .collection("thread")
                        .orderBy('createdAt', descending: false),
                    viewType: ViewType.list,
                    isLive: true,
                  ),
                ),
              ),

              // Message Input
              Container(
                padding: EdgeInsets.all(Responsive.width(2, context)),
                decoration: BoxDecoration(
                  color: themeChange.getThem()
                      ? AppColors.darkContainerBackground
                      : AppColors.containerBackground,
                  border: Border(
                    top: BorderSide(
                      color: themeChange.getThem()
                          ? AppColors.darkContainerBorder
                          : AppColors.containerBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeChange.getThem()
                                ? AppColors.darkTextField
                                : AppColors.textField,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: themeChange.getThem()
                                  ? AppColors.darkTextFieldBorder
                                  : AppColors.textFieldBorder,
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            textInputAction: TextInputAction.send,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.sentences,
                            style: GoogleFonts.poppins(
                              color: themeChange.getThem()
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: Responsive.width(3.8, context),
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: Responsive.width(4, context),
                                vertical: Responsive.height(1.2, context),
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: 'Start typing ...'.tr,
                              hintStyle: GoogleFonts.poppins(
                                color: AppColors.subTitleColor,
                                fontSize: Responsive.width(3.8, context),
                              ),
                              prefixIcon: IconButton(
                                onPressed: () async {
                                  _onCameraClick();
                                },
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: themeChange.getThem()
                                      ? Colors.white70
                                      : Colors.black54,
                                  size: Responsive.width(6, context),
                                ),
                              ),
                            ),
                            onSubmitted: (value) async {
                              if (_messageController.text.isNotEmpty) {
                                _sendMessage(
                                    _messageController.text, null, '', 'text');
                                Timer(
                                    const Duration(milliseconds: 500),
                                    () => _controller.jumpTo(
                                        _controller.position.maxScrollExtent));
                                _messageController.clear();
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.width(2, context)),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            if (_messageController.text.isNotEmpty) {
                              _sendMessage(
                                  _messageController.text, null, '', 'text');
                              _messageController.clear();
                              setState(() {});
                            } else {
                              ShowToastDialog.showToast("Please enter text".tr);
                            }
                          },
                          icon: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: Responsive.width(5.5, context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chatItemView(bool isMe, ConversationModel data) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Container(
      padding: EdgeInsets.only(
        left: Responsive.width(3.5, context),
        right: Responsive.width(3.5, context),
        top: Responsive.height(1.2, context),
        bottom: Responsive.height(1.2, context),
      ),
      child: isMe
          ? Align(
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Message or Image
                  data.messageType == 'text'
                      ? Container(
                          constraints: BoxConstraints(
                            maxWidth: Responsive.width(75, context),
                          ),
                          decoration: BoxDecoration(
                            color: themeChange.getThem()
                                ? AppColors.darkModePrimary
                                : AppColors.primary,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: Responsive.width(4, context),
                              vertical: Responsive.height(1.2, context)),
                          child: Text(
                            data.message.toString(),
                            style: GoogleFonts.poppins(
                              color: themeChange.getThem()
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: Responsive.width(3.8, context),
                            ),
                          ),
                        )
                      : ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: Responsive.width(12, context),
                            maxWidth: Responsive.width(60, context),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(15)),
                            child:
                                Stack(alignment: Alignment.center, children: [
                              GestureDetector(
                                onTap: () {
                                  Get.to(FullScreenImageViewer(
                                    imageUrl: data.url!.url,
                                  ));
                                },
                                child: Hero(
                                  tag: data.url!.url,
                                  child: CachedNetworkImage(
                                    imageUrl: data.url!.url,
                                    placeholder: (context, url) => SizedBox(
                                      height: Responsive.height(20, context),
                                      child: Center(
                                          child: Constant.loader(context)),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        SizedBox(
                                      height: Responsive.height(20, context),
                                      child: const Icon(Icons.error,
                                          color: Colors.red),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          )),

                  SizedBox(height: Responsive.height(0.5, context)),

                  // Message Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Me".tr,
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.width(3, context),
                            fontWeight: FontWeight.w500,
                            color: themeChange.getThem()
                                ? Colors.white70
                                : Colors.black54,
                          )),
                      Text(Constant.dateAndTimeFormatTimestamp(data.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.width(2.8, context),
                            fontWeight: FontWeight.w400,
                            color: AppColors.subTitleColor,
                          )),
                    ],
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Message or Image
                    data.messageType == 'text'
                        ? Container(
                            constraints: BoxConstraints(
                              maxWidth: Responsive.width(75, context),
                            ),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                  bottomRight: Radius.circular(15)),
                              color: themeChange.getThem()
                                  ? AppColors.darkContainerBackground
                                  : Colors.grey.shade200,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: Responsive.width(4, context),
                                vertical: Responsive.height(1.2, context)),
                            child: Text(
                              data.message.toString(),
                              style: GoogleFonts.poppins(
                                color: themeChange.getThem()
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: Responsive.width(3.8, context),
                              ),
                            ),
                          )
                        : ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: Responsive.width(12, context),
                              maxWidth: Responsive.width(60, context),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                  bottomRight: Radius.circular(15)),
                              child:
                                  Stack(alignment: Alignment.center, children: [
                                GestureDetector(
                                  onTap: () {
                                    Get.to(FullScreenImageViewer(
                                      imageUrl: data.url!.url,
                                    ));
                                  },
                                  child: Hero(
                                    tag: data.url!.url,
                                    child: CachedNetworkImage(
                                      imageUrl: data.url!.url,
                                      placeholder: (context, url) => SizedBox(
                                        height: Responsive.height(20, context),
                                        child: Center(
                                            child: Constant.loader(context)),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          SizedBox(
                                        height: Responsive.height(20, context),
                                        child: const Icon(Icons.error,
                                            color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            )),
                  ],
                ),

                SizedBox(height: Responsive.height(0.5, context)),

                // Message Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.customerName.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.width(3, context),
                          fontWeight: FontWeight.w500,
                          color: themeChange.getThem()
                              ? Colors.white70
                              : Colors.black54,
                        )),
                    Text(Constant.dateAndTimeFormatTimestamp(data.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.width(2.8, context),
                          fontWeight: FontWeight.w400,
                          color: AppColors.subTitleColor,
                        )),
                  ],
                ),
              ],
            ),
    );
  }

  _sendMessage(String message, Url? url, String videoThumbnail,
      String messageType) async {
    InboxModel inboxModel = InboxModel(
        lastSenderId: widget.customerId,
        customerId: widget.customerId,
        customerName: widget.customerName,
        driverId: widget.driverId,
        driverName: widget.driverName,
        driverProfileImage: widget.driverProfileImage,
        createdAt: Timestamp.now(),
        orderId: widget.orderId,
        customerProfileImage: widget.customerProfileImage,
        lastMessage: _messageController.text);

    await FireStoreUtils.addInBox(inboxModel);

    ConversationModel conversationModel = ConversationModel(
        id: const Uuid().v4(),
        message: message,
        senderId: FireStoreUtils.getCurrentUid(),
        receiverId: widget.driverId,
        createdAt: Timestamp.now(),
        url: url,
        orderId: widget.orderId,
        messageType: messageType,
        videoThumbnail: videoThumbnail);

    if (url != null) {
      if (url.mime.contains('image')) {
        conversationModel.message = "sent an image";
      } else if (url.mime.contains('video')) {
        conversationModel.message = "sent an Video";
      } else if (url.mime.contains('audio')) {
        conversationModel.message = "Sent a voice message";
      }
    }

    await FireStoreUtils.addChat(conversationModel);

    Map<String, dynamic> playLoad = <String, dynamic>{
      "type": "chat",
      "driverId": widget.driverId,
      "customerId": widget.customerId,
      "orderId": widget.orderId,
    };

    SendNotification.sendOneNotification(
        title:
            "${widget.driverName} ${messageType == "image" ? messageType == "video" ? "sent video to you" : "sent image to you" : "sent message to you"}",
        body: conversationModel.message.toString(),
        token: widget.token.toString(),
        payload: playLoad);
  }

  final ImagePicker _imagePicker = ImagePicker();

  _onCameraClick() {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);

    final action = CupertinoActionSheet(
      message: Text(
        'Send Media'.tr,
        style: GoogleFonts.poppins(
          fontSize: Responsive.width(3.8, context),
          color: themeChange.getThem() ? Colors.white70 : Colors.black87,
        ),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Get.back();
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              Url url = await Constant()
                  .uploadChatImageToFireStorage(File(image.path));
              _sendMessage('', url, '', 'image');
            }
          },
          child: Text(
            "Choose image from gallery".tr,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(3.8, context),
              color: AppColors.primary,
            ),
          ),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.camera);
            if (image != null) {
              Url url = await Constant()
                  .uploadChatImageToFireStorage(File(image.path));
              _sendMessage('', url, '', 'image');
            }
          },
          child: Text(
            "Take a Photo".tr,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(3.8, context),
              color: AppColors.primary,
            ),
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(
          'Cancel'.tr,
          style: GoogleFonts.poppins(
            fontSize: Responsive.width(3.8, context),
            color: Colors.red,
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }
}
