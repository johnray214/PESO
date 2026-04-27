<?php

namespace App\Http\Controllers\Api\Jobseeker;

use App\Http\Controllers\Controller;
use App\Models\JobseekerSkill;
use App\Support\JobseekerPassword;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;

class JobseekerProfileController extends Controller
{
    private const EMAIL_CHANGE_OTP_TTL_MINUTES = 15;
    private const EMAIL_CHANGE_OTP_RESEND_COOLDOWN_SECONDS = 60;
    private const EMAIL_CHANGE_OTP_DAILY_LIMIT = 7;

    public function show(Request $request)
    {
        $jobseeker = $request->user()->load('skills');
        
        return response()->json([
            'success' => true,
            'data' => $jobseeker,
        ]);
    }

    public function update(Request $request)
    {
        $jobseeker = $request->user();
        
        $validated = $request->validate([
            'first_name' => 'sometimes|string|max:100',
            'middle_initial' => 'sometimes|nullable|string|max:5',
            'last_name' => 'sometimes|string|max:100',
            'contact' => 'sometimes|nullable|string|max:20',
            'address' => 'sometimes|nullable|string|max:500',
            'email' => 'sometimes|email|unique:jobseekers,email,' . $jobseeker->id,
            'sex' => 'sometimes|in:male,female',
            'date_of_birth' => 'sometimes|date',
            'bio' => 'nullable|string',
            'education_level' => 'sometimes|nullable|string|max:120|in:No Formal Education,Elementary Level,Elementary Graduate,Secondary Level,Secondary Graduate,Tertiary Level,Tertiary Graduate',
            'job_experience' => 'sometimes|nullable|string|max:1000',
            'province_code' => 'sometimes|nullable|string|max:20',
            'province_name' => 'sometimes|nullable|string|max:120',
            'city_code' => 'sometimes|nullable|string|max:20',
            'city_name' => 'sometimes|nullable|string|max:120',
            'barangay_code' => 'sometimes|nullable|string|max:20',
            'barangay_name' => 'sometimes|nullable|string|max:120',
            'street_address' => 'sometimes|nullable|string|max:255',
            'longitude' => 'nullable|numeric',
            'is_onboarding_done' => 'sometimes|boolean',
            'skills' => 'nullable|array',
            'skills.*' => 'string|max:100',
        ]);

        DB::beginTransaction();
        try {
            $skills = $validated['skills'] ?? null;
            unset($validated['skills']);

            if (!array_key_exists('address', $validated)) {
                $parts = [
                    $validated['street_address'] ?? $jobseeker->street_address,
                    $validated['barangay_name'] ?? $jobseeker->barangay_name,
                    $validated['city_name'] ?? $jobseeker->city_name,
                    $validated['province_name'] ?? $jobseeker->province_name,
                ];
                $parts = array_values(array_filter(array_map(
                    fn ($p) => is_string($p) ? trim($p) : '',
                    $parts
                )));
                if (!empty($parts)) {
                    $validated['address'] = implode(', ', $parts);
                }
            }
            
            $jobseeker->update($validated);
            
            if ($skills !== null) {
                $jobseeker->skills()->delete();
                foreach ($skills as $skill) {
                    JobseekerSkill::create([
                        'jobseeker_id' => $jobseeker->id,
                        'skill' => $skill,
                    ]);
                }
            }
            
            DB::commit();

            if ($skills !== null && !empty($skills)) {
                $jobseeker->load('skills');
                $openJobs = \App\Models\JobListing::where('status', 'Open')->with('skills')->get();
                foreach ($openJobs as $job) {
                    /** @var \App\Models\JobListing $job */
                    $score = \App\Models\Application::calculateMatchScore($jobseeker, $job);
                    if ($score >= 70) {
                        $exists = \App\Models\Notification::where('type', 'match')
                            ->where('created_by', $jobseeker->id)
                            ->where('job_listing_id', $job->id)
                            ->exists();
                            
                        if (!$exists) {
                            $employerNotification = \App\Models\Notification::create([
                                'subject'        => 'New Potential Applicant Match',
                                'message'        => "{$jobseeker->full_name} is a high match ({$score}%) for your {$job->title} position.",
                                'type'           => 'match',
                                'job_listing_id' => $job->id,
                                'recipients'     => 'specific',
                                'scheduled_at'   => null,
                                'sent_at'        => now(),
                                'status'         => 'sent',
                                'created_by'     => null,
                            ]);
                    
                            \App\Models\NotificationRead::create([
                                'notification_id' => $employerNotification->id,
                                'recipient_type'  => 'employer',
                                'recipient_id'    => $job->employer_id,
                                'read_at'         => null,
                            ]);
                        }
                    }
                }
            }

            return response()->json([
                'success' => true,
                'data' => $jobseeker->load('skills'),
                'message' => 'Profile updated successfully',
            ]);
        } catch (\Exception $e) {
            DB::rollback();
            throw $e;
        }
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'password' => JobseekerPassword::createRules(),
        ]);

        $jobseeker = $request->user();

        if (!\Illuminate\Support\Facades\Hash::check($request->current_password, $jobseeker->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Current password is incorrect',
            ], 422);
        }

        $jobseeker->update(['password' => \Illuminate\Support\Facades\Hash::make($request->password)]);

        return response()->json([
            'success' => true,
            'message' => 'Password changed successfully',
        ]);
    }

    public function requestEmailChangeOtp(Request $request)
    {
        $jobseeker = $request->user();
        $validated = $request->validate([
            'new_email' => 'required|email|max:191|unique:jobseekers,email,' . $jobseeker->id,
        ]);

        $newEmail = strtolower(trim((string) $validated['new_email']));
        if (strtolower((string) $jobseeker->email) === $newEmail) {
            return response()->json([
                'success' => false,
                'message' => 'New email must be different from your current email.',
            ], 422);
        }

        $now = Carbon::now();
        $this->refreshOtpDailyCounterWindow($jobseeker, $now);

        if ((int) $jobseeker->otp_send_count_today >= self::EMAIL_CHANGE_OTP_DAILY_LIMIT) {
            return response()->json([
                'success' => false,
                'message' => 'Daily OTP limit reached (7/day). Please try again tomorrow.',
                'retry_after_seconds' => $this->secondsUntilNextDay($now),
                'remaining_daily_sends' => 0,
            ], 429);
        }

        if (
            $jobseeker->otp_resend_cooldown_until &&
            $now->lt($jobseeker->otp_resend_cooldown_until)
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Please wait before requesting another OTP.',
                'retry_after_seconds' => $now->diffInSeconds($jobseeker->otp_resend_cooldown_until),
                'remaining_daily_sends' => max(0, self::EMAIL_CHANGE_OTP_DAILY_LIMIT - (int) $jobseeker->otp_send_count_today),
            ], 429);
        }

        $otpCode = $this->generateOtp();
        if (!$this->sendEmailChangeOtpEmail($jobseeker, $newEmail, $otpCode)) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to send OTP email. Please try again shortly.',
                'remaining_daily_sends' => max(0, self::EMAIL_CHANGE_OTP_DAILY_LIMIT - (int) $jobseeker->otp_send_count_today),
            ], 500);
        }

        $jobseeker->otp_code = $otpCode;
        $jobseeker->otp_expires_at = Carbon::now()->addMinutes(self::EMAIL_CHANGE_OTP_TTL_MINUTES);
        $jobseeker->otp_send_count_today = (int) $jobseeker->otp_send_count_today + 1;
        $jobseeker->otp_resend_count = (int) $jobseeker->otp_resend_count + 1;
        $jobseeker->otp_resend_cooldown_until = Carbon::now()->addSeconds(self::EMAIL_CHANGE_OTP_RESEND_COOLDOWN_SECONDS);
        $jobseeker->setAttribute('otp_send_count_date', $now->toDateString());
        $jobseeker->save();

        return response()->json([
            'success' => true,
            'message' => 'OTP sent to your new email address.',
            'cooldown_seconds' => self::EMAIL_CHANGE_OTP_RESEND_COOLDOWN_SECONDS,
            'remaining_daily_sends' => max(0, self::EMAIL_CHANGE_OTP_DAILY_LIMIT - (int) $jobseeker->otp_send_count_today),
        ]);
    }

    public function confirmEmailChangeOtp(Request $request)
    {
        $jobseeker = $request->user();
        $validated = $request->validate([
            'new_email' => 'required|email|max:191|unique:jobseekers,email,' . $jobseeker->id,
            'otp_code' => 'required|string|size:6',
        ]);

        $newEmail = strtolower(trim((string) $validated['new_email']));
        if (strtolower((string) $jobseeker->email) === $newEmail) {
            return response()->json([
                'success' => false,
                'message' => 'New email must be different from your current email.',
            ], 422);
        }

        if (!$jobseeker->otp_code || $jobseeker->otp_code !== $validated['otp_code']) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid verification code',
            ], 400);
        }

        if (!$jobseeker->otp_expires_at || now()->greaterThan($jobseeker->otp_expires_at)) {
            return response()->json([
                'success' => false,
                'message' => 'Verification code has expired',
            ], 400);
        }

        $jobseeker->email = $newEmail;
        $jobseeker->email_verified_at = now();
        $jobseeker->otp_code = null;
        $jobseeker->otp_expires_at = null;
        $jobseeker->otp_resend_count = 0;
        $jobseeker->otp_resend_cooldown_until = null;
        $jobseeker->save();

        return response()->json([
            'success' => true,
            'data' => $jobseeker->fresh()->load('skills'),
            'message' => 'Email updated successfully',
        ]);
    }

    public function uploadResume(Request $request)
    {
        $request->validate([
            'resume' => 'required|file|mimes:pdf|max:5120',
        ]);

        $jobseeker = $request->user();

        if ($jobseeker->resume_path) {
            Storage::disk('public')->delete($jobseeker->resume_path);
        }

        $path = $request->file('resume')->store(
            "resumes/{$jobseeker->id}",
            'public'
        );

        $jobseeker->update(['resume_path' => $path]);

        return response()->json([
            'success' => true,
            'data' => [
                'resume_path' => $path,
            ],
            'message' => 'Resume uploaded successfully',
        ]);
    }

    public function uploadCertificate(Request $request)
    {
        $request->validate([
            'certificate' => 'required|file|mimes:pdf|max:5120',
        ]);

        $jobseeker = $request->user();

        if ($jobseeker->certificate_path) {
            Storage::disk('public')->delete($jobseeker->certificate_path);
        }

        $path = $request->file('certificate')->store(
            "certificates/{$jobseeker->id}",
            'public'
        );

        $jobseeker->update(['certificate_path' => $path]);

        return response()->json([
            'success' => true,
            'data' => [
                'certificate_path' => $path,
            ],
            'message' => 'Certificate uploaded successfully',
        ]);
    }

    public function uploadBarangayClearance(Request $request)
    {
        $request->validate([
            'barangay_clearance' => 'required|file|mimes:pdf|max:5120',
        ]);

        $jobseeker = $request->user();

        if ($jobseeker->barangay_clearance_path) {
            Storage::disk('public')->delete($jobseeker->barangay_clearance_path);
        }

        $path = $request->file('barangay_clearance')->store(
            "barangay_clearances/{$jobseeker->id}",
            'public'
        );

        $jobseeker->update(['barangay_clearance_path' => $path]);

        return response()->json([
            'success' => true,
            'data' => [
                'barangay_clearance_path' => $path,
            ],
            'message' => 'Barangay clearance uploaded successfully',
        ]);
    }

    public function uploadAvatar(Request $request)
    {
        $request->validate([
            'avatar' => 'required|image|max:3072', // 3MB
        ]);

        $jobseeker = $request->user();

        $path = $request->file('avatar')->store(
            "avatars/jobseekers/{$jobseeker->id}",
            'public'
        );

        $jobseeker->update(['avatar_path' => $path]);

        return response()->json([
            'success' => true,
            'data' => [
                'avatar_path' => $path,
            ],
            'message' => 'Avatar uploaded successfully',
        ]);
    }

    public function avatar(Request $request)
    {
        $jobseeker = $request->user();
        $path = $jobseeker->avatar_path;

        if (!$path) {
            return response()->noContent();
        }

        if (!Storage::disk('public')->exists($path)) {
            return response()->noContent();
        }

        return Storage::disk('public')->response($path);
    }

    /**
     * View own document (PDF) with auth — avoids public /storage 403 issues.
     *
     * @param  string  $type  resume|certificate|clearance
     */
    public function downloadDocument(Request $request, string $type)
    {
        $column = match ($type) {
            'resume' => 'resume_path',
            'certificate' => 'certificate_path',
            'clearance' => 'barangay_clearance_path',
            default => null,
        };

        if ($column === null) {
            abort(404);
        }

        $jobseeker = $request->user();
        $path = $jobseeker->getAttribute($column);

        if (! is_string($path) || $path === '' || ! Storage::disk('public')->exists($path)) {
            abort(404);
        }

        return Storage::disk('public')->response($path, basename($path), [
            'Content-Disposition' => 'inline; filename="'.basename($path).'"',
        ]);
    }

    public function submitSatisfactionRating(Request $request)
    {
        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
        ]);

        $jobseeker = $request->user();

        \Illuminate\Support\Facades\DB::table('satisfaction_ratings')->insert([
            'jobseeker_id' => $jobseeker->id,
            'rating' => $validated['rating'],
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Satisfaction rating submitted successfully',
        ]);
    }

    public function saveFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $jobseeker = $request->user();
        $jobseeker->update(['fcm_token' => $request->fcm_token]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token saved successfully',
        ]);
    }

    private function sendEmailChangeOtpEmail($jobseeker, string $newEmail, string $otpCode): bool
    {
        try {
            $mj = new \Mailjet\Client(env('MAILJET_API_KEY'), env('MAILJET_SECRET_KEY'), true, ['version' => 'v3.1']);
            $body = [
                'Messages' => [
                    [
                        'From' => [
                            'Email' => env('MAILJET_FROM_EMAIL', 'peso@posuechague.site'),
                            'Name'  => env('MAILJET_FROM_NAME', 'PESO Santiago'),
                        ],
                        'To' => [
                            [
                                'Email' => $newEmail,
                                'Name'  => $jobseeker->first_name ?? 'Jobseeker',
                            ],
                        ],
                        'TemplateID' => 7861324,
                        'TemplateLanguage' => true,
                        'Subject' => 'Confirm Your New Email — PESO Santiago Jobseeker',
                        'Variables' => [
                            'first_name' => $jobseeker->first_name ?? 'Jobseeker',
                            'otp_code'   => $otpCode,
                            'verify_url' => env('FRONTEND_URL', 'http://localhost:8080'),
                        ],
                    ],
                ],
            ];
            $response = $mj->post(\Mailjet\Resources::$Email, ['body' => $body]);
            if (!$response->success()) {
                Log::error('Mailjet API Error (Email Change OTP): ' . json_encode($response->getData()));
                return false;
            }
            return true;
        } catch (\Throwable $e) {
            Log::error('Mailjet Exception (Email Change OTP): ' . $e->getMessage());
            return false;
        }
    }

    private function generateOtp(): string
    {
        return str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
    }

    private function refreshOtpDailyCounterWindow($jobseeker, Carbon $now): void
    {
        $today = $now->toDateString();
        $raw = $jobseeker->getAttribute('otp_send_count_date');
        if ($raw instanceof \DateTimeInterface) {
            $currentDate = $raw->format('Y-m-d');
        } else {
            $currentDate = $raw ? (string) $raw : null;
        }
        if ($currentDate === $today) {
            return;
        }
        $jobseeker->otp_send_count_today = 0;
        $jobseeker->otp_resend_count = 0;
        $jobseeker->otp_resend_cooldown_until = null;
        $jobseeker->setAttribute('otp_send_count_date', $today);
        $jobseeker->save();
    }

    private function secondsUntilNextDay(Carbon $now): int
    {
        return $now->copy()->endOfDay()->diffInSeconds($now) + 1;
    }
}
