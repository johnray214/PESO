import 'user_session.dart';

/// Shared skill/company matching helpers with lightweight caching.
class SkillMatchUtils {
  static final RegExp _splitPattern = RegExp(r'[,/;|]');
  static final RegExp _spacesPattern = RegExp(r'\s+');
  static final RegExp _nonAlnumSpacePattern = RegExp(r'[^a-z0-9 ]');

  static String? _cachedUserSkillsKey;
  static Set<String> _cachedUserSkills = <String>{};

  static String normalizeCompanyName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(_nonAlnumSpacePattern, '')
        .replaceAll(_spacesPattern, ' ');
  }

  static String normalizeTerm(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(_spacesPattern, ' ')
        .replaceAll(_nonAlnumSpacePattern, '')
        .trim();
  }

  static Set<String> normalizeSkillTerms(Iterable<String> values) {
    final out = <String>{};
    for (final raw in values) {
      final source = raw.trim().toLowerCase();
      if (source.isEmpty) continue;
      for (final part in source.split(_splitPattern)) {
        final normalized = normalizeTerm(part);
        if (normalized.isNotEmpty) out.add(normalized);
      }
    }
    return out;
  }

  static Set<String> normalizedUserSkillsFromSession() {
    final raw = UserSession()
        .skills
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    final key = raw.join('|');
    if (_cachedUserSkillsKey == key) return _cachedUserSkills;
    _cachedUserSkillsKey = key;
    _cachedUserSkills = normalizeSkillTerms(raw);
    return _cachedUserSkills;
  }

  /// Call after sign-out, profile refresh, or any change to [UserSession.skills].
  static void invalidateUserSkillsCache() {
    _cachedUserSkillsKey = null;
    _cachedUserSkills = <String>{};
  }

  static bool termsLookMatched(String userSkill, String jobSkill) {
    if (userSkill == jobSkill) return true;
    if (userSkill.length >= 4 && jobSkill.contains(userSkill)) return true;
    if (jobSkill.length >= 4 && userSkill.contains(jobSkill)) return true;
    return false;
  }

  static bool anySkillMatch({
    required Set<String> normalizedUserSkills,
    required Iterable<String> jobSkillsRaw,
  }) {
    if (normalizedUserSkills.isEmpty) return false;
    final jobSkills = normalizeSkillTerms(jobSkillsRaw);
    if (jobSkills.isEmpty) return false;
    for (final userSkill in normalizedUserSkills) {
      for (final jobSkill in jobSkills) {
        if (termsLookMatched(userSkill, jobSkill)) return true;
      }
    }
    return false;
  }

  static bool matchesSingleSkillLabel({
    required Set<String> normalizedUserSkills,
    required String jobSkill,
  }) {
    final normalizedJobSkill = normalizeTerm(jobSkill);
    if (normalizedJobSkill.isEmpty) return false;
    for (final userSkill in normalizedUserSkills) {
      if (termsLookMatched(userSkill, normalizedJobSkill)) return true;
    }
    return false;
  }
}
