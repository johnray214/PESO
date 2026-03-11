<?php

namespace App\Http\Controllers\Api\Employer;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\JobApplication;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class EmployerApplicantController extends Controller
{
    public function index(Request $request)
    {
        $employer = $request->user();
        $jobIds   = $employer->jobListings()->pluck('id');

        $query = JobApplication::with(['user.documents', 'jobListing'])
            ->whereIn('job_listing_id', $jobIds);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('user', fn($q) => $q->where('name', 'like', "%{$search}%")
                ->orWhere('email', 'like', "%{$search}%"));
        }

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('employer_status', $request->status);
        }

        if ($request->filled('position')) {
            $query->whereHas('jobListing', fn($q) => $q->where('title', 'like', "%{$request->position}%"));
        }

        $apps = $query->latest()->paginate($request->get('per_page', 15));

        $apps->getCollection()->transform(fn($app) => $this->formatApplication($app, $employer));

        return response()->json(['success' => true, 'data' => $apps]);
    }

    public function show(Request $request, $id)
    {
        $employer = $request->user();
        $jobIds   = $employer->jobListings()->pluck('id');

        $app = JobApplication::with(['user.documents', 'jobListing'])
            ->whereIn('job_listing_id', $jobIds)
            ->findOrFail($id);

        return response()->json(['success' => true, 'data' => $this->formatApplication($app, $employer)]);
    }

    public function updateStatus(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:reviewing,shortlisted,interview,hired,rejected',
            'notes'  => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employer = $request->user();
        $jobIds   = $employer->jobListings()->pluck('id');

        $app = JobApplication::whereIn('job_listing_id', $jobIds)->findOrFail($id);
        $app->update([
            'employer_status' => $request->status,
            'employer_notes'  => $request->notes ?? $app->employer_notes,
        ]);

        if ($request->status === 'hired') {
            $employer->increment('total_hired');
            $app->jobListing->increment('hired_count');
            if ($app->user) {
                $app->user->update(['peso_status' => 'hired']);
            }
        }

        AuditLog::record(
            'Status Changed', 'Applicants',
            "Applicant {$app->user?->name} status set to {$request->status} for job {$app->jobListing?->title}",
            $request, $employer
        );

        return response()->json(['success' => true, 'message' => 'Status updated']);
    }

    private function computeMatchScore($user, $jobListing): int
    {
        if (!$user || !$jobListing) return 0;
        $userSkills = $user->skills ?? [];
        $jobSkills  = $jobListing->skills ?? [];

        if (empty($jobSkills)) return 0;

        $matched = count(array_intersect(
            array_map('strtolower', $userSkills),
            array_map('strtolower', $jobSkills)
        ));

        return (int) round(($matched / count($jobSkills)) * 100);
    }

    private function formatApplication(JobApplication $app, $employer): array
    {
        $user = $app->user;
        $job  = $app->jobListing;

        $matchScore = $app->match_score > 0
            ? $app->match_score
            : $this->computeMatchScore($user, $job);

        return [
            'id'          => $app->id,
            'name'        => $user?->name ?? 'N/A',
            'email'       => $user?->email ?? 'N/A',
            'location'    => $user?->address ?? 'N/A',
            'contact'     => $user?->phone ?? 'N/A',
            'education'   => $user?->education,
            'experience'  => $user?->experience,
            'skills'      => $user?->skills ?? [],
            'jobApplied'  => $job?->title ?? 'N/A',
            'date'        => $app->created_at->format('M d, Y'),
            'status'      => $app->employer_status,
            'notes'       => $app->employer_notes,
            'matchScore'  => $matchScore,
            'resume'      => $user?->documents?->resume_url,
            'resumeName'  => $user?->documents?->resume_name,
        ];
    }
}
