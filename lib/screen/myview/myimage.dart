import 'package:flutter/material.dart';

class MyImage {
  static Image network({@required String url, @required BuildContext context}) {
    return Image.network(
      url,
      loadingBuilder:
          (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
        if (loadingProgress == null) return child;
        return CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes
                : null);
      },
    );
  }
}
