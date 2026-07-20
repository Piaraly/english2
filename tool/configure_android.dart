import 'dart:io';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('AndroidManifest.xml not found. Run flutter create first.');
    exit(1);
  }
  var text = manifest.readAsStringSync();
  const permissions = '''
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
''';
  if (!text.contains('android.permission.RECORD_AUDIO')) {
    text = text.replaceFirst('<manifest xmlns:android="http://schemas.android.com/apk/res/android">', '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n$permissions');
  }
  text = text.replaceFirst('<application', '<application android:enableOnBackInvokedCallback="true"');
  manifest.writeAsStringSync(text);

  final gradle = File('android/app/build.gradle.kts');
  if (gradle.existsSync()) {
    var g = gradle.readAsStringSync();
    g = g.replaceFirst('minSdk = flutter.minSdkVersion', 'minSdk = 24');
    gradle.writeAsStringSync(g);
  }
}
