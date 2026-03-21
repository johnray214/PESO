<?php

namespace App\Http\Controllers\Api\Employer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EmployerDashboardController extends Controller
{
    public function index(Request $request)
    {
        $employer = $request->user();
        
        $jobListings = $employer->jobListings()->withCount('applications')->with('skills')->get();
        
        $totalJobs = $jobListings->count();
        $openJobs = $jobListings->where('status', 'open')->count();
        $totalApplications = $jobListings->sum('applications_count');
        
        $recentApplications = \App\Models\Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        })->with(['jobseeker.skills', 'jobListing:id,title'])
            ->orderByDesc('applied_at')
            ->limit(10)
            ->get();

        $applicationStatusCounts = \App\Models\Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        })->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->pluck('count', 'status');

        // Applications over time (monthly data for current year)
        $currentYear = now()->year;
        $monthlyApplications = \App\Models\Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        })->selectRaw('MONTH(applied_at) as month, COUNT(*) as count')
            ->whereYear('applied_at', $currentYear)
            ->groupBy('month')
            ->pluck('count', 'month');

        $monthlyHired = \App\Models\Application::whereHas('jobListing', function ($q) use ($employer) {
            $q->where('employer_id', $employer->id);
        })->where('status', 'hired')
            ->selectRaw('MONTH(updated_at) as month, COUNT(*) as count')
            ->whereYear('updated_at', $currentYear)
            ->groupBy('month')
            ->pluck('count', 'month');

        $chartData = [];
        $months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        foreach ($months as $i => $label) {
            $monthNum = $i + 1;
            $chartData[] = [
                'label' => $label,
                'applications' => $monthlyApplications[$monthNum] ?? 0,
                'hired' => $monthlyHired[$monthNum] ?? 0,
            ];
        }

        // Active job listings with applicant counts
        $activeJobs = $jobListings->where('status', 'open')->map(function ($job) {
            return [
                'id' => $job->id,
                'title' => $job->title,
                'applicants' => $job->applications_count,
                'slots' => $job->slots ?? 10,
            ];
        })->values();

        // Potential applicants - jobseekers with skills matching job listings
        $employerJobSkills = $jobListings->flatMap(function ($job) {
            return $job->skills->pluck('skill');
        })->unique()->toArray();

        $potentialApplicants = [];
        if (!empty($employerJobSkills)) {
            $jobseekers = \App\Models\Jobseeker::whereHas('skills', function ($q) use ($employerJobSkills) {
                $q->whereIn('skill', $employerJobSkills);
            })->with('skills')->limit(20)->get();

            foreach ($jobseekers as $js) {
                $jsSkills = $js->skills->pluck('skill')->toArray();
                $matchingSkills = array_intersect($jsSkills, $employerJobSkills);
                
                if (count($matchingSkills) > 0) {
                    // Find best matching job
                    $bestJob = null;
                    $bestScore = 0;
                    foreach ($jobListings as $job) {
                        $jobSkills = $job->skills->pluck('skill')->toArray();
                        if (empty($jobSkills)) continue;
                        $matchCount = count(array_intersect($jsSkills, $jobSkills));
                        $score = ($matchCount / count($jobSkills)) * 100;
                        if ($score > $bestScore) {
                            $bestScore = $score;
                            $bestJob = $job;
                        }
                    }

                    if ($bestJob && $bestScore > 0) {
                        $potentialApplicants[] = [
                            'id' => $js->id,
                            'name' => $js->full_name,
                            'skills' => array_slice($jsSkills, 0, 3),
                            'score' => round($bestScore),
                            'job_id' => $bestJob->id,
                            'job_title' => $bestJob->title,
                            'location' => $js->address ?? 'Unknown',
                            'education' => $js->education_level ?? 'Not specified',
                        ];
                    }
                }
            }
        }

        // Sort by score descending
        usort($potentialApplicants, function ($a, $b) {
            return $b['score'] <=> $a['score'];
        });

        return response()->json([
            'success' => true,
            'data' => [
                'stats' => [
                    'total_jobs' => $totalJobs,
                    'open_jobs' => $openJobs,
                    'total_applications' => $totalApplications,
                    'application_status_counts' => $applicationStatusCounts,
                ],
                'chart_data' => $chartData,
                'active_jobs' => $activeJobs,
                'potential_applicants' => array_slice($potentialApplicants, 0, 10),
                'recent_applications' => $recentApplications,
            ],
        ]);
    }
}
