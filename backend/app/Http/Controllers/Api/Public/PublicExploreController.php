<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Models\Employer;
use App\Models\JobListing;
use App\Support\PublicStorageUrl;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Aggregated discovery data for the mobile app Explore tab.
 *
 * @see GET /api/public/explore
 */
class PublicExploreController extends Controller
{
    private const TOP_COMPANIES_LIMIT = 10;

    private const SKILLS_LIMIT = 15;

    private const FEATURED_JOBS_LIMIT = 8;

    /** @var list<int> ARGB accent colors for company cards (Flutter Color.value) */
    private const ACCENT_PALETTE = [
        0xFF2563EB,
        0xFF7C3AED,
        0xFF059669,
        0xFFDC2626,
        0xFFEA580C,
        0xFF0891B2,
        0xFFDB2777,
        0xFFCA8A04,
    ];

    public function __invoke(Request $request)
    {
        $weekAgo = now()->subDays(7)->startOfDay();

        $totalOpen = JobListing::query()->open()->count();

        $activeEmployers = (int) DB::table('job_listings')
            ->where('status', 'open')
            ->whereNull('deleted_at')
            ->selectRaw('COUNT(DISTINCT employer_id) as explore_employer_count')
            ->value('explore_employer_count');

        $newThisWeek = JobListing::query()
            ->open()
            ->where('posted_date', '>=', $weekAgo)
            ->count();

        $topCompanies = $this->buildTopCompanies($request, $totalOpen);

        $inDemandSkills = $this->buildInDemandSkills();

        $sectors = $this->buildSectorsByType();

        $industries = $this->buildIndustriesByEmployer();

        $featuredJobs = $this->buildFeaturedJobs();

        return response()->json([
            'success' => true,
            'data' => [
                'snapshot' => [
                    'new_jobs_this_week' => $newThisWeek,
                    'active_employers' => $activeEmployers,
                    'total_open_positions' => $totalOpen,
                ],
                'top_companies' => $topCompanies,
                'in_demand_skills' => $inDemandSkills,
                'industries' => $industries,
                'sectors' => $sectors,
                'featured_jobs' => $featuredJobs,
            ],
        ]);
    }

    /**
     * @return list<array{name: string, initial: string, photo_url: ?string, job_count: int, color: int}>
     */
    private function buildTopCompanies(Request $request, int $totalOpen): array
    {
        if ($totalOpen === 0) {
            return [];
        }

        $rows = JobListing::query()
            ->open()
            ->selectRaw('employer_id, COUNT(*) as job_count')
            ->groupBy('employer_id')
            ->orderByDesc('job_count')
            ->limit(self::TOP_COMPANIES_LIMIT)
            ->get();

        if ($rows->isEmpty()) {
            return [];
        }

        $employerIds = $rows->pluck('employer_id')->filter()->unique()->values();
        $employers = Employer::query()
            ->whereIn('id', $employerIds)
            ->get(['id', 'company_name', 'photo'])
            ->keyBy('id');

        $out = [];
        foreach ($rows as $row) {
            $emp = $employers->get($row->employer_id);
            $name = $emp?->company_name ?? 'Employer';
            $name = trim($name) !== '' ? $name : 'Employer';
            $initial = mb_strtoupper(mb_substr($name, 0, 1));
            $photoPath = $emp?->photo;
            $photoUrl = ($photoPath !== null && $photoPath !== '')
                ? PublicStorageUrl::fromRequest($request, $photoPath)
                : null;

            $out[] = [
                'name' => $name,
                'initial' => $initial,
                'photo_url' => $photoUrl,
                'job_count' => (int) $row->job_count,
                'color' => $this->accentColorForEmployerId($row->employer_id),
            ];
        }

        return $out;
    }

    /**
     * @return list<array{name: string, job_count: int}>
     */
    private function buildInDemandSkills(): array
    {
        $rows = DB::table('job_skills')
            ->join('job_listings', 'job_skills.job_listing_id', '=', 'job_listings.id')
            ->where('job_listings.status', 'open')
            ->whereNull('job_listings.deleted_at')
            ->selectRaw('job_skills.skill as name, COUNT(*) as job_count')
            ->groupBy('job_skills.skill')
            ->havingRaw('job_skills.skill IS NOT NULL AND job_skills.skill != ""')
            ->orderByDesc('job_count')
            ->limit(self::SKILLS_LIMIT)
            ->get();

        return $rows->map(fn ($r) => [
            'name' => (string) $r->name,
            'job_count' => (int) $r->job_count,
        ])->all();
    }

    /**
     * Employer industry (BPO, Retail, …) from open listings.
     *
     * @return list<array{name: string, job_count: int}>
     */
    private function buildIndustriesByEmployer(): array
    {
        $rows = DB::table('job_listings')
            ->join('employers', 'job_listings.employer_id', '=', 'employers.id')
            ->where('job_listings.status', 'open')
            ->whereNull('job_listings.deleted_at')
            ->whereNull('employers.deleted_at')
            ->selectRaw(
                'COALESCE(NULLIF(TRIM(employers.industry), ""), "Other") as name, COUNT(*) as job_count'
            )
            ->groupBy(DB::raw('COALESCE(NULLIF(TRIM(employers.industry), ""), "Other")'))
            ->orderByDesc('job_count')
            ->limit(12)
            ->get();

        return $rows
            ->map(fn ($r) => [
                'name' => (string) $r->name,
                'job_count' => (int) $r->job_count,
            ])
            ->filter(fn (array $s) => $s['job_count'] > 0)
            ->values()
            ->all();
    }

    /**
     * @return list<array{name: string, job_count: int}>
     */
    private function buildSectorsByType(): array
    {
        $rows = JobListing::query()
            ->open()
            ->selectRaw('type as name, COUNT(*) as job_count')
            ->groupBy('type')
            ->orderByDesc('job_count')
            ->get();

        return $rows
            ->map(fn ($r) => [
                'name' => trim((string) ($r->name ?? '')),
                'job_count' => (int) $r->job_count,
            ])
            ->filter(fn (array $s) => $s['name'] !== '' && $s['job_count'] > 0)
            ->values()
            ->all();
    }

    /**
     * Same JSON shape as paginated /public/jobs items (Eloquent + relations).
     *
     * @return list<mixed>
     */
    private function buildFeaturedJobs(): array
    {
        $jobs = JobListing::with(['employer', 'skills'])
            ->open()
            ->orderByDesc('posted_date')
            ->limit(self::FEATURED_JOBS_LIMIT)
            ->get();

        foreach ($jobs as $job) {
            $job->setAttribute('match_percentage', 0);
        }

        return $jobs->values()->all();
    }

    private function accentColorForEmployerId(?int $employerId): int
    {
        if ($employerId === null || $employerId <= 0) {
            return 0xFF3B82F6;
        }

        $idx = abs(crc32((string) $employerId)) % count(self::ACCENT_PALETTE);

        return self::ACCENT_PALETTE[$idx];
    }
}
