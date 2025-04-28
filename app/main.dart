import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'splash_page.dart';
import 'login_page.dart';
import 'sign_up_page.dart';
import 'add_car_screen.dart';
import 'main_layout.dart';
import 'after_splash.dart';
import 'email_verification_page.dart';
import 'appointments_screen.dart';
import 'book_appointment_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


// Function to handle notifications received in the background
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 إشعار في الخلفية: ${message.notification?.title}");
}

void main() async {
  // Ensure Flutter binding is initialized before any async operation
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background notification handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Request notification permissions from the user
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ تم منح الإذن للإشعارات');
  } else {
    print('❌ لم يتم منح الإذن للإشعارات');
  }

  // Get and save the FCM token
  FirebaseMessaging.instance.getToken().then((token) {
    if (token != null) {
      saveTokenToDatabase(token);
      print("📲 FCM Token: $token");
    }
  });

  // Set up foreground notification handling
  setupFirebaseMessaging();

  runApp(MyApp());
}

/// Save FCM token to Firebase Realtime Database for the logged-in user
Future<void> saveTokenToDatabase(String token) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DatabaseReference ref = FirebaseDatabase.instance.ref("users/${user.uid}");
    
    // Only update the token if it has changed
    DatabaseEvent event = await ref.once();
    Map<dynamic, dynamic>? userData = event.snapshot.value as Map?;
    String? oldToken = userData?['fcm_token'];

    if (oldToken != token) {
      await ref.update({"fcm_token": token});
      print("✅ تم تحديث FCM Token للمستخدم: ${user.uid}, التوكن الجديد: $token");
    } else {
      print("🔄 FCM Token لم يتغير، لا حاجة للتحديث.");
    }
  } else {
    print("❌ لم يتم العثور على مستخدم نشط!");
  }
}

/// Login user and update their FCM token
Future<void> loginUser(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    print("✅ تم تسجيل الدخول بنجاح للمستخدم: ${userCredential.user?.uid}");

    // Update FCM token upon login
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await saveTokenToDatabase(token);
    }
  } catch (e) {
    print("❌ فشل تسجيل الدخول: $e");
  }
}

/// Register a new user and update their FCM token
Future<void> registerUser(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    print("✅ تم تسجيل الحساب بنجاح للمستخدم: ${userCredential.user?.uid}");

    // Update FCM token after account creation
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await saveTokenToDatabase(token);
    }
  } catch (e) {
    print("❌ فشل تسجيل الحساب: $e");
  }
}

/// Logout user and remove their FCM token from database
Future<void> logoutUser() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    DatabaseReference ref = FirebaseDatabase.instance.ref("users/${user.uid}");
    await ref.update({"fcm_token": null});
    print("🚪 تم تسجيل الخروج وحذف FCM Token للمستخدم: ${user.uid}");
  }

  await FirebaseAuth.instance.signOut();
}

/// Set up notification listeners for foreground and opened notifications
void setupFirebaseMessaging() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 إشعار في المقدمة: ${message.notification?.title}");

    // Display local notification in the app
    showLocalNotification(message.notification?.title, message.notification?.body);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("✅ تم فتح التطبيق عبر الإشعار: ${message.notification?.title}");
  });
}


void showLocalNotification(String? title, String? body) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Android notification channel setup
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  var androidDetails = const AndroidNotificationDetails(
    'channel_id', 'القناة الرئيسية',
    importance: Importance.high,
    priority: Priority.high,
  );

  var generalNotificationDetails = NotificationDetails(android: androidDetails);

  // Show the notification
  await flutterLocalNotificationsPlugin.show(
    0, title, body, generalNotificationDetails,
  );
}

// Root of the Flutter application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Realtime Database',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashPage(),
        '/after_splash': (context) => AfterSplashPage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/add_car': (context) => AddCarScreen(),
        '/home': (context) => MainLayout(),
        '/email_verification': (context) => EmailVerificationPage(),
        '/appointments': (context) => AppointmentsPage(),
        '/book_appointment': (context) => BookAppointmentPage(),
      },
    );
  }
}