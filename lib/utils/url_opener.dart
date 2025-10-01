import 'url_opener_stub.dart'
    if (dart.library.html) 'url_opener_web.dart' as url_opener;

Future<bool> openExternalUrl(String url) => url_opener.openExternalUrl(url);
