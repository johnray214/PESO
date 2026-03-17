<?php

namespace App\Http\Controllers\Api\Employer;

use App\Http\Controllers\Controller;
use App\Http\Resources\ApplicationResource;
use App\Models\Application;
use Illuminate\Http\Request;
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
                  ->orWhere('last_name', 'like', "%{$search}%");
            });
        }
        
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        if ($request->has('job_listing_id')) {
            $query->where('job_listing_id', $request->job_listing_id);
        }

        $applications = $query->with(['jobseeker.skills', 'jobListing'])
            ->orderByDesc('applied_at')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => ApplicationResource::collection($applications),
        ]);
    }

    public function show(Request $request, $id)
    {
        $employer = $request->user();
        
        $application = Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        })->with(['jobseeker.skills', 'jobListing'])->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $application,
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $employer = $request->user();
        
        $validated = $request->validate([
            'status' => ['required', Rule::in(['reviewing', 'shortlisted', 'interview', 'hired', 'rejected'])],
        ]);

        $application = Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        })->findOrFail($id);
        
        $application->update($validated);

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
        
        $query = \App\Models\Jobseeker::with('skills')
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

        $jobseekers = $query->orderByDesc('created_at')->paginate(15);

        // Calculate match score and best matching job for each
        $jobseekers->getCollection()->transform(function ($jobseeker) use ($jobListings) {
            $maxScore = 0;
            $bestJob = null;
            foreach ($jobListings as $job) {
                $score = \App\Models\Application::calculateMatchScore($jobseeker, $job);
                if ($score > $maxScore) {
                    $maxScore = $score;
                    $bestJob = $job;
                }
            }
            $jobseeker->match_score = $maxScore;
            $jobseeker->best_job_match = $bestJob?->title ?? null;
            return $jobseeker;
        });

        return response()->json([
            'success' => true,
            'data' => $jobseekers,
        ]);
    }
}
