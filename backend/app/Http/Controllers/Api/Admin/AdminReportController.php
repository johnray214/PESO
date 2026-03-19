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
use Illuminate\Validation\Rule;

class AdminReportController extends Controller
{
    /**
     * List all previously generated reports (paginated).
     * GET /admin/reports
     */
    public function index()
    {
        $reports = Report::with('generator:id,first_name,last_name')
            ->orderByDesc('created_at')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data'    => $reports,
        ]);
    }

    /**
     * Generate a report, store a record, and return the data rows.
     * POST /admin/reports
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'type'          => ['required', Rule::in(['placement','registration','skills','events','employer','skillmatch','feedback'])],
            'date_from'     => 'nullable|date',
            'date_to'       => 'nullable|date|after_or_equal:date_from',
            'group_by'      => 'nullable|string|max:50',
            'columns'       => 'nullable|array',
            'export_format' => ['nullable', Rule::in(['pdf','xlsx'])],
            // Filters are free-form so we accept them as an array without strict shape validation
            'filters'       => 'nullable|array',
        ]);

        // Save the report record so admins can see it was run
        $validated['generated_by'] = $request->user()->id;
        $report = Report::create([
            'type'          => $validated['type'],
            'date_from'     => $validated['date_from'] ?? null,
            'date_to'       => $validated['date_to'] ?? null,
            'group_by'      => $validated['group_by'] ?? 'Month',
            'columns'       => $validated['columns'] ?? [],
            'export_format' => $validated['export_format'] ?? 'xlsx',
            'generated_by'  => $validated['generated_by'],
        ]);

        // Fetch actual data rows for the preview
        $dateFrom = $validated['date_from'] ?? null;
        $dateTo   = $validated['date_to']   ?? null;
        $filters  = $validated['filters']   ?? [];

        $data = $this->fetchReportData($validated['type'], $dateFrom, $dateTo, $filters);

        return response()->json([
            'success' => true,
            'report'  => $report,
            'data'    => $data,
        ], 201);
    }

    /**
     * Show a single saved report.
     * GET /admin/reports/{id}
     */
    public function show($id)
    {
        $report = Report::with('generator:id,first_name,last_name')->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $report,
        ]);
    }

    /**
     * Delete a saved report.
     * DELETE /admin/reports/{id}
     */
    public function destroy($id)
    {
        Report::findOrFail($id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Report deleted successfully.',
        ]);
    }

    /**
     * Export a report as Excel or PDF (returns binary blob).
     * POST /admin/reports/export
     */
    public function export(Request $request)
    {
        $validated = $request->validate([
            'type'     => ['required', Rule::in(['placement','registration','skills','events','employer','skillmatch','feedback'])],
            'format'   => ['required', Rule::in(['pdf','xlsx'])],
            'date_from'=> 'nullable|date',
            'date_to'  => 'nullable|date|after_or_equal:date_from',
            'columns'  => 'nullable|array',
            'filters'  => 'nullable|array',
        ]);

        $dateFrom = $validated['date_from'] ?? null;
        $dateTo   = $validated['date_to']   ?? null;
        $filters  = $validated['filters']   ?? [];

        $data = $this->fetchReportData($validated['type'], $dateFrom, $dateTo, $filters);

        // Filter columns if requested
        $columns = $validated['columns'] ?? [];
        if (!empty($columns)) {
            $data = $data->map(fn ($row) => collect($row)->only($columns)->all());
        }

        if ($validated['format'] === 'xlsx') {
            return $this->exportExcel($data, $validated['type']);
        }

        return $this->exportPdf($data, $validated['type']);
    }

    // ──────────────────────────────────────────────
    // PRIVATE: Data fetchers
    // ──────────────────────────────────────────────

    private function fetchReportData(string $type, ?string $from, ?string $to, array $filters)
    {
        return match ($type) {
            'placement'    => $this->getPlacementData($from, $to, $filters),
            'registration' => $this->getRegistrationData($from, $to, $filters),
            'skills'       => $this->getSkillsData($from, $to, $filters),
            'events'       => $this->getEventsData($from, $to, $filters),
            'employer'     => $this->getEmployerData($from, $to, $filters),
            'skillmatch'   => $this->getSkillMatchData($from, $to, $filters),
            'feedback'     => $this->getFeedbackData($from, $to, $filters),
            default        => collect([]),
        };
    }

    private function getPlacementData(?string $from, ?string $to, array $filters)
    {
        $query = Application::with(['jobseeker:id,first_name,last_name', 'jobListing.employer:id,company_name'])
            ->where('status', 'hired');

        if ($from && $to) $query->whereBetween('applied_at', [$from, $to]);
        if (!empty($filters['status']))   $query->where('status', $filters['status']);
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

    private function getRegistrationData(?string $from, ?string $to, array $filters)
    {
        $jobseekerQuery = Jobseeker::query();
        $employerQuery  = Employer::query();

        if ($from && $to) {
            $jobseekerQuery->whereBetween('created_at', [$from, $to]);
            $employerQuery->whereBetween('created_at',  [$from, $to]);
        }
        if (!empty($filters['city'])) {
            $jobseekerQuery->where('city', $filters['city']);
            $employerQuery->where('city',  $filters['city']);
        }

        $type = $filters['regType'] ?? '';

        $rows = collect();

        if ($type === '' || $type === 'Jobseeker') {
            $rows = $rows->merge($jobseekerQuery->get()->map(fn ($js) => [
                'month' => $js->created_at->format('F'),
                'name'  => $js->full_name,
                'type'  => 'Jobseeker',
                'city'  => $js->city,
                'skills'=> $js->skills ?? '—',
                'date'  => $js->created_at->format('M d'),
            ]));
        }

        if ($type === '' || $type === 'Employer') {
            $rows = $rows->merge($employerQuery->get()->map(fn ($emp) => [
                'month' => $emp->created_at->format('F'),
                'name'  => $emp->company_name,
                'type'  => 'Employer',
                'city'  => $emp->city,
                'skills'=> $emp->industry ?? '—',
                'date'  => $emp->created_at->format('M d'),
            ]));
        }

        return $rows->sortBy('date')->values();
    }

    private function getSkillsData(?string $from, ?string $to, array $filters)
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

        return $query->get()->map(fn ($row) => [
            'skill'    => $row->skill,
            'supply'   => $row->supply_count,
            'demand'   => 0, // calculate from job postings if available
            'gap'      => '—',
            'trend'    => '—',
            'postings' => JobListing::where('required_skills', 'like', '%'.$row->skill.'%')->count(),
        ]);
    }

    private function getEventsData(?string $from, ?string $to, array $filters)
    {
        $query = Event::query();

        if ($from && $to) $query->whereBetween('event_date', [$from, $to]);
        if (!empty($filters['eventType']))   $query->where('type',   $filters['eventType']);
        if (!empty($filters['eventStatus'])) $query->where('status', $filters['eventStatus']);

        return $query->get()->map(fn ($e) => [
            'title'    => $e->title,
            'type'     => $e->type,
            'date'     => $e->event_date?->format('M d'),
            'location' => $e->location,
            'slots'    => $e->slots,
            'attended' => $e->attended ?? 0,
            'status'   => $e->status,
        ]);
    }

    private function getEmployerData(?string $from, ?string $to, array $filters)
    {
        $query = Employer::query();

        if ($from && $to) $query->whereBetween('created_at', [$from, $to]);
        if (!empty($filters['verificationStatus'])) $query->where('status',   $filters['verificationStatus']);
        if (!empty($filters['industry']))           $query->where('industry', $filters['industry']);

        return $query->get()->map(fn ($emp) => [
            'company'            => $emp->company_name,
            'industry'           => $emp->industry,
            'city'               => $emp->city,
            'verificationStatus' => ucfirst($emp->status),
            'vacancies'          => $emp->jobListings()->where('status', 'open')->count(),
            'date'               => $emp->created_at->format('M d'),
        ]);
    }

    private function getSkillMatchData(?string $from, ?string $to, array $filters)
    {
        // Returns a collection (not a single aggregate) so the table can render rows
        $query = Application::with(['jobseeker:id,first_name,last_name', 'jobListing'])
            ->whereNotNull('match_score');

        if ($from && $to) $query->whereBetween('applied_at', [$from, $to]);
        if (!empty($filters['minMatch']))    $query->where('match_score', '>=', (int) $filters['minMatch']);
        if (!empty($filters['jobCategory'])) {
            $query->whereHas('jobListing', fn ($q) => $q->where('category', $filters['jobCategory']));
        }

        return $query->get()->map(fn ($app) => [
            'name'       => $app->jobseeker?->full_name,
            'topSkill'   => $app->jobseeker?->top_skill ?? '—',
            'matchScore' => $app->match_score,
            'bestFor'    => $app->jobListing?->title ?? '—',
            'city'       => $app->jobseeker?->city ?? '—',
        ]);
    }

    private function getFeedbackData(?string $from, ?string $to, array $filters)
    {
        $query = Feedback::query();

        if ($from && $to) $query->whereBetween('created_at', [$from, $to]);
        if (!empty($filters['rating']))      $query->where('rating',         (int) $filters['rating']);
        if (!empty($filters['submittedBy'])) $query->where('submitter_type', $filters['submittedBy']);

        return $query->get()->map(fn ($fb) => [
            'name'     => $fb->submitter_name,
            'type'     => $fb->submitter_type,
            'rating'   => $fb->rating,
            'comment'  => $fb->comment,
            'category' => $fb->category ?? '—',
            'date'     => $fb->created_at->format('M d'),
        ]);
    }

    // ──────────────────────────────────────────────
    // PRIVATE: Export helpers
    // ──────────────────────────────────────────────

    private function exportExcel($data, string $type)
    {
        // Use maatwebsite/excel or spatie/simple-excel — example uses simple-excel
        $filename = "{$type}_report_" . now()->format('Ymd_His') . '.xlsx';

        // Example with spatie/simple-excel:
        // return SimpleExcelWriter::streamDownload($filename)
        //     ->addRows($data->toArray())
        //     ->toBrowser();

        // Placeholder until the package is wired in:
        return response()->json(['success' => false, 'message' => 'Excel export not yet implemented.'], 501);
    }

    private function exportPdf($data, string $type)
    {
        // Use barryvdh/laravel-dompdf or similar
        $filename = "{$type}_report_" . now()->format('Ymd_His') . '.pdf';

        // Example with Dompdf:
        // $pdf = PDF::loadView('reports.generic', ['rows' => $data, 'type' => $type]);
        // return $pdf->download($filename);

        return response()->json(['success' => false, 'message' => 'PDF export not yet implemented.'], 501);
    }
}