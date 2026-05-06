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
        
        if ($request->has('status')) {
            $query->where('status', $request->status);
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

        $applications = $query->with([
            'jobseeker:id,first_name,last_name,address,contact,email,sex,date_of_birth,education_level,job_experience,resume_path,certificate_path,barangay_clearance_path',
            'jobseeker.skills:id,jobseeker_id,skill',
            'jobListing:id,title,employer_id',
            'jobListing.employer:id,company_name'
        ])
            ->orderByDesc('applied_at')
            ->paginate(15);

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
                'action'         => ucfirst($newStatus),
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
        $jobListings = \Illuminate\Support\Facades\Cache::remember('open_job_listings_with_skills', 60, function() {
            return \App\Models\JobListing::with(['employer', 'skills'])->whereRaw('LOWER(status) = ?', ['open'])->get();
        });

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

        $processed = $jobseekers->map(function ($jobseeker) use ($jobListings) {
            $maxScore = 0;
            $bestJob  = null;
            foreach ($jobListings as $job) {
                // Skip jobs the jobseeker already applied to
                if ($jobseeker->applications->contains('job_listing_id', $job->id)) continue;
                $score = \App\Models\Application::calculateMatchScore($jobseeker, $job);
                if ($score > $maxScore) {
                    $maxScore = $score;
                    $bestJob  = $job;
                }
            }
            $jobseeker->match_score      = $maxScore;
            $jobseeker->best_job_title   = $bestJob?->title;
            $jobseeker->best_job_id      = $bestJob?->id;
            $jobseeker->best_employer    = $bestJob?->employer?->company_name;
            $jobseeker->best_job_skills  = $bestJob ? $bestJob->skills->pluck('skill')->values()->toArray() : [];
            $jobseeker->education_display = ucwords(str_replace('_', ' ', $jobseeker->education_level ?? ''));
            return $jobseeker;
        })->filter(fn ($js) => $js->match_score > 0)->values();

        return response()->json([
            'success' => true,
            'data'    => $processed,
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
        $count = \App\Models\Application::where('status', 'reviewing')->count();
        return response()->json(['count' => $count]);
    }

    public function counts()
    {
        $statuses = ['reviewing', 'shortlisted', 'interview', 'hired', 'rejected'];
        $counts = ['all' => Application::count()];
        foreach ($statuses as $s) {
            $counts[$s] = Application::where('status', $s)->count();
        }
        return response()->json(['success' => true, 'data' => $counts]);
    }
}
