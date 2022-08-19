import 'package:dio/dio.dart';

class DownloadRequest {
  final String url;
  final String path;
  var cancelToken = CancelToken();
  var forceDownload = false;

  DownloadRequest(
    this.url,
    this.path,
  );
}
