import 'package:universal_html/html.dart';

class WebUtils {
  static String getBlobUrl({required data}) {
    return Url.createObjectUrlFromBlob(Blob([data]));
  }
}
