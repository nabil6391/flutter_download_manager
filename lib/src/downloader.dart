import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DownloadManager {
  final Map<String, DownloadTask> _cache = <String, DownloadTask>{};
  final Queue<DownloadRequest> _queue = Queue();
  var dio = Dio();
  var c = Completer();
  static const partialExtension = ".partial";
  static const tempExtension = ".temp";

  int maxConcurrentTasks = 2;
  int runningTasks = 0;

  static final DownloadManager _localRepository = new DownloadManager._internal();

  DownloadManager._internal() {}

  factory DownloadManager({int? maxConcurrentTasks}) {
    if (maxConcurrentTasks != null) {
      _localRepository.maxConcurrentTasks = maxConcurrentTasks;
    }
    return _localRepository;
  }

  void Function(int, int) createCallback(url) => (int received, int total) {
        getDownload(url)?.progress.value = received / total;

        if (total == -1) {}
      };

  Future<void> download(String url, String savePath, cancelToken, {forceDownload = false}) async {
    try {
      print(url);
      var file = File(savePath.toString());
      var partialFilePath = savePath + partialExtension;
      var partialFile = File(partialFilePath);

      var fileExist = await file.exists();
      var partialFileExist = await partialFile.exists();

      if (fileExist) {
        print("File Exists");
        setStatus(url, DownloadStatus.success);
        return;
      } else if (partialFileExist) {
        print("Partial File Exists");
        setStatus(url, DownloadStatus.downloading);

        var partialFileLength = await partialFile.length();

        var response = await dio.download(url, partialFilePath + tempExtension,
            onReceiveProgress: createCallback(url),
            options: Options(
              headers: {HttpHeaders.rangeHeader: 'bytes=$partialFileLength-'},
            ),
            cancelToken: cancelToken,
            deleteOnError: true);

        if (response.statusCode == HttpStatus.partialContent) {
          var ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          var _f = File(partialFilePath + tempExtension);
          await ioSink.addStream(_f.openRead());
          await _f.delete();
          await ioSink.close();
          await partialFile.rename(savePath);

          setStatus(url, DownloadStatus.success);
        }
      } else {
        setStatus(url, DownloadStatus.downloading);

        var response = await dio.download(url, partialFilePath,
            onReceiveProgress: createCallback(url), cancelToken: cancelToken, deleteOnError: false);

        if (response.statusCode == HttpStatus.ok) {
          await partialFile.rename(savePath);
          setStatus(url, DownloadStatus.success);
        }
      }
    } catch (e) {
      print(e);

      var task = getDownload(url)!;
      if (task.status.value != DownloadStatus.canceled &&
          task.status.value != DownloadStatus.paused) {
        task.status.value = DownloadStatus.failed;
      }
    }

    runningTasks--;

    if (_queue.isEmpty) {
      c.complete("complete");
    } else {
      _startExecution();
    }
  }

  void setStatus(String url, status) {
    getDownload(url)?.status?.value = status;
  }

  Future<void> addDownload(String url, String savedDir) async {
    if (_queue.isEmpty) {
      c = Completer();
    }
    _queue.add(DownloadRequest(url, savedDir));
    _cache[url] = DownloadTask(_queue.last);

    _startExecution();
  }

  Future<void> pauseDownload(String url) async {
    var task = getDownload(url)!;
    task.status.value = DownloadStatus.paused;
    task.request.cancelToken.cancel();

    _queue.remove(task.request);
  }

  Future<void> cancelDownload(String url) async {
    var task = getDownload(url)!;
    task.status.value = DownloadStatus.canceled;
    _queue.remove(task.request);
    task.request.cancelToken.cancel();
  }

  Future<void> resumeDownload(String url) async {
    if (_queue.isEmpty) {
      c = Completer();
    }
    var task = getDownload(url)!;
    task.status.value = DownloadStatus.downloading;
    _queue.add(task.request);

    _startExecution();
  }

  DownloadTask? getDownload(String url) {
    return _cache[url];
  }

  List<DownloadTask> getAllDownloads() {
    return _cache.values as List<DownloadTask>;
  }

  void _startExecution() async {
    if (runningTasks == maxConcurrentTasks || _queue.isEmpty) {
      return;
    }

    while (_queue.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;
      print('Concurrent workers: $runningTasks');

      var currentRequest = _queue.removeFirst();
      download(currentRequest.name, currentRequest.path, currentRequest.cancelToken);

      await Future.delayed(Duration(milliseconds: 500), null);
    }
  }
}

class DownloadRequest {
  final String name;
  final String path;
  var cancelToken = CancelToken();
  var forceDownload = false;

  DownloadRequest(
    this.name,
    this.path,
  );
}

class DownloadTask {
  final DownloadRequest request;
  ValueNotifier<DownloadStatus> status = ValueNotifier(DownloadStatus.queued);
  ValueNotifier<double> progress = ValueNotifier(0);

  DownloadTask(
    this.request,
  );
}

enum DownloadStatus { queued, downloading, success, failed, paused, canceled }
