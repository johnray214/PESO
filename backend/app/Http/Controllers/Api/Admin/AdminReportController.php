<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Models\Application;
use App\Models\JobListing;
use App\Models\Jobseeker;
use App\Models\Employer;
use App\Models\JobseekerSkill;
use App\Models\Event;
use App\Models\Feedback;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AdminReportController extends Controller
{
    public function index()
    {
        $reports = Report::with('generator:id,first_name,last_name')
            ->orderByDesc('created_at')
            ->paginate(15);

        return response()->json(['success' => true, 'data' => $reports]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'type'          => ['required', Rule::in(['placement','registration','skills','events','employer','skillmatch','feedback'])],
            'date_from'     => 'nullable|date',
            'date_to'       => 'nullable|date|after_or_equal:date_from',
            'group_by'      => 'nullable|string|max:50',
            'columns'       => 'nullable|array',
            'export_format' => ['nullable', Rule::in(['pdf','xlsx'])],
            'filters'       => 'nullable|array',
        ]);

        $dateFrom = $validated['date_from'] ?? null;
        $dateTo   = $validated['date_to']   ?? null;
        $filters  = $validated['filters']   ?? [];

        $result = DB::transaction(function () use ($validated, $dateFrom, $dateTo, $filters, $request) {
            $report = Report::create([
                'type'          => $validated['type'],
                'date_from'     => $dateFrom,
                'date_to'       => $dateTo,
                'group_by'      => $validated['group_by']      ?? 'Month',
                'columns'       => $validated['columns']        ?? [],
                'export_format' => $validated['export_format'] ?? 'xlsx',
                'generated_by'  => $request->user()->id,
            ]);

            $data = $this->fetchReportData($validated['type'], $dateFrom, $dateTo, $filters);

            return [$report, $data];
        });

        [$report, $data] = $result;

        return response()->json(['success' => true, 'report' => $report, 'data' => $data], 201);
    }

    public function show($id)
    {
        $report = Report::with('generator:id,first_name,last_name')->findOrFail($id);

        return response()->json(['success' => true, 'data' => $report]);
    }

    public function destroy($id)
    {
        Report::findOrFail($id)->delete();

        return response()->json(['success' => true, 'message' => 'Report deleted successfully.']);
    }

    public function export(Request $request)
    {
        $validated = $request->validate([
            'type'      => ['required', Rule::in(['placement','registration','skills','events','employer','skillmatch','feedback'])],
            'format'    => ['required', Rule::in(['pdf','xlsx'])],
            'date_from' => 'nullable|date',
            'date_to'   => 'nullable|date|after_or_equal:date_from',
            'columns'   => 'nullable|array',
            'filters'   => 'nullable|array',
        ]);

        $dateFrom = $validated['date_from'] ?? null;
        $dateTo   = $validated['date_to']   ?? null;
        $filters  = $validated['filters']   ?? [];

        $data    = $this->fetchReportData($validated['type'], $dateFrom, $dateTo, $filters);
        $columns = $validated['columns'] ?? [];

        if (!empty($columns)) {
            $data = $data->map(fn ($row) => collect($row)->only($columns)->all());
        }

        return $validated['format'] === 'xlsx'
            ? $this->exportExcel($data, $validated['type'])
            : $this->exportPdf($data, $validated['type']);
    }

    // ── Central dispatcher ────────────────────────────────────────────────────

    private function fetchReportData(string $type, ?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        return match ($type) {
            'placement'    => $this->getPlacementData($from, $to, $filters),
            'registration' => $this->getRegistrationData($from, $to, $filters),
            'skills'       => $this->getSkillsData($from, $to, $filters),
            'events'       => $this->getEventsData($from, $to, $filters),
            'employer'     => $this->getEmployerData($from, $to, $filters),
            'skillmatch'   => $this->getSkillMatchData($from, $to, $filters),
            'feedback'     => $this->getFeedbackData($from, $to, $filters),
            default        => collect(),
        };
    }

    // ── Data fetchers ─────────────────────────────────────────────────────────

    private function getPlacementData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $query = Application::with([
            'jobseeker:id,first_name,last_name',
            'jobListing.employer:id,company_name,industry',
        ])->where('status', 'hired');

        if ($from && $to) $query->whereBetween('applied_at', [$from, $to]);
        if (!empty($filters['status']))   $query->where('status', strtolower($filters['status']));
        if (!empty($filters['industry'])) {
            $query->whereHas('jobListing.employer', fn ($q) => $q->where('industry', $filters['industry']));
        }

        return $query->get()->map(fn ($app) => [
            'month'    => $app->applied_at?->format('F'),
            'name'     => $app->jobseeker?->full_name,
            'company'  => $app->jobListing?->employer?->company_name,
            'position' => $app->jobListing?->title,
            'industry' => $app->jobListing?->employer?->industry,
            'status'   => ucfirst($app->status),
            'date'     => $app->applied_at?->format('M d'),
        ]);
    }

    private function getRegistrationData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $type = $filters['regType'] ?? '';
        $rows = collect();

        if ($type === '' || $type === 'Jobseeker') {
            $q = Jobseeker::query();
            if ($from && $to)          $q->whereBetween('created_at', [$from, $to]);
            // ✅ FIXED: no city column on jobseekers — filter/display using address
            if (!empty($filters['city'])) $q->where('address', 'like', '%' . $filters['city'] . '%');

            $rows = $rows->merge(
                $q->get()->map(fn ($js) => [
                    'month'  => $js->created_at->format('F'),
                    'name'   => $js->full_name,
                    'type'   => 'Jobseeker',
                    'city'   => $js->address ?? '—',
                    // ✅ FIXED: flatten skills to a comma-separated string
                    //    $js->skills was returning the raw relationship object
                    'skills' => $js->skills()->exists()
                        ? $js->skills()->pluck('skill')->implode(', ')
                        : '—',
                    'date'   => $js->created_at->format('M d'),
                ])
            );
        }

        if ($type === '' || $type === 'Employer') {
            $q = Employer::query();
            if ($from && $to)          $q->whereBetween('created_at', [$from, $to]);
            if (!empty($filters['city'])) $q->where('city', $filters['city']);

            $rows = $rows->merge(
                $q->get()->map(fn ($emp) => [
                    'month'  => $emp->created_at->format('F'),
                    'name'   => $emp->company_name,
                    'type'   => 'Employer',
                    'city'   => $emp->city ?? '—',
                    'skills' => $emp->industry ?? '—',
                    'date'   => $emp->created_at->format('M d'),
                ])
            );
        }

        return $rows->sortBy('date')->values();
    }

    private function getSkillsData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $query = JobseekerSkill::selectRaw('skill, COUNT(*) as supply_count')
            ->groupBy('skill')
            ->orderByDesc('supply_count')
            ->limit(20);

        if ($from && $to) {
            $query->whereHas('jobseeker', fn ($q) => $q->whereBetween('created_at', [$from, $to]));
        }
        if (!empty($filters['skillCategory'])) {
            $query->where('category', $filters['skillCategory']);
        }

        return $query->get()->map(function ($row) {
            // ✅ FIXED: job_listings has no skills column
            //    match skill name against title + description instead
            $postings = JobListing::where(function ($q) use ($row) {
                $q->where('title', 'like', '%' . $row->skill . '%')
                  ->orWhere('description', 'like', '%' . $row->skill . '%');
            })->count();
            $totalPostings = JobListing::count() ?: 1;
            $demand        = (int) min(100, round(($postings / $totalPostings) * 100));

            return [
                'skill'    => $row->skill,
                'demand'   => $demand,
                'supply'   => $row->supply_count,
                'gap'      => ($demand - $row->supply_count) . '%',
                'trend'    => '—',
                'postings' => $postings,
            ];
        });
    }

    private function getEventsData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $query = Event::query();
        if ($from && $to)                    $query->whereBetween('event_date', [$from, $to]);
        if (!empty($filters['eventType']))   $query->where('type',   $filters['eventType']);
        if (!empty($filters['eventStatus'])) $query->where('status', $filters['eventStatus']);

        return $query->get()->map(fn ($e) => [
            'title'    => $e->title,
            'type'     => $e->type,
            'date'     => $e->event_date?->format('M d'),
            'location' => $e->location,
            'slots'    => $e->slots,
            'attended' => $e->attended ?? 0,
            'status'   => ucfirst($e->status),  // ✅ FIXED: ensure capital first letter
        ]);
    }

    private function getEmployerData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        // withTrashed() so soft-deleted (rejected/suspended) employers still appear in reports
        $query = Employer::withTrashed();
        if ($from && $to)                               $query->whereBetween('created_at', [$from, $to]);
        if (!empty($filters['verificationStatus']))     $query->where('status', strtolower($filters['verificationStatus']));
        if (!empty($filters['industry']))               $query->where('industry', $filters['industry']);

        return $query->get()->map(fn ($emp) => [
            'company'            => $emp->company_name,
            'industry'           => $emp->industry,
            'city'               => $emp->city,
            'verificationStatus' => ucfirst($emp->status),
            'vacancies'          => $emp->jobListings()->where('status', 'open')->count(),
            'date'               => $emp->created_at->format('M d'),
        ]);
    }

    private function getSkillMatchData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $query = Application::with([
            'jobseeker:id,first_name,last_name,address',
            'jobListing:id,title,category',
        ])->whereNotNull('match_score');

        if ($from && $to)                    $query->whereBetween('applied_at', [$from, $to]);
        if (!empty($filters['minMatch']))    $query->where('match_score', '>=', (int) $filters['minMatch']);
        if (!empty($filters['jobCategory'])) {
            $query->whereHas('jobListing', fn ($q) => $q->where('category', $filters['jobCategory']));
        }

        return $query->get()->map(fn ($app) => [
            'name'       => $app->jobseeker?->full_name,
            // ✅ FIXED: no top_skill column — derive from jobseeker_skills relationship
            //           no city column — jobseekers only has 'address'
            'topSkill'   => $app->jobseeker?->skills()->orderBy('id')->first()?->skill ?? '—',
            'matchScore' => $app->match_score,
            'bestFor'    => $app->jobListing?->title ?? '—',
            'city'       => $app->jobseeker?->address ?? '—',
        ]);
    }

    private function getFeedbackData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $query = Feedback::query();
        if ($from && $to)                     $query->whereBetween('created_at', [$from, $to]);
        if (!empty($filters['rating']))       $query->where('rating', (int) $filters['rating']);
        if (!empty($filters['submittedBy']))  $query->where('submitter_type', $filters['submittedBy']);

        return $query->get()->map(fn ($fb) => [
            'name'     => $fb->submitter_name,
            'type'     => $fb->submitter_type,
            'rating'   => $fb->rating,
            'comment'  => $fb->comment,
            'category' => $fb->category ?? '—',
            'date'     => $fb->created_at->format('M d'),
        ]);
    }

    // ── Export helpers ────────────────────────────────────────────────────────

    private function exportExcel(\Illuminate\Support\Collection $data, string $type)
    {
        $filename = "{$type}_report_" . now()->format('Ymd_His') . '.xlsx';

        // Uncomment once spatie/simple-excel is installed:
        // return \Spatie\SimpleExcel\SimpleExcelWriter::streamDownload($filename)
        //     ->addRows($data->toArray())
        //     ->toBrowser();

        return response()->json([
            'success' => false,
            'message' => 'Excel export not yet implemented. Install spatie/simple-excel or maatwebsite/excel.',
        ], 501);
    }

    private function exportPdf(\Illuminate\Support\Collection $data, string $type)
    {
        $filename = "{$type}_report_" . now()->format('Ymd_His') . '.pdf';

        // Uncomment once barryvdh/laravel-dompdf is installed:
        // $pdf = \PDF::loadView('reports.generic', ['rows' => $data, 'type' => $type]);
        // return $pdf->download($filename);

        return response()->json([
            'success' => false,
            'message' => 'PDF export not yet implemented. Install barryvdh/laravel-dompdf.',
        ], 501);
    }
}