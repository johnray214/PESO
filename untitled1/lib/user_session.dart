/// Singleton that holds the currently authenticated user's data.
/// Populated on login/register, cleared on sign-out.
class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? token;
  int? userId;
  String? firstName;
  String? middleInitial;
  String? lastName;
  String? name;
  String? email;
  String? gender;
  int? age;
  String? phone;
  String? address;
  String? provinceCode;
  String? provinceName;
  String? cityCode;
  String? cityName;
  String? barangayCode;
  String? barangayName;
  String? streetAddress;
  List<String> skills = [];
  String? avatarPath;
  String? educationLevel;
  String? jobExperience;
  String? dateOfBirth; // 'YYYY-MM-DD'
  bool isOnboardingDone = false;

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
  /// Accepts either:
  /// - { "user": {...}, "token": "..." }
  /// - { "jobseeker": {...}, "token": "..." }
  void setFromApiData(Map<String, dynamic> data) {
    final user = (data['user'] as Map<String, dynamic>?) ??
        (data['jobseeker'] as Map<String, dynamic>?) ??
        {};
    token = data['token'] as String? ?? '';
    _applyUserFields(user);
  }

  /// Update only the user fields (used after profile edit, where token stays the same).
  void updateFromUser(Map<String, dynamic> user) => _applyUserFields(user);

  void _applyUserFields(Map<String, dynamic> user) {
    userId = user['id'] as int?;
    firstName = (user['first_name'] as String?)?.trim();
    middleInitial = (user['middle_initial'] as String?)?.trim();
    lastName = (user['last_name'] as String?)?.trim();
    final directName = user['name'] as String?;
    if (directName != null && directName.trim().isNotEmpty) {
      name = directName;
    } else {
      final combined = [firstName, lastName]
          .where((p) => p != null && p.isNotEmpty)
          .cast<String>()
          .join(' ');
      name = combined.isNotEmpty ? combined : null;
    }
    email = user['email'] as String?;
    gender = (user['gender'] as String?) ?? (user['sex'] as String?);
    age = user['age'] as int?;
    phone = (user['phone'] as String?) ?? (user['contact'] as String?);
    address = user['address'] as String?;
    provinceCode = (user['province_code'] as String?)?.trim();
    provinceName = (user['province_name'] as String?)?.trim();
    cityCode = (user['city_code'] as String?)?.trim();
    cityName = (user['city_name'] as String?)?.trim();
    barangayCode = (user['barangay_code'] as String?)?.trim();
    barangayName = (user['barangay_name'] as String?)?.trim();
    streetAddress = (user['street_address'] as String?)?.trim();
    avatarPath = user['avatar_path'] as String?;
    educationLevel = (user['education_level'] as String?)?.trim();
    jobExperience = (user['job_experience'] as String?)?.trim();
    final dob = (user['date_of_birth'] as String?)?.trim();
    if (dob != null && dob.isNotEmpty) {
      // Split by 'T' or space to discard time components immediately
      dateOfBirth = dob.split(RegExp(r'[T\s]'))[0];
    } else {
      dateOfBirth = null;
    }
    final rawOnboarding = user['is_onboarding_done'];
    if (rawOnboarding is bool) {
      isOnboardingDone = rawOnboarding;
    } else if (rawOnboarding is int) {
      isOnboardingDone = (rawOnboarding == 1);
    }
    final rawSkills = user['skills'];
    if (rawSkills is List) {
      skills = rawSkills.map((e) {
        // Depending on the backend endpoint, `skills` might come as:
        // 1) List<String>
        // 2) List<{ skill: "..." , ... }>
        if (e is Map<String, dynamic>) {
          final s = e['skill'];
          if (s != null) return s.toString();
        }
        return e.toString();
      }).toList();
    } else {
      skills = [];
    }
  }

  void clear() {
    token = null;
    userId = null;
    firstName = null;
    middleInitial = null;
    lastName = null;
    name = null;
    email = null;
    gender = null;
    age = null;
    phone = null;
    address = null;
    provinceCode = null;
    provinceName = null;
    cityCode = null;
    cityName = null;
    barangayCode = null;
    barangayName = null;
    streetAddress = null;
    avatarPath = null;
    skills = [];
    educationLevel = null;
    jobExperience = null;
    dateOfBirth = null;
    isOnboardingDone = false;
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
  if (hour >= 5 && hour < 12) return 'Good Morning';
  if (hour >= 12 && hour < 18) return 'Good Afternoon';
  return 'Good Evening';
}
      