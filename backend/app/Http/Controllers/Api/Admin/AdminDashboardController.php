<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Employer;
use App\Models\Event;
use App\Models\JobApplication;
use App\Models\JobListing;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminDashboardController extends Controller
{
    public function index(Request $request)
    {
        $totalApplicants = User::count();
        $totalEmployers  = Employer::where('status', 'active')->count();
        $totalPlacements = User::where('peso_status', 'placed')->orWhere('peso_status', 'hired')->count();
        $activeJobs      = JobListing::where('status', 'open')->count();

        $prevApplicants  = User::where('created_at', '<', now()->subMonth())->count();
        $prevEmployers   = Employer::where('status', 'active')->where('created_at', '<', now()->subMonth())->count();

        $placementRate = $totalApplicants > 0
            ? round(($totalPlacements / $totalApplicants) * 100, 1)
            : 0;

        $stats = [
            [
                'label'    => 'Total Applicants',
                'value'    => $totalApplicants,
                'sub'      => 'Registered job seekers',
                'trendVal' => $prevApplicants > 0
                    ? round((($totalApplicants - $prevApplicants) / $prevApplicants) * 100, 1)
                    : 0,
                'trendUp'  => $totalApplicants >= $prevApplicants,
            ],
            [
                'label'    => 'Active Employers',
                'value'    => $totalEmployers,
                'sub'      => 'Verified companies',
                'trendVal' => $prevEmployers > 0
                    ? round((($totalEmployers - $prevEmployers) / $prevEmployers) * 100, 1)
                    : 0,
                'trendUp'  => $totalEmployers >= $prevEmployers,
            ],
            [
                'label'    => 'Total Placements',
                'value'    => $totalPlacements,
                'sub'      => 'Placed or hired',
                'trendVal' => 0,
                'trendUp'  => true,
            ],
            [
                'label'    => 'Placement Rate',
                'value'    => "{$placementRate}%",
                'sub'      => 'Of registered applicants',
                'trendVal' => 0,
                'trendUp'  => true,
            ],
        ];

        $registrationChart = $this->getMonthlyRegistrations();
        $placementChart    = $this->getMonthlyPlacements();

        $trendingJobs   = $this->getTrendingJobs();
        $trendingSkills = $this->getTrendingSkills();

        $recentApplicants = User::with('applications.jobListing.employer')
            ->latest()
            ->take(5)
            ->get()
            ->map(fn($u) => [
                'id'          => $u->id,
                'name'        => $u->name,
                'location'    => $u->address ?? 'N/A',
                'skill'       => is_array($u->skills) && count($u->skills) > 0 ? $u->skills[0] : 'N/A',
                'job'         => optional($u->applications->first()?->jobListing)->title ?? 'N/A',
                'date'        => $u->created_at->format('M d, Y'),
                'status'      => $u->peso_status ?? 'processing',
            ]);

        $upcomingEvents = Event::whereIn('status', ['Upcoming', 'upcoming', 'Ongoing', 'ongoing'])
            ->where('event_date', '>=', now()->toDateString())
            ->orderBy('event_date')
            ->take(5)
            ->get()
            ->map(fn($e) => [
                'id'       => $e->id,
                'title'    => $e->title,
                'day'      => $e->event_date->format('d'),
                'month'    => strtoupper($e->event_date->format('M')),
                'date'     => $e->event_date->format('Y-m-d'),
                'location' => $e->location,
                'slots'    => $e->slots,
                'type'     => $e->event_type,
            ]);

        $topEmployers = Employer::withCount('jobListings')
            ->where('status', 'active')
            ->orderByDesc('total_hired')
            ->take(5)
            ->get()
            ->map(fn($emp) => [
                'id'        => $emp->id,
                'name'      => $emp->company_name,
                'industry'  => $emp->industry ?? 'N/A',
                'vacancies' => $emp->job_listings_count,
            ]);

        return response()->json([
            'success' => true,
            'data'    => compact(
                'stats', 'registrationChart', 'placementChart',
                'trendingJobs', 'trendingSkills', 'recentApplicants',
                'upcomingEvents', 'topEmployers'
            ),
        ]);
    }

    private function getMonthlyRegistrations(): array
    {
        $months = [];
        for ($i = 11; $i >= 0; $i--) {
            $date  = now()->subMonths($i);
            $label = $date->format('M');
            $months[] = [
                'label'      => $label,
                'jobseekers' => User::whereYear('created_at', $date->year)
                    ->whereMonth('created_at', $date->month)->count(),
                'employers'  => Employer::whereYear('created_at', $date->year)
                    ->whereMonth('created_at', $date->month)->count(),
            ];
        }
        return $months;
    }

    private function getMonthlyPlacements(): array
    {
        $months = [];
        for ($i = 11; $i >= 0; $i--) {
            $date  = now()->subMonths($i);
            $months[] = [
                'label'        => $date->format('M'),
                'placement'    => User::whereIn('peso_status', ['placed', 'hired'])
                    ->whereYear('updated_at', $date->year)
                    ->whereMonth('updated_at', $date->month)->count(),
                'registration' => User::whereYear('created_at', $date->year)
                    ->whereMonth('created_at', $date->month)->count(),
                'processing'   => User::where('peso_status', 'processing')
                    ->whereYear('updated_at', $date->year)
                    ->whereMonth('updated_at', $date->month)->count(),
                'rejection'    => User::where('peso_status', 'rejected')
                    ->whereYear('updated_at', $date->year)
                    ->whereMonth('updated_at', $date->month)->count(),
            ];
        }
        return $months;
    }

    private function getTrendingJobs(): array
    {
        return JobListing::withCount('applications')
            ->where('status', 'open')
            ->orderByDesc('applications_count')
            ->take(5)
            ->get()
            ->map(fn($j) => [
                'id'        => $j->id,
                'title'     => $j->title,
                'industry'  => $j->category ?? 'General',
                'vacancies' => $j->slots,
                'apps'      => $j->applications_count,
            ])
            ->toArray();
    }

    private function getTrendingSkills(): array
    {
        $users  = User::whereNotNull('skills')->pluck('skills');
        $counts = [];
        foreach ($users as $skills) {
            if (!is_array($skills)) continue;
            foreach ($skills as $skill) {
                $counts[$skill] = ($counts[$skill] ?? 0) + 1;
            }
        }
        arsort($counts);
        $result = [];
        foreach (array_slice($counts, 0, 8, true) as $name => $count) {
            $result[] = ['name' => $name, 'count' => $count];
        }
        return $result;
    }
}
