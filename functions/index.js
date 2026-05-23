const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendUserNotificationPush = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    const notification = event.data && event.data.data();
    if (!notification) return;

    const userId = event.params.userId;
    const notificationId = event.params.notificationId;
    const userRef = admin.firestore().collection("users").doc(userId);
    const userSnapshot = await userRef.get();
    const user = userSnapshot.data() || {};
    const tokens = Array.isArray(user.fcmTokens)
      ? user.fcmTokens.filter((token) => typeof token === "string" && token)
      : [];

    if (tokens.length === 0) {
      logger.info("No FCM tokens for notification receiver", { userId });
      return;
    }

    const title = String(notification.title || "Foodopia");
    const body = String(notification.message || "You have a new notification.");
    const type = String(notification.type || "notification");

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: {
        notificationId,
        type,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "foodopia_social_notifications",
          sound: "default",
        },
      },
    });

    const invalidTokens = [];
    response.responses.forEach((item, index) => {
      if (!item.success) {
        const code = item.error && item.error.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(tokens[index]);
        }
        logger.warn("Failed to send notification push", {
          userId,
          code,
          message: item.error && item.error.message,
        });
      }
    });

    if (invalidTokens.length > 0) {
      await userRef.update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
    }
  }
);
