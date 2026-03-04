/// Singleton that holds the currently authenticated user's data.
/// Populated on login/register, cleared on sign-out.
class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? token;
  int? userId;
  String? name;
  String? email;
  String? gender;
  int? age;
  String? phone;
  String? address;
  List<String> skills = [];

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  /// Two-letter initials from the user's name (e.g. "Juan Dela Cruz" → "JD")
  String get initials {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  /// Display name, falls back to email prefix when name is blank.
  String get displayName {
    final n = name?.trim() ?? '';
    if (n.isNotEmpty) return n;
    return email?.split('@').first ?? 'User';
  }

  /// Populate session from the API login/register `data` block.
  /// Expects: { "user": {...}, "token": "..." }
  void setFromApiData(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>? ?? {};
    token = data['token'] as String? ?? '';
    _applyUserFields(user);
  }

  /// Update only the user fields (used after profile edit, where token stays the same).
  void updateFromUser(Map<String, dynamic> user) => _applyUserFields(user);

  void _applyUserFields(Map<String, dynamic> user) {
    userId = user['id'] as int?;
    name = user['name'] as String?;
    email = user['email'] as String?;
    gender = user['gender'] as String?;
    age = user['age'] as int?;
    phone = user['phone'] as String?;
    address = user['address'] as String?;
    final rawSkills = user['skills'];
    if (rawSkills is List) {
      skills = rawSkills.map((e) => e.toString()).toList();
    } else {
      skills = [];
    }
  }

  void clear() {
    token = null;
    userId = null;
    name = null;
    email = null;
    gender = null;
    age = null;
    phone = null;
    address = null;
    skills = [];
  }
}

/// Current time in the Philippines (PHT / UTC+8), independent of device timezone.
DateTime nowInPhilippines() {
  final utcNow = DateTime.now().toUtc();
  return utcNow.add(const Duration(hours: 8));
}

/// Greeting string based on Philippines time.
///
/// Morning: 5:00–11:59
/// Afternoon: 12:00–17:59
/// Evening: 18:00–4:59
String getPhilippinesGreeting() {
  final hour = nowInPhilippines().hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 18) return 'Good afternoon';
  return 'Good evening';
}
      