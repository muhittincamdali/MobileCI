/// A Flutter app version as written in `pubspec.yaml`: `1.4.0+27`.
///
/// `mobileci version bump patch --build` rewrites that line; this class reads it back the way
/// Flutter does (the part after `+` becomes the iOS build number and the Android version code).
class ReleaseVersion {
  const ReleaseVersion(this.name, this.build);

  /// The largest Android version code Google Play accepts.
  static const int maximumBuild = 2100000000;

  final String name;
  final int? build;

  /// Returns `null` for anything that is not `x.y.z` with an optional `+build`.
  static ReleaseVersion? tryParse(String text) {
    final parts = text.trim().split('+');
    if (parts.length > 2) return null;
    final name = parts.first;
    final numbers = name.split('.');
    if (numbers.length != 3 || numbers.any((part) => !_isNumber(part))) {
      return null;
    }
    if (parts.length == 1) return ReleaseVersion(name, null);
    final buildText = parts[1];
    if (!_isNumber(buildText) || buildText.length > 10) return null;
    final build = int.parse(buildText);
    if (build > maximumBuild) return null;
    return ReleaseVersion(name, build);
  }

  static bool _isNumber(String text) =>
      text.isNotEmpty && text.codeUnits.every((unit) => unit >= 48 && unit <= 57);

  /// `Version 1.4.0 (27)`, or `Version 1.4.0` without a build number.
  String get label => build == null ? 'Version $name' : 'Version $name ($build)';
}
