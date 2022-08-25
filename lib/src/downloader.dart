import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:path/path.dart' as p;

class DownloadManager {
  final Map<String, DownloadTask> _cache = <String, DownloadTask>{};
  final Queue<DownloadRequest> _queue = Queue();
  var dio = Dio();
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

  void Function(int, int) createCallback(url, int partialFileLength) => (int received, int total) {
        getDownload(url)?.progress.value =
            (received + partialFileLength) / (total + partialFileLength);

        if (total == -1) {}
      };

  Future<void> download(String url, String savePath, cancelToken, {forceDownload = false}) async {
    try {
      var task = getDownload(url);

      if (task == null || task.status.value == DownloadStatus.canceled) {
        return;
      }
      setStatus(task, DownloadStatus.downloading);

      if (kDebugMode) {
        print(url);
      }
      var file = File(savePath.toString());
      var partialFilePath = savePath + partialExtension;
      var partialFile = File(partialFilePath);

      var fileExist = await file.exists();
      var partialFileExist = await partialFile.exists();

      if (fileExist) {
        if (kDebugMode) {
          print("File Exists");
        }
        setStatus(task, DownloadStatus.completed);
      } else if (partialFileExist) {
        if (kDebugMode) {
          print("Partial File Exists");
        }

        var partialFileLength = await partialFile.length();

        var response = await dio.download(url, partialFilePath + tempExtension,
            onReceiveProgress: createCallback(url, partialFileLength),
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

          setStatus(task, DownloadStatus.completed);
        }
      } else {
        var response = await dio.download(url, partialFilePath,
            onReceiveProgress: createCallback(url, 0),
            cancelToken: cancelToken,
            deleteOnError: false);

        if (response.statusCode == HttpStatus.ok) {
          await partialFile.rename(savePath);
          setStatus(task, DownloadStatus.completed);
        }
      }
    } catch (e) {
      var task = getDownload(url)!;
      if (task.status.value != DownloadStatus.canceled &&
          task.status.value != DownloadStatus.paused) {
        task.status.value = DownloadStatus.failed;
        disposeNotifiers(task);
        rethrow;
      }
    }

    runningTasks--;

    if (_queue.isNotEmpty) {
      _startExecution();
    }
  }

  void disposeNotifiers(DownloadTask task) {
    task.status.dispose();
    task.progress.dispose();
  }

  void setStatus(DownloadTask? task, DownloadStatus status) {
    if (task != null) {
      task.status.value = status;

      if (status.isCompleted) {
        disposeNotifiers(task);
      }
    }
  }

  Future<void> addDownload(String url, String savedDir) async {
    if (url.isNotEmpty) {
      if (savedDir.isEmpty) {
        savedDir = ".";
      }
      var hasExtension = p.extension(savedDir, 2).isNotEmpty;

      var downloadFilename = hasExtension ? savedDir : savedDir + "/" + getFileNameFromUrl(url);

      _addDownloadRequest(DownloadRequest(url, downloadFilename));
    }
  }

  Future<void> _addDownloadRequest(DownloadRequest downloadRequest) async {
    _queue.add(DownloadRequest(downloadRequest.url, downloadRequest.path));
    _cache[downloadRequest.url] = DownloadTask(_queue.last);

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
    var task = getDownload(url)!;
    task.status.value = DownloadStatus.downloading;
    _queue.add(task.request);

    _startExecution();
  }

  DownloadTask? getDownload(String url) {
    return _cache[url];
  }

  Future<DownloadStatus> whenDownloadComplete(String url) async {
    var completer = Completer<DownloadStatus>();

    DownloadTask? task = getDownload(url);

    if (task != null) {
      if (task.status.value.isCompleted) {
        completer.complete(task.status.value);
      }

      task.status.addListener(() {
        if (task.status.value.isCompleted) {
          completer.complete(task.status.value);
        }
      });
    } else {
      completer.completeError("Not Found");
    }

    return completer.future;
  }

  List<DownloadTask> getAllDownloads() {
    return _cache.values as List<DownloadTask>;
  }

  // Batch Download Mechanism
  Future<void> addBatchDownloads(List<String> urls, String savedDir) async {
    urls.forEach((url) {
      addDownload(url, savedDir);
    });
  }

  List<DownloadTask?> getBatchDownloads(List<String> urls) {
    return urls.map((e) => _cache[e]).toList();
  }

  Future<void> pauseBatchDownloads(List<String> urls) async {
    urls.forEach((element) {
      pauseDownload(element);
    });
  }

  Future<void> cancelBatchDownloads(List<String> urls) async {
    urls.forEach((element) {
      cancelDownload(element);
    });
  }

  Future<void> resumeBatchDownloads(List<String> urls) async {
    urls.forEach((element) {
      resumeDownload(element);
    });
  }

  ValueNotifier<double> getBatchDownloadProgress(List<String> urls) {
    ValueNotifier<double> progress = ValueNotifier(0);

    var completed = 0;
    var total = urls.length;

    urls.forEach((url) {
      DownloadTask? task = getDownload(url);

      if (task != null) {
        if (task.status.value.isCompleted) {
          completed++;

          progress.value = completed / total;
        }

        task.status.addListener(() {
          if (task.status.value.isCompleted) {
            completed++;

            progress.value = completed / total;
          }
        });
      } else {
        total--;
      }
    });

    return progress;
  }

  Future<List<DownloadTask?>?> whenBatchDownloadsComplete(List<String> urls,
      {Duration timeout = const Duration(hours: 2)}) async {
    var completer = Completer<List<DownloadTask?>?>();

    var completed = 0;
    var total = urls.length;

    urls.forEach((url) {
      DownloadTask? task = getDownload(url);

      if (task != null) {
        if (task.status.value.isCompleted) {
          completed++;

          if (completed == total) {
            completer.complete(getDownloads(urls));
          }
        }

        task.status.addListener(() {
          if (task.status.value.isCompleted) {
            completed++;

            if (completed == total) {
              completer.complete(getDownloads(urls));
            }
          }
        });
      } else {
        total--;
      }
    });

    return completer.future;
  }

  void _startExecution() async {
    if (runningTasks == maxConcurrentTasks || _queue.isEmpty) {
      return;
    }

    while (_queue.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;
      if (kDebugMode) {
        print('Concurrent workers: $runningTasks');
      }
      var currentRequest = _queue.removeFirst();

      download(currentRequest.url, currentRequest.path, currentRequest.cancelToken);

      await Future.delayed(Duration(milliseconds: 500), null);
    }
  }

  /// This function is used for get file name with extension from url
  String getFileNameFromUrl(String url) {
    return url.split('/').last;
  }
}
