import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// B站视频播放器组件
/// 使用 WebView 加载 B站官方 iframe 嵌入页面
class BilibiliPlayer extends StatefulWidget {
  /// B站视频BV号，如：BV1xx411c7XD
  final String bvid;

  /// 视频标题（用于显示）
  final String? title;

  const BilibiliPlayer({
    super.key,
    required this.bvid,
    this.title,
  });

  @override
  State<BilibiliPlayer> createState() => _BilibiliPlayerState();
}

class _BilibiliPlayerState extends State<BilibiliPlayer> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('B站播放器开始加载: $url');
          },
          onPageFinished: (String url) {
            debugPrint('B站播放器加载完成: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('B站播放器错误: ${error.description}');
          },
        ),
      );

    // B站官方iframe嵌入地址
    final url = 'https://player.bilibili.com/player.html?bvid=${widget.bvid}&page=1&autoplay=0';
    debugPrint('B站播放器URL: $url');

    _controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: WebViewWidget(controller: _controller),
    );
  }
}
