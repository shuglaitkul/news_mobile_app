import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA1wuGYxL96sFmuIaBAhQs5f1t2B4B00js",
        authDomain: "newsapp-7ebd8.firebaseapp.com",
        projectId: "newsapp-7ebd8",
        storageBucket: "newsapp-7ebd8.appspot.com",
        messagingSenderId: "279629180041",
        appId: "1:279629180041:web:25082b3e7028902ac4ea58",
        measurementId: "G-PV42Y8T88E",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NewsWebView(),
    );
  }
}

class NewsWebView extends StatefulWidget {
  const NewsWebView({super.key});

  @override
  State<NewsWebView> createState() => _NewsWebViewState();
}

class _NewsWebViewState extends State<NewsWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isAuthenticated = false;

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() {
            _isLoading = false;
          }),
          onWebResourceError: (error) => setState(() {
            _hasError = true;
            _isLoading = false;
            print('Error loading: ${error.description}');
          }),
        ),
      );
    _authenticateUser();
  }

  Future<void> _authenticateUser() async {
    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Пожалуйста, пройдите биометрическую аутентификацию',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (didAuthenticate) {
        setState(() {
          _isAuthenticated = true;
          _hasError = false;
          _isLoading = true;
        });

        _controller.loadRequest(
            Uri.parse('https://illustrious-pudding-d99ce5.netlify.app/'));
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новости')),
      body: _isAuthenticated
          ? Stack(
              children: [
                if (_hasError)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Ошибка загрузки. Проверьте интернет.',
                          style: TextStyle(color: Colors.red),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _controller.reload();
                          },
                          child: const Text('Попробовать снова'),
                        ),
                      ],
                    ),
                  )
                else
                  WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            )
          : Center(
              child: _hasError
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Ошибка биометрической аутентификации.',
                          style: TextStyle(color: Colors.red),
                        ),
                        ElevatedButton(
                          onPressed: _authenticateUser,
                          child: const Text('Повторить аутентификацию'),
                        ),
                      ],
                    )
                  : const Text('Ожидание биометрической аутентификации...'),
            ),
    );
  }
}
