import 'dart:convert';
import 'dart:html';

class WebUtils {
  static downloadBlobFile({required data, required String filename}) {
    try {
      String filenameLocal =
          filename.replaceAll('/', '_').replaceAll('\\', '_');

      final anchor = AnchorElement(
          href: 'data:application/octet-stream;base64,${base64Encode(data)}')
        ..target = 'blank';

      // add the name
      anchor.download = filenameLocal;

      // trigger download
      document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } catch (_) {}
  }
}
