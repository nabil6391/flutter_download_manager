import 'package:example/download_blob_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Web Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var url =
      "https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/sample-mp4-file.mp4";

  var downloadManager = DownloadManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter Download Manager")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListItem(
                onDownloadPlayPausedPressed: (url) async {
                  setState(() {
                    var task = downloadManager.getDownload(url);

                    if (task != null && !task.status.value.isCompleted) {
                      switch (task.status.value) {
                        case DownloadStatus.downloading:
                          downloadManager.pauseDownload(url);
                          break;
                        case DownloadStatus.paused:
                          downloadManager.resumeDownload(url);
                          break;
                      }
                    } else {
                      downloadManager.addDownload(url, '');
                    }
                  });
                },
                onDelete: (url) {
                  downloadManager.removeDownload(url);
                  setState(() {});
                },
                url: url,
                downloadTask: downloadManager.getDownload(url)),
          ],
        ),
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  final Function(String) onDownloadPlayPausedPressed;
  final Function(String) onDelete;
  DownloadTask? downloadTask;
  String url = "";

  ListItem(
      {Key? key,
      required this.url,
      required this.onDownloadPlayPausedPressed,
      required this.onDelete,
      this.downloadTask})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Colors.amber,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20))),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      url,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (downloadTask != null)
                      ValueListenableBuilder(
                          valueListenable: downloadTask!.status,
                          builder: (context, value, child) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text("$value",
                                  style: TextStyle(fontSize: 16)),
                            );
                          }),
                  ],
                )),
                downloadTask != null
                    ? ValueListenableBuilder(
                        valueListenable: downloadTask!.status,
                        builder: (context, value, child) {
                          if (downloadTask!.status.value ==
                              DownloadStatus.completed) {

                            downloadBlobFile(downloadTask!.blobUrl!, url.split('/').last);
                          }

                          switch (downloadTask!.status.value) {
                            case DownloadStatus.downloading:
                              return IconButton(
                                  onPressed: () {
                                    onDownloadPlayPausedPressed(url);
                                  },
                                  icon: const Icon(Icons.pause));
                            case DownloadStatus.paused:
                              return IconButton(
                                  onPressed: () {
                                    onDownloadPlayPausedPressed(url);
                                  },
                                  icon: const Icon(Icons.play_arrow));
                            case DownloadStatus.completed:
                              return IconButton(
                                  onPressed: () {
                                    onDelete(url);
                                  },
                                  icon: const Icon(Icons.delete));
                            case DownloadStatus.failed:
                            case DownloadStatus.canceled:
                              return IconButton(
                                  onPressed: () {
                                    onDownloadPlayPausedPressed(url);
                                  },
                                  icon: const Icon(Icons.download));
                          }
                          return Text("$value", style: TextStyle(fontSize: 16));
                        })
                    : IconButton(
                        onPressed: () {
                          onDownloadPlayPausedPressed(url);
                        },
                        icon: const Icon(Icons.download))
              ],
            ), // if (widget.item.isDownloadingOrPaused)
            if (downloadTask != null && !downloadTask!.status.value.isCompleted)
              () {
                try {
                  return ValueListenableBuilder(
                      valueListenable: downloadTask!.progress,
                      builder: (context, value, child) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: LinearProgressIndicator(
                            value: isNan(value) ? 100 : value,
                            color: downloadTask!.status.value ==
                                    DownloadStatus.paused
                                ? Colors.grey
                                : Colors.amber,
                          ),
                        );
                      });
                } catch (e) {
                  print(e);
                  return Container();
                }
              }(),
            if (downloadTask != null)
              FutureBuilder<DownloadStatus>(
                  future: downloadTask!.whenDownloadComplete(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DownloadStatus> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return Text(
                            'I will wait till this download has been completed');
                      default:
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return Text('Result: ${snapshot.data}');
                        }
                    }
                  })
          ],
        ),
      ),
    );
  }
}

// For fix bug NaN in web
bool isNan(double x) => x != x;
