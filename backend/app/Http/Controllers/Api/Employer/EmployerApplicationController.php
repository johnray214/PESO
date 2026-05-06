<?php

namespace App\Http\Controllers\Api\Employer;

use App\Http\Controllers\Controller;
use App\Http\Resources\ApplicationResource;
use App\Models\Application;
use App\Models\ApplicationActivityLog;
use App\Models\Notification;
use App\Models\NotificationRead;
use App\Events\AdminActivityEvent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class EmployerApplicationController extends Controller
{
    public function index(Request $request)
    {
        $employer = $request->user();
        
        $query = Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        });
        
        if ($request->has('search')) {
            $search = $request->search;
            $query->whereHas('jobseeker', function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                  ->orWhere('last_name', 'like', "%{$search}%")
                  ->orWhereRaw("CONCAT(first_name, ' ', last_name) LIKE ?", ["%{$search}%"]);
            });
        }
        
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        if ($request->has('job_title')) {
            $query->whereHas('jobListing', function ($q) use ($request) {
                $q->where('title', $request->job_title);
            });
        }
        
        if ($request->has('job_listing_id')) {
            $query->where('job_listing_id', $request->job_listing_id);
        }

        $applications = $query->with(['jobseeker' => fn($q) => $q->withTrashed()->with('skills'), 'jobListing'])
            ->orderByDesc('applied_at')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data'    => ApplicationResource::collection($applications->items()),
            'meta'    => [
                'current_page' => $applications->currentPage(),
                'last_page'    => $applications->lastPage(),
                'total'        => $applications->total(),
                'per_page'     => $applications->perPage(),
            ],
        ]);
    }

    public function show(Request $request, $id)
    {
        $employer = $request->user();
        
        $application = Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        })->with(['jobseeker' => fn($q) => $q->withTrashed()->with('skills'), 'jobListing'])->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $application,
        ]);
    }

    /**
     * Stream applicant resume PDF (must be an application to this employer's listing).
     */
    public function downloadResume(Request $request, $id)
    {
        $employer = $request->user();

        $application = Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        })->with(['jobseeker' => fn($q) => $q->withTrashed()])->findOrFail($id);

        $path = $application->jobseeker->resume_path;

        if (! is_string($path) || $path === '' || ! Storage::disk('public')->exists($path)) {
            abort(404);
        }

        return Storage::disk('public')->response($path, basename($path), [
            'Content-Disposition' => 'inline; filename="'.basename($path).'"',
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $employer = $request->user();
        \Illuminate\Support\Facades\Log::info("UpdateStatus Payload:", $request->all());
        
        $validated = $request->validate([
            'status'     => ['required', Rule::in(['reviewing', 'shortlisted', 'interview', 'for_job_offer', 'hired', 'rejected'])],
            'start_date' => ['nullable', 'date'],
            'interview_date' => ['nullable', 'date'],
            'interview_time' => ['nullable'],
            'interview_format' => ['nullable', 'string', 'max:255'],
            'interview_location' => ['nullable', 'string', 'max:255'],
            'interviewer_name' => ['nullable', 'string', 'max:255'],
        ]);

        $application = Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        })->with(['jobseeker' => fn($q) => $q->withTrashed(), 'jobListing', 'jobListing.employer'])->findOrFail($id);

        $oldStatus = $application->status;
        $sendOffer = $request->boolean('send_offer');
        
        $application->update($validated);

        if ($validated['status'] === 'for_job_offer') {
            if ($sendOffer) {
                $application->offer_sent_at = now();
                $application->offer_response = null;
                $application->offer_response_at = null;
                $application->save();
            } else if ($oldStatus !== 'for_job_offer') {
                // If transitioning to for_job_offer (e.g. from interview) without sending an offer,
                // we must clear any previous offer history so it starts fresh at 'Preparing Offer'
                $application->offer_sent_at = null;
                $application->offer_response = null;
                $application->offer_response_at = null;
                $application->save();
            }
        }

        $newStatus = $application->status;

        // Always persist interview schedule details whenever the application is in interview status.
        // (Employers may resend/update the schedule while keeping status == interview.)
        if ($application->status === 'interview') {
            $rawInterviewDate = $request->input('interview_date');
            $rawInterviewTime = $request->input('interview_time');

            if ($rawInterviewDate !== null) {
                $parsedDate = null;
                if (! empty($rawInterviewDate)) {
                    try {
                        $parsedDate = \Carbon\Carbon::parse($rawInterviewDate)->toDateString();
                    } catch (\Throwable $e) {
                        $parsedDate = null;
                    }
                }
                $application->interview_date = $parsedDate;
            }

            if ($rawInterviewTime !== null) {
                $parsedTime = null;
                if (! empty($rawInterviewTime)) {
                    try {
                        $parsedTime = \Carbon\Carbon::parse($rawInterviewTime)->format('H:i:s');
                    } catch (\Throwable $e) {
                        $parsedTime = null;
                    }
                }
                $application->interview_time = $parsedTime;
            }

            if ($request->has('interview_format')) {
                $application->interview_format = $request->input('interview_format') ?: null;
            }
            if ($request->has('interview_location')) {
                $application->interview_location = $request->input('interview_location') ?: null;
            }
            if ($request->has('interviewer_name')) {
                $application->interviewer_name = $request->input('interviewer_name') ?: null;
            }

            $application->save();
        }

        // Only notify when status actually changes OR if we are sending/resending a job offer
        if ($newStatus !== $oldStatus || ($newStatus === 'for_job_offer' && $sendOffer)) {
            $jobseeker = $application->jobseeker;
            $job       = $application->jobListing;
            $company   = $job->employer->company_name ?? 'Employer';

            switch ($newStatus) {
                case 'reviewing':
                    $subject = 'Application received';
                    $message = "Your application for **{$job->title}** at **{$company}** has been received and is under review.";
                    $type = 'status_reviewing';
                    break;
                case 'shortlisted':
                    $subject = 'You have been Shortlisted!';
                    $message = "Great news! You have been shortlisted for the **{$job->title}** position at **{$company}**. The employer will contact you soon for the next steps.";
                    $type = 'status_shortlisted';
                    
                    try {
                        $mj = new \Mailjet\Client(env('MAILJET_API_KEY'), env('MAILJET_SECRET_KEY'), true, ['version' => 'v3.1']);
                        $body = [
                            'Messages' => [
                                [
                                    'From' => [ 'Email' => env('MAILJET_FROM_EMAIL'), 'Name' => env('MAILJET_FROM_NAME', 'PESO Santiago') ],
                                    'To' => [ [ 'Email' => $jobseeker->email, 'Name' => trim($jobseeker->first_name . ' ' . $jobseeker->last_name) ] ],
                                    'TemplateID' => 7861619,
                                    'TemplateLanguage' => true,
                                    'Subject' => 'You have been Shortlisted',
                                    'Variables' => [
                                        'first_name' => $jobseeker->first_name,
                                        'job_title' => $job->title,
                                        'company_name' => $company,
                                        'job_location' => $job->location ?? 'Not specified'
                                    ]
                                ]
                            ]
                        ];
                        $response = $mj->post(\Mailjet\Resources::$Email, ['body' => $body]);
                        if (!$response->success()) {
                            \Illuminate\Support\Facades\Log::error('Mailjet API Error Shortlisted Email: ' . json_encode($response->getData()));
                        }
                    } catch (\Throwable $e) {
                        \Illuminate\Support\Facades\Log::error('Mailjet Exception Shortlisted Email: ' . $e->getMessage());
                    }
                    break;
                case 'interview':
                    $subject = 'Interview Scheduled';
                    $message = "You have been scheduled for an interview for the **{$job->title}** position at **{$company}**.";
                    $type = 'status_interview';
                    $interviewMeta = [
                        'interview_date'     => ! empty($application->interview_date) ? \Carbon\Carbon::parse($application->interview_date)->format('F d, Y') : 'TBA',
                        'interview_time'     => ! empty($application->interview_time) ? \Carbon\Carbon::parse($application->interview_time)->format('h:i A') : 'TBA',
                        'interview_format'   => $application->interview_format ?: 'In-person',
                        'interview_location' => $application->interview_location ?: 'TBA',
                        'interviewer_name'   => $application->interviewer_name ?: 'Hiring Manager',
                    ];

                    try {
                        $mj = new \Mailjet\Client(env('MAILJET_API_KEY'), env('MAILJET_SECRET_KEY'), true, ['version' => 'v3.1']);
                        $body = [
                            'Messages' => [
                                [
                                    'From' => [ 'Email' => env('MAILJET_FROM_EMAIL'), 'Name' => env('MAILJET_FROM_NAME', 'PESO Santiago') ],
                                    'To' => [ [ 'Email' => $jobseeker->email, 'Name' => trim($jobseeker->first_name . ' ' . $jobseeker->last_name) ] ],
                                    'TemplateID' => 7861384,
                                    'TemplateLanguage' => true,
                                    'Subject' => 'Interview Scheduled',
                                    'Variables' => [
                                        'first_name' => $jobseeker->first_name,
                                        'company_name' => $company,
                                        'job_title' => $job->title,
                                        'interview_date' => $interviewMeta['interview_date'],
                                        'interview_time' => $interviewMeta['interview_time'],
                                        'interview_format' => $interviewMeta['interview_format'],
                                        'interview_location' => $interviewMeta['interview_location'],
                                        'interviewer_name' => $interviewMeta['interviewer_name'],
                                    ]
                                ]
                            ]
                        ];
                        $response = $mj->post(\Mailjet\Resources::$Email, ['body' => $body]);
                        if (!$response->success()) {
                            \Illuminate\Support\Facades\Log::error('Mailjet API Error Interview Email: ' . json_encode($response->getData()));
                        }
                    } catch (\Throwable $e) {
                        \Illuminate\Support\Facades\Log::error('Mailjet Exception Interview Email: ' . $e->getMessage());
                    }
                    break;
                case 'for_job_offer':
                    if ($sendOffer) {
                        $subject = 'You have received a Job Offer!';
                        $message = "Great news! **{$company}** has officially extended a job offer to you for the **{$job->title}** position. Please log in to your PESO account to review and accept the offer.";
                        $type = 'status_for_job_offer_sent';
                        $templateId = 7861483;
                        $variables = [
                            'first_name'      => $jobseeker->first_name,
                            'company_name'    => $company,
                            'job_title'       => $job->title,
                            'start_date'      => !empty($request->input('start_date')) ? \Carbon\Carbon::parse($request->input('start_date'))->format('F d, Y') : 'To be discussed',
                            'salary'          => $job->salary_range ?? 'Negotiable',
                            'employment_type' => $job->job_type ?? 'Full-time'
                        ];
                        
                        $hiredMeta = [ // Storing the meta for notification payload
                            'job_title'       => $job->title,
                            'company_name'    => $company,
                            'start_date'      => $variables['start_date'],
                            'salary'          => $variables['salary'],
                            'employment_type' => $variables['employment_type'],
                        ];
                    } else {
                        $subject = 'Great news — You passed your interview!';
                        $message = "Congratulations! You have successfully passed the interview for **{$job->title}** at **{$company}**. A formal job offer is currently being prepared for you.";
                        $type = 'status_for_job_offer';
                        $templateId = 7972296;
                        $variables = [
                            'first_name'   => $jobseeker->first_name,
                            'company_name' => $company,
                            'job_title'    => $job->title,
                        ];
                    }

                    try {
                        $mj = new \Mailjet\Client(env('MAILJET_API_KEY'), env('MAILJET_SECRET_KEY'), true, ['version' => 'v3.1']);
                        $body = [
                            'Messages' => [
                                [
                                    'From' => [ 'Email' => env('MAILJET_FROM_EMAIL'), 'Name' => env('MAILJET_FROM_NAME', 'PESO Santiago') ],
                                    'To' => [ [ 'Email' => $jobseeker->email, 'Name' => trim($jobseeker->first_name . ' ' . $jobseeker->last_name) ] ],
                                    'TemplateID' => $templateId,
                                    'TemplateLanguage' => true,
                                    'Subject' => $subject,
                                    'Variables' => $variables
                                ]
                            ]
                        ];
                        $response = $mj->post(\Mailjet\Resources::$Email, ['body' => $body]);
                        if (!$response->success()) {
                            \Illuminate\Support\Facades\Log::error('Mailjet API Error For Job Offer Email: ' . json_encode($response->getData()));
                        }
                    } catch (\Throwable $e) {
                        \Illuminate\Support\Facades\Log::error('Mailjet Exception For Job Offer Email: ' . $e->getMessage());
                    }
                    break;
                case 'hired':
                    $subject = 'Congratulations — You are Hired!';
                    $message = "Outstanding! You have been officially hired for **{$job->title}** at **{$company}**. Welcome to the team!";
                    $type = 'status_hired';

                    $hiredMeta = [
                        'job_title'       => $job->title,
                        'company_name'    => $company,
                        'update_date'  => now()->format('F d, Y'),
                    ];
                    // Removed Mailjet logic here because the jobseeker already accepted the job offer.
                    break;
                case 'rejected':
                    $subject = 'Application Update';
                    $message = "Thank you for your interest in the **{$job->title}** position at **{$company}**. Unfortunately, the employer has decided not to proceed with your application at this time.";
                    $type = 'status_rejected';

                    $rejectedMeta = [
                        'job_title'    => $job->title,
                        'company_name' => $company,
                        'update_date'  => now()->format('F d, Y'),
                    ];

                    try {
                        $mj = new \Mailjet\Client(env('MAILJET_API_KEY'), env('MAILJET_SECRET_KEY'), true, ['version' => 'v3.1']);
                        $body = [
                            'Messages' => [
                                [
                                    'From' => [ 'Email' => env('MAILJET_FROM_EMAIL'), 'Name' => env('MAILJET_FROM_NAME', 'PESO Santiago') ],
                                    'To' => [ [ 'Email' => $jobseeker->email, 'Name' => trim($jobseeker->first_name . ' ' . $jobseeker->last_name) ] ],
                                    'TemplateID' => 7972299,
                                    'TemplateLanguage' => true,
                                    'Subject' => 'Application Update: Not Selected',
                                    'Variables' => [
                                        'first_name' => $jobseeker->first_name,
                                        'company_name' => $company,
                                        'job_title' => $job->title,
                                        'update_date' => now()->format('F d, Y')
                                    ]
                                ]
                            ]
                        ];
                        $response = $mj->post(\Mailjet\Resources::$Email, ['body' => $body]);
                        if (!$response->success()) {
                            \Illuminate\Support\Facades\Log::error('Mailjet API Error Rejected Email: ' . json_encode($response->getData()));
                        }
                    } catch (\Throwable $e) {
                        \Illuminate\Support\Facades\Log::error('Mailjet Exception Rejected Email: ' . $e->getMessage());
                    }
                    break;
                default:
                    $subject = 'Application update';
                    $message = "There is an update to your application for **{$job->title}** at **{$company}**.";
                    $type = 'application_update';
            }

            $notification = Notification::create([
                'subject'        => $subject,
                'message'        => $message,
                'type'           => $type,
                'job_listing_id' => $job->id,
                'meta'           => $interviewMeta ?? $hiredMeta ?? $rejectedMeta ?? null,
                'recipients'     => 'jobseekers',
                'scheduled_at'   => null,
                'sent_at'        => now(),
                'status'         => 'sent',
                'created_by'     => $employer->id,
            ]);

            NotificationRead::create([
                'notification_id' => $notification->id,
                'recipient_type'  => 'jobseeker',
                'recipient_id'    => $jobseeker->id,
                'read_at'         => null,
            ]);

            if (($newStatus === 'hired' || $newStatus === 'rejected') && !$jobseeker->has_received_satisfaction_survey) {
                $surveyNotification = Notification::create([
                    'subject'        => 'Rate your application experience',
                    'message'        => 'How satisfied are you with the application process on PESO Santiago Connect?',
                    'type'           => 'satisfaction_survey',
                    'recipients'     => 'jobseekers',
                    'scheduled_at'   => null,
                    'sent_at'        => now(),
                    'status'         => 'sent',
                    'created_by'     => $employer->id, // Or null if system
                ]);

                NotificationRead::create([
                    'notification_id' => $surveyNotification->id,
                    'recipient_type'  => 'jobseeker',
                    'recipient_id'    => $jobseeker->id,
                    'read_at'         => null,
                ]);

                $jobseeker->update(['has_received_satisfaction_survey' => true]);
            }

            event(new AdminActivityEvent(
                'Status',
                'Application Status Updated',
                "{$company} updated {$jobseeker->first_name}'s application for {$job->title} to " . ucfirst($newStatus) . ".",
                'app_' . $application->id . '_' . time()
            ));

            // Log activity for History tab
            ApplicationActivityLog::create([
                'application_id' => $application->id,
                'actor_type'     => 'employer',
                'actor_label'    => $company,
                'action'         => ucfirst($newStatus),
            ]);

            // Auto-close job if hired count reaches slots
            if ($newStatus === 'hired') {
                $hiredCount = $job->applications()->where('status', 'hired')->count();
                if ($job->slots > 0 && $hiredCount >= $job->slots) {
                    $job->update(['status' => 'closed']);
                }
            }
        }

        return response()->json([
            'success' => true,
            'data' => $application,
            'message' => 'Application status updated successfully',
        ]);
    }

    public function potentialApplicants(Request $request)
    {
        $employer = $request->user();
        
        $jobListings = $employer->jobListings()->with('skills')->get();
        $jobSkills = $jobListings->pluck('skills')->flatten()->pluck('skill')->unique();
        
        $query = \App\Models\Jobseeker::with(['skills', 'applications'])
            ->where('status', 'active')
            ->whereHas('skills', function ($q) use ($jobSkills) {
                $q->whereIn('skill', $jobSkills);
            });
        
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                  ->orWhere('last_name', 'like', "%{$search}%")
                  ->orWhereHas('skills', function ($sq) use ($search) {
                      $sq->where('skill', 'like', "%{$search}%");
                  });
            });
        }

        $jobseekers = $query->orderByDesc('created_at')->get();

        $processed = $jobseekers->map(function ($jobseeker) use ($jobListings) {
            $maxScore = 0;
            $bestJob  = null;
            foreach ($jobListings as $job) {
                if ($jobseeker->applications->contains('job_listing_id', $job->id)) continue;

                $score = \App\Models\Application::calculateMatchScore($jobseeker, $job);
                if ($score > $maxScore) {
                    $maxScore = $score;
                    $bestJob  = $job;
                }
            }
            $jobseeker->match_score    = $maxScore;
            $jobseeker->best_job_match = $bestJob?->title ?? null;
            $jobseeker->best_job_skills = $bestJob ? $bestJob->skills->pluck('skill')->values() : [];
            $jobseeker->best_job_id = $bestJob?->id ?? null;
            $jobseeker->education_level = ucwords(str_replace('_', ' ', $jobseeker->education_level ?? 'Not specified'));
            return $jobseeker;
        })->filter(function ($jobseeker) {
            return $jobseeker->match_score > 0;
        })->values();

        $page = \Illuminate\Pagination\Paginator::resolveCurrentPage('page') ?: 1;
        $perPage = 15;
        
        $paginated = new \Illuminate\Pagination\LengthAwarePaginator(
            $processed->forPage($page, $perPage)->values(),
            $processed->count(),
            $perPage,
            $page,
            [
                'path' => \Illuminate\Pagination\Paginator::resolveCurrentPath(),
                'query' => request()->query()
            ]
        );

        return response()->json([
            'success' => true,
            'data' => $paginated,
        ]);
    }

    /**
     * Send a job invitation email to a potential applicant (jobseeker).
     */
    public function sendInvite(Request $request, $jobseekerId)
    {
        $employer = $request->user();

        $jobseeker = \App\Models\Jobseeker::with('skills')->findOrFail($jobseekerId);

        // Find the best-matching job for this jobseeker
        $jobListings = $employer->jobListings()->with('skills')->get();
        $maxScore = 0;
        $bestJob  = null;
        foreach ($jobListings as $job) {
            $score = \App\Models\Application::calculateMatchScore($jobseeker, $job);
            if ($score > $maxScore) { $maxScore = $score; $bestJob = $job; }
        }

        if (!$bestJob) {
            return response()->json(['success' => false, 'message' => 'No matching job listing found.'], 422);
        }

        $company   = $employer->company_name ?? 'Employer';
        $topSkills = $jobseeker->skills->pluck('skill')->take(3)->implode(', ');
        $applyUrl  = env('FRONTEND_URL', 'http://localhost:8080') . '/jobseeker/jobs/' . $bestJob->id;

        // Send Mailjet email
        try {
            $mj = new \Mailjet\Client(env('MAILJET_API_KEY'), env('MAILJET_SECRET_KEY'), true, ['version' => 'v3.1']);
            $body = [
                'Messages' => [[
                    'From' => ['Email' => env('MAILJET_FROM_EMAIL'), 'Name' => env('MAILJET_FROM_NAME', 'PESO Santiago')],
                    'To'   => [['Email' => $jobseeker->email, 'Name' => $jobseeker->full_name]],
                    'TemplateID'       => 7869914,
                    'TemplateLanguage' => true,
                    'Subject'          => "You're Invited to Apply — {$bestJob->title} at {$company}",
                    'Variables'        => [
                        'first_name'       => $jobseeker->first_name,
                        'company_name'     => $company,
                        'hero_subtext'     => "{$company} has reviewed your profile and personally invited you to apply.",
                        'invitation_text'  => "{$company} has reviewed your PESO Santiago profile and believes you are an excellent candidate for one of their open positions. They have personally invited you to apply.",
                        'job_title'        => $bestJob->title,
                        'job_location'     => $bestJob->location ?? 'On-site',
                        'employment_type'  => $bestJob->job_type ?? 'Full-time',
                        'salary_range'     => $bestJob->salary_range ?? 'Negotiable',
                        'work_setup'       => $bestJob->work_setup ?? 'On-site',
                        'match_pct'        => (string) round($maxScore),
                        'top_skills'       => $topSkills ?: 'your listed skills',
                        'apply_url'        => $applyUrl,
                    ],
                ]],
            ];
            $response = $mj->post(\Mailjet\Resources::$Email, ['body' => $body]);
            if (!$response->success()) {
                \Illuminate\Support\Facades\Log::error('Mailjet Invite Error: ' . json_encode($response->getData()));
            }
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Mailjet Invite Exception: ' . $e->getMessage());
        }

        // Create notification for JOBSEEKER
        $jobseekerNotif = Notification::create([
            'subject'    => 'Job Invitation from ' . $company,
            'message'    => "You have been personally invited by {$company} to apply for the {$bestJob->title} position. Check your email for details.",
            'recipients' => 'jobseekers',
            'scheduled_at' => null,
            'sent_at'    => now(),
            'status'     => 'sent',
            'created_by' => $employer->id,
        ]);
        NotificationRead::create([
            'notification_id' => $jobseekerNotif->id,
            'recipient_type'  => 'jobseeker',
            'recipient_id'    => $jobseeker->id,
            'read_at'         => null,
        ]);

        // Create notification for EMPLOYER
        $employerNotif = Notification::create([
            'subject'    => 'Invitation Sent',
            'message'    => "You successfully invited {$jobseeker->full_name} to apply for {$bestJob->title}.",
            'recipients' => 'employers',
            'scheduled_at' => null,
            'sent_at'    => now(),
            'status'     => 'sent',
            'created_by' => $employer->id,
        ]);
        NotificationRead::create([
            'notification_id' => $employerNotif->id,
            'recipient_type'  => 'employer',
            'recipient_id'    => $employer->id,
            'read_at'         => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => "Invitation sent to {$jobseeker->full_name}",
        ]);
    }

    public function history(Request $request, $id)
    {
        $employer = $request->user();

        $application = Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        })->findOrFail($id);

        $logs = ApplicationActivityLog::where('application_id', $application->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(function ($log) {
                return [
                    'id'          => $log->id,
                    'actor_type'  => $log->actor_type,
                    'actor_label' => $log->actor_label,
                    'action'      => $log->action,
                    'created_at'  => $log->created_at->toIso8601String(),
                ];
            });

        return response()->json([
            'success' => true,
            'data'    => $logs,
        ]);
    }
}

