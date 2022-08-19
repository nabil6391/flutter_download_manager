import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var url2 = "http://download.dcloud.net.cn/HBuilder.9.0.2.macosx_64.dmg";

  var url3 = 'https://cdn.jsdelivr.net/gh/flutterchina/flutter-in-action@1.0/docs/imgs/book.jpg';
  var url = "http://app01.78x56.com/Xii_2021-03-13%2010%EF%BC%9A41.ipa";
  var url4 = "https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/sample-mp4-file.mp4";
  var url5 =
      "https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-Video-File-For-Testing.mp4";
  var url6 = "https://static.gtaf.org/v1/quran/static/translation-db/10";

  test('future download', () async {
    var dl = DownloadManager();

    dl.addDownload(url4, "./test.mp4");

    DownloadTask? task = dl.getDownload(url4);

    task?.status.addListener(() {
      print(task.status.value);
    });

    task?.progress.addListener(() {
      print(task.progress.value);
    });

    await dl.whenComplete(url4);
  });

  test('parallel download', () async {
    var dl = DownloadManager();

    dl.addDownload(url2, "./test2.ipa");
    dl.addDownload(url3, "./test3.ipa");
    dl.addDownload(url, "./test.ipa");

    DownloadTask? task = dl.getDownload(url);

    task?.status.addListener(() {
      print(task.status.value);
    });

    DownloadTask? task2 = dl.getDownload(url2);

    task2?.status.addListener(() {
      print(task2.status.value);
    });

    DownloadTask? task3 = dl.getDownload(url3);

    task3?.status.addListener(() {
      print(task3.status.value);
    });

    await dl.whenCompletes([url, url2, url3]);
  });

  test('cancel download', () async {
    var dl = DownloadManager();

    dl.addDownload(url5, "./test2.mp4");

    DownloadTask? task = dl.getDownload(url5);

    Future.delayed(Duration(milliseconds: 500), () {
      dl.cancelDownload(url5);
    });

    task?.status.addListener(() {
      print(task.status.value);
    });

    await Future.delayed(Duration(seconds: 10), null);
  });

  test('pause and resume download', () async {
    var dl = DownloadManager();

    dl.addDownload(url5, "./test2.mp4");

    DownloadTask? task = dl.getDownload(url5);

    Future.delayed(Duration(milliseconds: 500), () {
      dl.pauseDownload(url5);
    });

    Future.delayed(Duration(milliseconds: 1000), () {
      dl.resumeDownload(url5);
    });

    task?.status.addListener(() {
      print(task.status.value);
    });

    await Future.delayed(Duration(seconds: 20), null);
  });

  test('handle empty url', () async {
    var dl = DownloadManager();

    dl.addDownload("", "");

    DownloadTask? task = dl.getDownload("");

    task?.status.addListener(() {
      print(task.status.value);
    });

    await dl.whenComplete("");
  });

  test('handle empty path', () async {
    var dl = DownloadManager();

    dl.addDownload(url3, "");

    DownloadTask? task = dl.getDownload(url3);

    task?.status.addListener(() {
      print(task.status.value);
    });

    await dl.whenComplete(url3);
  });

  test('handle url with empty extension', () async {
    var dl = DownloadManager();

    dl.addDownload(url6, "");

    DownloadTask? task = dl.getDownload(url6);

    task?.status.addListener(() {
      print(task.status.value);
    });

    await dl.whenComplete(url6);
  });

  test('download in batch', () async {
    var dl = DownloadManager();

    var urls = <String>[];
    urls.add(url2);
    urls.add(url3);
    urls.add(url);

    dl.addDownload(url2, "./test2.ipa");
    dl.addDownload(url3, "./test3.ipa");
    dl.addDownload(url, "./test.ipa");

    var downloadProgress = dl.getDownloadProgress(urls);

    downloadProgress.addListener(() {
      print(downloadProgress.value);
    });

    await dl.whenCompletes(urls);
  });

  test('cancel a batched download', () async {
    var dl = DownloadManager();

    var urls = <String>[];
    urls.add(url6);
    urls.add(url5);
    urls.add(url);
    dl.addDownloads(urls, ".");

    var downloads = dl.getDownloads(urls);

    downloads.forEach((task) {
      task?.status.addListener(() {
        print(task.request.url + ", " + task.status.value.toString());
      });
    });

    dl.cancelDownloads(urls);

    await dl.whenCompletes(urls);
  });

  test('cancel a single item in a batched download', () async {
    var dl = DownloadManager();

    var urls = <String>[];
    urls.add(url4);
    urls.add(url3);
    urls.add(url);
    dl.addDownloads(urls, "");

    var downloads = dl.getDownloads(urls);

    downloads.forEach((task) {
      task?.status.addListener(() {
        print(task.status.value);
      });
    });

    dl.cancelDownload(url3);

    await dl.whenCompletes(urls);
  });
}
