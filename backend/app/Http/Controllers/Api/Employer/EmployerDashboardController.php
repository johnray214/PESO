<?php

namespace App\Http\Controllers\Api\Employer;

use App\Http\Controllers\Controller;
use App\Models\JobApplication;
use App\Models\JobListing;
use App\Models\User;
use Illuminate\Http\Request;

class EmployerDashboardController extends Controller
{
    public function index(Request $request)
    {
        $employer = $request->user();

        $jobIds      = $employer->jobListings()->pluck('id');
        $activeJobs  = $employer->jobListings()->where('status', 'open')->count();
        $totalApps   = JobApplication::whereIn('job_listing_id', $jobIds)->count();
        $totalHired  = JobApplication::whereIn('job_listing_id', $jobIds)
            ->where('employer_status', 'hired')->count();

        $prevApps = JobApplication::whereIn('job_listing_id', $jobIds)
            ->where('created_at', '<', now()->subMonth())->count();

        $stats = [
            [
                'label'    => 'Active Listings',
                'value'    => $activeJobs,
                'sub'      => 'Open job posts',
                'trendVal' => 0,
                'trendUp'  => true,
            ],
            [
                'label'    => 'Total Applicants',
                'value'    => $totalApps,
                'sub'      => 'All applications received',
                'trendVal' => $prevApps > 0
                    ? round((($totalApps - $prevApps) / $prevApps) * 100, 1)
                    : 0,
                'trendUp'  => $totalApps >= $prevApps,
            ],
            [
                'label'    => 'Total Hired',
                'value'    => $totalHired,
                'sub'      => 'Applicants hired',
                'trendVal' => 0,
                'trendUp'  => true,
            ],
            [
                'label'    => 'Total Job Slots',
                'value'    => $employer->jobListings()->sum('slots'),
                'sub'      => 'Available positions',
                'trendVal' => 0,
                'trendUp'  => true,
            ],
        ];

        $chartData   = $this->getMonthlyApplications($jobIds);
        $funnelStages = $this->getFunnelData($jobIds);
        $recentApplicants = $this->getRecentApplicants($jobIds);
        $activeListings   = $this->getActiveListings($employer);
        $skillGaps        = $this->getSkillGaps($employer);

        return response()->json([
            'success' => true,
            'data'    => compact('stats', 'chartData', 'funnelStages', 'recentApplicants', 'activeListings', 'skillGaps'),
        ]);
    }

    private function getMonthlyApplications($jobIds): array
    {
        $months = [];
        for ($i = 11; $i >= 0; $i--) {
            $date = now()->subMonths($i);
            $months[] = [
                'label'        => $date->format('M'),
                'applications' => JobApplication::whereIn('job_listing_id', $jobIds)
                    ->whereYear('created_at', $date->year)
                    ->whereMonth('created_at', $date->month)->count(),
                'hired'        => JobApplication::whereIn('job_listing_id', $jobIds)
                    ->where('employer_status', 'hired')
                    ->whereYear('updated_at', $date->year)
                    ->whereMonth('updated_at', $date->month)->count(),
            ];
        }
        return $months;
    }

    private function getFunnelData($jobIds): array
    {
        $stages = ['reviewing', 'shortlisted', 'interview', 'hired', 'rejected'];
        return array_map(fn($stage) => [
            'label' => ucfirst($stage),
            'count' => JobApplication::whereIn('job_listing_id', $jobIds)
                ->where('employer_status', $stage)->count(),
        ], $stages);
    }

    private function getRecentApplicants($jobIds): array
    {
        return JobApplication::with(['user', 'jobListing'])
            ->whereIn('job_listing_id', $jobIds)
            ->latest()
            ->take(5)
            ->get()
            ->map(fn($app) => [
                'id'         => $app->user->id ?? null,
                'name'       => $app->user->name ?? 'N/A',
                'location'   => $app->user->address ?? 'N/A',
                'skill'      => is_array($app->user->skills) && count($app->user->skills) > 0
                    ? $app->user->skills[0] : 'N/A',
                'job'        => $app->jobListing->title ?? 'N/A',
                'date'       => $app->created_at->format('M d, Y'),
                'status'     => $app->employer_status,
                'matchScore' => $app->match_score,
            ])
            ->toArray();
    }

    private function getActiveListings($employer): array
    {
        return $employer->jobListings()
            ->where('status', 'open')
            ->withCount('applications')
            ->take(5)
            ->get()
            ->map(fn($j) => [
                'id'         => $j->id,
                'title'      => $j->title,
                'applicants' => $j->applications_count,
                'slots'      => $j->slots,
            ])
            ->toArray();
    }

    private function getSkillGaps($employer): array
    {
        $requiredSkills = [];
        $employer->jobListings()->where('status', 'open')->get()->each(function ($job) use (&$requiredSkills) {
            if (!is_array($job->skills)) return;
            foreach ($job->skills as $skill) {
                $requiredSkills[$skill] = ($requiredSkills[$skill] ?? 0) + 1;
            }
        });

        $jobIds = $employer->jobListings()->pluck('id');
        $applicantSkills = [];
        JobApplication::whereIn('job_listing_id', $jobIds)->with('user')->get()->each(function ($app) use (&$applicantSkills) {
            if (!$app->user || !is_array($app->user->skills)) return;
            foreach ($app->user->skills as $skill) {
                $applicantSkills[$skill] = ($applicantSkills[$skill] ?? 0) + 1;
            }
        });

        $gaps = [];
        foreach ($requiredSkills as $skill => $required) {
            $available = $applicantSkills[$skill] ?? 0;
            $gaps[] = [
                'skill'     => $skill,
                'required'  => $required,
                'available' => $available,
            ];
        }

        usort($gaps, fn($a, $b) => ($b['required'] - $b['available']) <=> ($a['required'] - $a['available']));
        return array_slice($gaps, 0, 8);
    }
}
