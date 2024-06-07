import 'dart:js_interop';
import 'package:web/web.dart';

void downloadBlobFile(String blobUrl,String name){
  Document htmlDocument = document;
  HTMLAnchorElement anchor =
  htmlDocument.createElement('a') as HTMLAnchorElement;
  anchor.href = blobUrl;
  anchor.style.display = name;
  anchor.download = name;
  document.body!.add(anchor);
  anchor.click();
  anchor.remove();
}