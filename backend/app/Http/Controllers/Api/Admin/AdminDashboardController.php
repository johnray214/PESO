<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\Employer;
use App\Models\Event;
use App\Models\JobListing;
use App\Models\Jobseeker;
use Illuminate\Support\Facades\DB;

class AdminDashboardController extends Controller
{
    public function index()
    {
        // ── Stat Cards ───────────────────────────────────────────────
        $totalJobseekers   = Jobseeker::count();
        $totalEmployers    = Employer::count();
        $totalJobListings  = JobListing::count();
        $totalPlacements   = Application::where('status', 'hired')->count();

        // Week-over-week helpers
        $weekAgo = now()->subWeek();
        $newJobseekers = Jobseeker::where('created_at', '>=', $weekAgo)->count();
        $newEmployers  = Employer::where('created_at',  '>=', $weekAgo)->count();
        $newListings   = JobListing::where('created_at','>=', $weekAgo)->count();
        $monthAgo      = now()->subMonth();
        $newPlacements = Application::where('status', 'hired')
                            ->where('updated_at', '>=', $monthAgo)->count();

        $stats = [
            [
                'label'    => 'Registered Jobseekers',
                'value'    => number_format($totalJobseekers),
                'sub'      => "+{$newJobseekers} this week",
                'trendVal' => $totalJobseekers > 0
                    ? round($newJobseekers / max($totalJobseekers - $newJobseekers, 1) * 100)
                    : 0,
                'trendUp'  => $newJobseekers > 0,
            ],
            [
                'label'    => 'Active Employers',
                'value'    => number_format($totalEmployers),
                'sub'      => "+{$newEmployers} this week",
                'trendVal' => $totalEmployers > 0
                    ? round($newEmployers / max($totalEmployers - $newEmployers, 1) * 100)
                    : 0,
                'trendUp'  => $newEmployers > 0,
            ],
            [
                'label'    => 'Job Vacancies',
                'value'    => number_format($totalJobListings),
                'sub'      => "+{$newListings} this week",
                'trendVal' => $totalJobListings > 0
                    ? round($newListings / max($totalJobListings - $newListings, 1) * 100)
                    : 0,
                'trendUp'  => $newListings > 0,
            ],
            [
                'label'    => 'Successful Placements',
                'value'    => number_format($totalPlacements),
                'sub'      => "+{$newPlacements} this month",
                'trendVal' => $totalPlacements > 0
                    ? round($newPlacements / max($totalPlacements - $newPlacements, 1) * 100)
                    : 0,
                'trendUp'  => $newPlacements > 0,
            ],
        ];

        // ── Registration Chart (monthly, current year) ───────────────
        $year = now()->year;
        $months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

        $jsMonthly = Jobseeker::selectRaw('MONTH(created_at) as m, COUNT(*) as cnt')
            ->whereYear('created_at', $year)
            ->groupBy('m')->pluck('cnt', 'm');
        $empMonthly = Employer::selectRaw('MONTH(created_at) as m, COUNT(*) as cnt')
            ->whereYear('created_at', $year)
            ->groupBy('m')->pluck('cnt', 'm');

        $registrationChart = collect(range(1, 12))->map(fn($m) => [
            'label'      => $months[$m - 1],
            'jobseekers' => (int)($jsMonthly[$m] ?? 0),
            'employers'  => (int)($empMonthly[$m] ?? 0),
        ]);

        // ── Placement Chart (monthly, current year) ──────────────────
        $appMonthly = Application::selectRaw('MONTH(updated_at) as m, status, COUNT(*) as cnt')
            ->whereYear('updated_at', $year)
            ->groupBy('m', 'status')
            ->get()
            ->groupBy('m');

        $placementChart = collect(range(1, 12))->map(function ($m) use ($months, $appMonthly) {
            $rows = $appMonthly->get($m, collect())->keyBy('status');
            return [
                'label'        => $months[$m - 1],
                'placement'    => (int)($rows['hired']->cnt      ?? 0),
                'processing'   => (int)($rows['processing']->cnt ?? 0),
                'registration' => (int)($rows['pending']->cnt    ?? 0),
                'rejection'    => (int)($rows['rejected']->cnt   ?? 0),
            ];
        });

        // ── Trending Jobs ─────────────────────────────────────────────
        $trendingJobs = JobListing::select(
    'job_listings.id',
    'job_listings.title',
    DB::raw('employers.industry'),
    DB::raw('COUNT(DISTINCT applications.id) as apps'),
    'job_listings.slots'                    // ← was vacancies
)
->leftJoin('applications', 'applications.job_listing_id', '=', 'job_listings.id')
->leftJoin('employers', 'employers.id', '=', 'job_listings.employer_id')
->where('job_listings.status', 'open')
->groupBy('job_listings.id', 'job_listings.title', 'employers.industry', 'job_listings.slots') // ← was vacancies
->orderByDesc('apps')
->limit(6)
->get()
->map(fn($j) => [
    'title'     => $j->title,
    'industry'  => $j->industry ?? 'General',
    'vacancies' => (int)$j->slots,          // ← was $j->vacancies
    'apps'      => (int)$j->apps,
]);

        // ── Trending Skills ───────────────────────────────────────────
        $trendingSkills = DB::table('job_skills')
            ->select('skill as name', DB::raw('COUNT(*) as count'))
            ->join('job_listings', 'job_listings.id', '=', 'job_skills.job_listing_id')
            ->where('job_listings.status', 'open')
            ->groupBy('skill')
            ->orderByDesc('count')
            ->limit(6)
            ->get()
            ->map(fn($s) => [
                'name'  => $s->name,
                'count' => (int)$s->count,
            ]);

        // ── Skill Gaps ────────────────────────────────────────────────
        // required = % of open jobs needing this skill
        // available = % of jobseekers who have it
        $totalOpenJobs   = max(JobListing::where('status', 'open')->count(), 1);
        $totalJobseekers = max($totalJobseekers, 1);

        $demandRaw = DB::table('job_skills')
            ->select('skill', DB::raw('COUNT(DISTINCT job_listing_id) as cnt'))
            ->join('job_listings', 'job_listings.id', '=', 'job_skills.job_listing_id')
            ->where('job_listings.status', 'open')
            ->groupBy('skill')
            ->orderByDesc('cnt')
            ->limit(6)
            ->get()->keyBy('skill');

        $supplyRaw = DB::table('jobseeker_skills')
            ->select('skill', DB::raw('COUNT(DISTINCT jobseeker_id) as cnt'))
            ->whereIn('skill', $demandRaw->keys())
            ->groupBy('skill')
            ->get()->keyBy('skill');

        $skillGaps = $demandRaw->map(fn($d, $skill) => [
            'skill'     => $skill,
            'required'  => min((int)round($d->cnt / $totalOpenJobs * 100), 100),
            'available' => min((int)round(($supplyRaw[$skill]->cnt ?? 0) / $totalJobseekers * 100), 100),
        ])->values();

        // ── Recent Applicants ─────────────────────────────────────────
        $recentApplicants = Application::with(['jobseeker', 'jobListing'])
            ->orderByDesc('applied_at')
            ->limit(5)
            ->get()
            ->map(fn($a) => [
                'name'        => $a->jobseeker->fullName(),
                'location'    => $a->jobseeker->city ?? '',
                'skill'       => $a->jobseeker->primary_skill ?? 'General',
                'job'         => $a->jobListing->title ?? '',
                'date'        => optional($a->applied_at)->format('M d'),
                'status'      => ucfirst($a->status),
                'statusClass' => strtolower($a->status),
            ]);

        // ── Upcoming Events ───────────────────────────────────────────
        $upcomingEvents = Event::where('event_date', '>=', now())
            ->orderBy('event_date')
            ->limit(3)
            ->get()
            ->map(fn($e) => [
                'day'      => $e->event_date->format('d'),
                'month'    => strtoupper($e->event_date->format('M')),
                'title'    => $e->title,
                'location' => $e->location ?? '',
                'slots'    => $e->slots ?? 0,
                'type'     => $e->type ?? 'Event',
            ]);

        // ── Top Employers ─────────────────────────────────────────────
        $topEmployers = Employer::select('employers.id', 'employers.company_name', 'employers.industry',
                DB::raw('COUNT(job_listings.id) as vacancies')
            )
            ->leftJoin('job_listings', function ($j) {
                $j->on('job_listings.employer_id', '=', 'employers.id')
                  ->where('job_listings.status', 'open');
            })
            ->where('employers.status', 'verified')
            ->groupBy('employers.id', 'employers.company_name', 'employers.industry')
            ->orderByDesc('vacancies')
            ->limit(4)
            ->get()
            ->map(fn($e) => [
                'name'      => $e->company_name,
                'industry'  => $e->industry ?? '',
                'vacancies' => (int)$e->vacancies,
            ]);

        return response()->json([
            'success' => true,
            'data' => [
                'stats'             => $stats,
                'registrationChart' => $registrationChart,
                'placementChart'    => $placementChart,
                'trendingJobs'      => $trendingJobs,
                'trendingSkills'    => $trendingSkills,
                'skillGaps'         => $skillGaps,
                'recentApplicants'  => $recentApplicants,
                'upcomingEvents'    => $upcomingEvents,
                'topEmployers'      => $topEmployers,
            ],
        ]);
    }
}