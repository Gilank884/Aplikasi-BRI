import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  // Link Fotoshare
  final String fotoshareUrl = 'https://fotoshare.co/e/2nxyV8Ns_YZwUXRfCRnZ2';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 100,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reports Page Not Available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This page is under construction.\nYou can check booth photos below!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF0D1B2A),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  // Navigate to WebView page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FotoshareWebView(url: fotoshareUrl),
                    ),
                  );
                },
                child: const Text(
                  'View Booth Photos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF0D1B2A),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Go Back',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Halaman WebView untuk menampilkan fotoshare
class FotoshareWebView extends StatefulWidget {
  final String url;
  const FotoshareWebView({super.key, required this.url});

  @override
  State<FotoshareWebView> createState() => _FotoshareWebViewState();
}

class _FotoshareWebViewState extends State<FotoshareWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booth Photos'),
        backgroundColor: const Color(0xFF0D1B2A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // kembali ke ReportsScreen
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D1B2A),
        child: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context); // tombol tambahan untuk kembali
        },
      ),
    );
  }
}
