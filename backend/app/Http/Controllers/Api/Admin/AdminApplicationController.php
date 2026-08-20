<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\ApplicationActivityLog;
use App\Models\Notification;
use App\Models\NotificationRead;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminApplicationController extends Controller
{
    public function index(Request $request)
    {
        $query = Application::query();
        
        if ($request->has('search')) {
            $search = $request->search;
            $query->whereHas('jobseeker', function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                  ->orWhere('last_name', 'like', "%{$search}%")
                  ->orWhereRaw("CONCAT(first_name, ' ', last_name) LIKE ?", ["%{$search}%"]);
            });
        }
        
        if ($request->has('status') && $request->status !== '') {
            $query->where('status', str_replace(' ', '_', strtolower((string) $request->status)));
        }
        
        if ($request->has('job_listing_id')) {
            $query->where('job_listing_id', $request->job_listing_id);
        }
        
        if ($request->has('jobseeker_id')) {
            $query->where('jobseeker_id', $request->jobseeker_id);
        }

        if ($request->has('skill') && $request->skill !== '') {
            $skill = $request->skill;
            $query->whereHas('jobseeker.skills', function ($q) use ($skill) {
                $q->where('skill', 'like', "%{$skill}%");
            });
        }

        if ($request->has('date_from') && $request->date_from !== '') {
            $dateFrom = match($request->date_from) {
                'today' => now()->startOfDay(),
                'week'  => now()->startOfWeek(),
                'month' => now()->startOfMonth(),
                default => null,
            };
            if ($dateFrom) {
                $query->where('applied_at', '>=', $dateFrom);
            }
        }

        if ($request->has('program') && $request->program !== '') {
            $prog = $request->program;
            if ($prog === 'all_dole' || $prog === 'dole') {
                $query->whereHas('jobListing', function ($q) {
                    $q->whereNotNull('program')
                      ->where('program', '!=', '')
                      ->whereRaw('LOWER(program) != ?', ['none']);
                });
            } elseif ($prog === 'regular') {
                $query->whereHas('jobListing', function ($q) {
                    $q->where(function ($q2) {
                        $q2->whereNull('program')
                           ->orWhere('program', '')
                           ->orWhereRaw('LOWER(program) = ?', ['none']);
                    });
                });
            } else {
                $query->whereHas('jobListing', function ($q) use ($prog) {
                    $q->where('program', $prog);
                });
            }
        }

        $perPage = $request->input('per_page', 15);
        if ($perPage === 'all' || $request->boolean('all_records')) {
            $applications = $query->with([
                'jobseeker:id,first_name,last_name,address,province_name,city_name,barangay_name,street_address,contact,email,sex,date_of_birth,education_level,job_experience,resume_path,certificate_path,barangay_clearance_path',
                'jobseeker.skills:id,jobseeker_id,skill',
                'jobListing:id,title,employer_id,program,program_budget,program_duration,program_target,implementing_agency',
                'jobListing.employer:id,company_name'
            ])
                ->orderByDesc('applied_at')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $applications,
            ]);
        }

        $perPage = min(max((int)$perPage, 1), 500);

        $applications = $query->with([
            'jobseeker:id,first_name,last_name,address,province_name,city_name,barangay_name,street_address,contact,email,sex,date_of_birth,education_level,job_experience,resume_path,certificate_path,barangay_clearance_path',
            'jobseeker.skills:id,jobseeker_id,skill',
            'jobListing:id,title,employer_id,program,program_budget,program_duration,program_target,implementing_agency',
            'jobListing.employer:id,company_name'
        ])
            ->orderByDesc('applied_at')
            ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $applications,
        ]);
    }

    public function show($id)
    {
        $application = Application::with(['jobseeker.skills', 'jobListing'])->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $application,
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $validated = $request->validate([
            'status' => ['required', Rule::in(['reviewing', 'shortlisted', 'interview', 'for_job_offer', 'hired', 'rejected'])],
        ]);

        $application = Application::with(['jobseeker', 'jobListing.employer'])->findOrFail($id);

        $oldStatus = $application->status;
        $application->update($validated);

        $newStatus = $application->status;

        // Create jobseeker notification and log when status actually changes
        if ($newStatus !== $oldStatus) {
            $jobseeker = $application->jobseeker;
            $job       = $application->jobListing;
            $company   = $job->employer->company_name ?? 'Employer';

            switch ($newStatus) {
                case 'reviewing':
                    $subject = 'Application received';
                    $message = "Your application for {$job->title} at {$company} has been received and is under review.";
                    break;
                case 'shortlisted':
                case 'interview':
                    $subject = 'Application in process';
                    $message = "Your application for {$job->title} at {$company} is now being processed.";
                    break;
                case 'for_job_offer':
                    $subject = 'You passed your interview!';
                    $message = "Congratulations! You have successfully passed the interview for {$job->title} at {$company}. A formal job offer is currently being prepared for you.";
                    break;
                case 'hired':
                    $subject = 'Application successful';
                    $message = "Congratulations! You have been hired for {$job->title} at {$company}.";
                    break;
                case 'rejected':
                    $subject = 'Application update';
                    $message = "Your application for {$job->title} at {$company} was not selected. Please consider applying to other opportunities.";
                    break;
                default:
                    $subject = 'Application update';
                    $message = "There is an update to your application for {$job->title} at {$company}.";
            }

            $notification = Notification::create([
                'subject'      => $subject,
                'message'      => $message,
                'recipients'   => 'jobseekers',
                'scheduled_at' => null,
                'sent_at'      => now(),
                'status'       => 'sent',
                'created_by'   => $request->user()->id ?? null,
            ]);

            NotificationRead::create([
                'notification_id' => $notification->id,
                'recipient_type'  => 'jobseeker',
                'recipient_id'    => $jobseeker->id,
                'read_at'         => null,
            ]);

            // Log activity
            ApplicationActivityLog::create([
                'application_id' => $application->id,
                'actor_type'     => 'peso',
                'actor_label'    => 'PESO',
                'action'         => $newStatus === 'for_job_offer' ? 'For Job Offer' : ucfirst($newStatus),
            ]);

            // Auto-close job if hired count reaches slots
            if ($newStatus === 'hired') {
                $job = $application->jobListing;
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

    public function history($id)
    {
        $application = Application::findOrFail($id);

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

    public function potentialApplicants(Request $request)
    {
        // Get ALL active job listings (across all employers) with their required skills
        $jobListings = \App\Models\JobListing::with(['employer', 'skills'])
            ->whereIn('status', ['open', 'Open'])
            ->get();

        if ($jobListings->isEmpty()) {
            return response()->json(['success' => true, 'data' => []]);
        }

        $allSkills = $jobListings->pluck('skills')->flatten()->pluck('skill')->unique();

        $query = \App\Models\Jobseeker::with(['skills', 'applications'])
            ->where('status', 'active')
            ->whereHas('skills', function ($q) use ($allSkills) {
                $q->whereIn('skill', $allSkills);
            });

        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('first_name', 'like', "%{$s}%")
                  ->orWhere('last_name', 'like', "%{$s}%")
                  ->orWhereRaw("CONCAT(first_name,' ',last_name) LIKE ?", ["%{$s}%"]);
            });
        }

        $jobseekers = $query->orderByDesc('created_at')->get();

        $processed = [];
        foreach ($jobseekers as $jobseeker) {
            foreach ($jobListings as $job) {
                // Skip jobs the jobseeker already applied to
                if ($jobseeker->applications->contains('job_listing_id', $job->id)) continue;
                
                $score = \App\Models\Application::calculateMatchScore($jobseeker, $job);
                if ($score > 0) {
                    $js = clone $jobseeker;
                    $js->match_score      = $score;
                    $js->best_job_title   = $job->title;
                    $js->best_job_id      = $job->id;
                    $js->best_employer    = $job->employer?->company_name;
                    $js->best_job_skills  = $job->skills->pluck('skill')->values()->toArray();
                    $js->education_display = ucwords(str_replace('_', ' ', $js->education_level ?? ''));
                    $processed[] = $js;
                }
            }
        }

        $processedCollection = collect($processed)->sortByDesc('match_score')->values();

        return response()->json([
            'success' => true,
            'data'    => $processedCollection,
        ]);
    }

    public function destroy($id)
    {
        $application = Application::findOrFail($id);
        $application->delete();

        return response()->json([
            'success' => true,
            'message' => 'Application deleted successfully',
        ]);
    }

    public function reviewingCount()
    {
        $count = \Illuminate\Support\Facades\Cache::remember('admin_app_reviewing_count', 15, function () {
            return \App\Models\Application::where('status', 'reviewing')->count();
        });
        return response()->json(['count' => $count]);
    }

    public function counts(Request $request)
    {
        $program = $request->query('program');
        $cacheKey = 'admin_app_counts_' . ($program ?: 'all');

        $counts = \Illuminate\Support\Facades\Cache::remember($cacheKey, 15, function () use ($program) {
            $applyProgramFilter = function ($q) use ($program) {
                if ($program === 'all_dole' || $program === 'dole') {
                    $q->whereHas('jobListing', function ($jl) {
                        $jl->whereNotNull('program')
                           ->where('program', '!=', '')
                           ->whereRaw('LOWER(program) != ?', ['none']);
                    });
                } elseif ($program === 'regular') {
                    $q->whereHas('jobListing', function ($jl) {
                        $jl->where(function ($jl2) {
                            $jl2->whereNull('program')
                               ->orWhere('program', '')
                               ->orWhereRaw('LOWER(program) = ?', ['none']);
                        });
                    });
                } elseif ($program && $program !== 'all') {
                    $q->whereHas('jobListing', function ($jl) use ($program) {
                        $jl->where('program', $program);
                    });
                }
            };

            $statuses = ['reviewing', 'shortlisted', 'interview', 'for_job_offer', 'hired', 'rejected'];
            
            $allQuery = Application::query();
            $applyProgramFilter($allQuery);
            $res = ['all' => $allQuery->count()];

            foreach ($statuses as $s) {
                $statusQuery = Application::where('status', $s);
                $applyProgramFilter($statusQuery);
                $res[$s] = $statusQuery->count();
            }

            // Global totals for tab headers
            $res['total_all'] = Application::count();
            $res['total_regular'] = Application::whereHas('jobListing', function ($jl) {
                $jl->whereNull('program')->orWhere('program', '')->orWhereRaw('LOWER(program) = ?', ['none']);
            })->count();
            $res['total_dole'] = Application::whereHas('jobListing', function ($jl) {
                $jl->whereNotNull('program')->where('program', '!=', '')->whereRaw('LOWER(program) != ?', ['none']);
            })->count();

            // Breakdown by DOLE program
            $res['programs'] = [
                'SPES'     => Application::whereHas('jobListing', fn($jl) => $jl->where('program', 'SPES'))->count(),
                'GIP'      => Application::whereHas('jobListing', fn($jl) => $jl->where('program', 'GIP'))->count(),
                'TUPAD'    => Application::whereHas('jobListing', fn($jl) => $jl->where('program', 'TUPAD'))->count(),
                'JobStart' => Application::whereHas('jobListing', fn($jl) => $jl->where('program', 'JobStart'))->count(),
            ];

            return $res;
        });

        return response()->json(['success' => true, 'data' => $counts]);
    }

    /**
     * Schedule single or batch interviews for applicants (e.g. DOLE programs or specific selection).
     */
    public function scheduleInterview(Request $request)
    {
        $validated = $request->validate([
            'application_ids'    => ['nullable', 'array'],
            'application_ids.*'  => ['integer'],
            'all'                => ['nullable', 'boolean'],
            'program'            => ['nullable', 'string'],
            'interview_date'     => ['required', 'date'],
            'interview_time'     => ['required'],
            'interview_format'   => ['nullable', 'string', 'max:255'],
            'interview_location' => ['required', 'string', 'max:255'],
            'interviewer_name'   => ['required', 'string', 'max:255'],
            'instructions'       => ['nullable', 'string', 'max:1000'],
        ]);

        $query = Application::with(['jobseeker', 'jobListing.employer']);

        if (!empty($validated['all']) && !empty($validated['program'])) {
            $query->whereHas('jobListing', function ($q) use ($validated) {
                if (strtoupper($validated['program']) === 'ALL') {
                    $q->whereNotNull('program')->where('program', '!=', '')->whereRaw('LOWER(program) != ?', ['none']);
                } else {
                    $q->where('program', $validated['program']);
                }
            })->whereNotIn('status', ['hired', 'rejected']);
        } elseif (!empty($validated['application_ids'])) {
            $query->whereIn('id', $validated['application_ids'])
                  ->whereNotIn('status', ['hired', 'rejected']);
        } else {
            return response()->json(['success' => false, 'message' => 'No applicants specified.'], 422);
        }

        $applications = $query->get();

        if ($applications->isEmpty()) {
            return response()->json(['success' => false, 'message' => 'No matching applicants found.'], 404);
        }

        $parsedDate = \Carbon\Carbon::parse($validated['interview_date'])->toDateString();
        $parsedTime = \Carbon\Carbon::parse($validated['interview_time'])->format('H:i:s');
        $format     = $validated['interview_format'] ?? 'In-person';
        $location   = $validated['interview_location'];
        $interviewer= $validated['interviewer_name'];
        $formattedDateStr = \Carbon\Carbon::parse($parsedDate)->format('F d, Y');
        $formattedTimeStr = \Carbon\Carbon::parse($parsedTime)->format('h:i A');

        $updatedCount = 0;

        foreach ($applications as $app) {
            $app->update([
                'status'             => 'interview',
                'interview_date'     => $parsedDate,
                'interview_time'     => $parsedTime,
                'interview_format'   => $format,
                'interview_location' => $location,
                'interviewer_name'   => $interviewer,
            ]);

            $jobseeker = $app->jobseeker;
            $job       = $app->jobListing;
            $progTitle = $job->program ? "DOLE {$job->program} Program" : ($job->title ?? 'Program');
            $company   = $job->employer->company_name ?? 'PESO Santiago City';

            // Activity Log
            ApplicationActivityLog::create([
                'application_id' => $app->id,
                'actor_type'     => 'peso',
                'actor_label'    => 'PESO Admin',
                'action'         => 'Interview Scheduled',
            ]);

            // In-app Notification
            $subject = "Interview Scheduled — {$progTitle}";
            $message = "You have been scheduled for an interview for **{$progTitle}** on **{$formattedDateStr}** at **{$formattedTimeStr}** at **{$location}** with **{$interviewer}**.";

            $notification = Notification::create([
                'subject'      => $subject,
                'message'      => $message,
                'recipients'   => 'jobseekers',
                'sent_at'      => now(),
                'status'       => 'sent',
                'created_by'   => $request->user()->id ?? null,
            ]);

            if ($jobseeker) {
                NotificationRead::create([
                    'notification_id' => $notification->id,
                    'recipient_type'  => 'jobseeker',
                    'recipient_id'    => $jobseeker->id,
                    'read_at'         => null,
                ]);

                // Email Notification via Mailjet if configured
                try {
                    $mailjetKey = config('services.mailjet.key');
                    $mailjetSecret = config('services.mailjet.secret');
                    if ($mailjetKey && $mailjetSecret && !empty($jobseeker->email)) {
                        $mj = new \Mailjet\Client($mailjetKey, $mailjetSecret, true, ['version' => 'v3.1']);
                        $body = [
                            'Messages' => [
                                [
                                    'From' => [
                                        'Email' => config('mail.from.address', 'noreply@pesosantiago.ph'),
                                        'Name'  => config('mail.from.name', 'PESO Santiago City'),
                                    ],
                                    'To' => [
                                        [
                                            'Email' => $jobseeker->email,
                                            'Name'  => $jobseeker->full_name ?? ($jobseeker->first_name . ' ' . $jobseeker->last_name),
                                        ]
                                    ],
                                    'Subject' => $subject,
                                    'HTMLPart' => "<h3>Interview Scheduled</h3><p>Dear {$jobseeker->first_name},</p><p>You are scheduled for an interview for <strong>{$progTitle}</strong>.</p><p><strong>Date:</strong> {$formattedDateStr}<br><strong>Time:</strong> {$formattedTimeStr}<br><strong>Format:</strong> {$format}<br><strong>Location / Link:</strong> {$location}<br><strong>Interviewer:</strong> {$interviewer}</p>" . (!empty($validated['instructions']) ? "<p><strong>Instructions:</strong> {$validated['instructions']}</p>" : "") . "<p>Best regards,<br>Public Employment Service Office (PESO) Santiago City</p>",
                                ]
                            ]
                        ];
                        $mj->post(\Mailjet\Resources::$Email, ['body' => $body]);
                    }
                } catch (\Throwable $e) {
                    \Illuminate\Support\Facades\Log::warning('DOLE Interview Email notice failed: ' . $e->getMessage());
                }
            }

            $updatedCount++;
        }

        return response()->json([
            'success' => true,
            'message' => "Successfully scheduled interview and sent notifications to {$updatedCount} applicant(s).",
            'count'   => $updatedCount,
        ]);
    }
}
