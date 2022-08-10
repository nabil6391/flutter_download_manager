GraphView
===========

[![pub package](https://img.shields.io/pub/v/graphview.svg)](https://pub.dev/packages/graphview)
[![pub points](https://badges.bar/graphview/pub%20points)](https://pub.dev/packages/graphview/score)
[![popularity](https://badges.bar/graphview/popularity)](https://pub.dev/packages/graphview/score)
[![likes](https://badges.bar/graphview/likes)](https://pub.dev/packages/graphview/score) |


Overview
========
The library is designed to support different graph layouts and currently works excellent with small graphs.

You can have a look at the flutter web implementation here:
http://graphview.surge.sh/


A package for automatically downloading and storing files

## Getting Started


### Creating a DownloadableFile

The first step is to create a downloadable file. The simplest way to do this is using a SimpleDownloadableFile

E.g. you can create one with a function (returning something can be written to file)

```
  File testFile = File("test_file.txt");
  var downloadFile = DownloadableFileBasic(() => "Test string", testFile);
```

You can also, optionally, set an expiry date time to your DownloadableFileBasic class. The purpose of this is
to have a file which is only downloaded if the expiry date on the file is newer than the one you've already downloaded

### Downloading a file

Insert your downloadable file into the DownloadManager

```
DownloadManager.instance().add(DownloadableFileBasic(() => "Test string", testBFile));

```
Results in the stream

```
expectLater(DownloadManager.instance().fileStream, emits(testBFile));
```

### Get notifications

There are two streams (more in development) that you can subscribe to.

The first will return a stream which has files in fired one at a time as they are downloaded.

```
DownloadManager.instance().fileStream
```

The second will return a list of all files downloaded. Note: files that are already downloaded will also be
added to this list

```
DownloadManager.instance().allFiles
```

You can also clear all files. You will be notified via allFiles stream with a new empty list that this has happened

```
DownloadManager.instance().clear();
```