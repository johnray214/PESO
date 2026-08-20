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
use App\Models\LegsFeedback;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Barryvdh\DomPDF\Facade\Pdf;
use Spatie\SimpleExcel\SimpleExcelWriter;

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
            'type'          => ['required', Rule::in(['placement','registration','skills','events','employer','jobposting','feedback'])],
            'date_from'     => 'nullable|date',
            'date_to'       => 'nullable|date|after_or_equal:date_from',
            'columns'       => 'nullable|array',
            'export_format' => ['nullable', Rule::in(['pdf','xlsx'])],
            'filters'       => 'nullable|array',
        ]);

        $dateFrom = $validated['date_from'] ?? null;
        $dateTo   = $validated['date_to']   ? $validated['date_to'] . ' 23:59:59' : null;
        $filters  = $validated['filters']   ?? [];

        $result = DB::transaction(function () use ($validated, $dateFrom, $dateTo, $filters, $request) {
            $report = Report::create([
                'type'          => $validated['type'],
                'date_from'     => $dateFrom,
                'date_to'       => $dateTo,
                'group_by'      => 'Month',
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
            'type'      => ['required', Rule::in(['placement','registration','skills','events','employer','jobposting','feedback'])],
            'format'    => ['required', Rule::in(['pdf','xlsx'])],
            'date_from' => 'nullable|date',
            'date_to'   => 'nullable|date|after_or_equal:date_from',
            'columns'   => 'nullable|array',
            'filters'   => 'nullable|array',
        ]);

        $dateFrom = $validated['date_from'] ?? null;
        $dateTo   = $validated['date_to']   ? $validated['date_to'] . ' 23:59:59' : null;
        $filters  = $validated['filters']   ?? [];

        $data = $this->fetchReportData($validated['type'], $dateFrom, $dateTo, $filters);
        $columns = $validated['columns'] ?? [];

        return $validated['format'] === 'pdf'
            ? $this->exportPdf($data, $validated['type'], $dateFrom, $validated['date_to'] ?? null, $filters)
            : $this->exportCsv(!empty($columns) ? $data->map(fn ($row) => collect($row)->only($columns)->all()) : $data, $validated['type']);
    }

    // â”€â”€ Central dispatcher â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    private function fetchReportData(string $type, ?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        return match ($type) {
            'placement'    => $this->getPlacementData($from, $to, $filters),
            'registration' => $this->getRegistrationData($from, $to, $filters),
            'skills'       => $this->getSkillsData($from, $to, $filters),
            'events'       => $this->getEventsData($from, $to, $filters),
            'employer'     => $this->getEmployerData($from, $to, $filters),
            'jobposting'   => $this->getJobPostingData($from, $to, $filters),
            'skillmatch'   => collect(),
            'feedback'     => $this->getFeedbackData($from, $to, $filters),
            default        => collect(),
        };
    }

    // â”€â”€ Data fetchers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    private function getPlacementData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $query = Application::with([
            'jobseeker:id,first_name,last_name',
            'jobListing.employer:id,company_name,industry',
        ]);

        if ($from && $to) $query->whereBetween('applied_at', [$from, $to]);
        if (!empty($filters['status']))   $query->where('status', strtolower($filters['status']));
        if (!empty($filters['industry'])) {
            $query->whereHas('jobListing.employer', fn ($q) => $q->where('industry', $filters['industry']));
        }
        if (!empty($filters['doleProgram'])) {
            $prog = strtolower(trim($filters['doleProgram']));
            if ($prog === 'all_dole' || $prog === 'dole') {
                $query->whereHas('jobListing', fn ($q) => $q->whereNotNull('program')->where('program', '!=', '')->where('program', '!=', 'none'));
            } elseif ($prog === 'regular' || $prog === 'non_dole') {
                $query->whereHas('jobListing', fn ($q) => $q->where(fn($sq) => $sq->whereNull('program')->orWhere('program', '')->orWhere('program', 'none')));
            } else {
                $query->whereHas('jobListing', fn ($q) => $q->where('program', $filters['doleProgram']));
            }
        }

        return $query->get()->map(fn ($app) => [
            'month'       => $app->applied_at?->format('F'),
            'name'        => $app->jobseeker?->full_name,
            'company'     => $app->jobListing?->employer?->company_name ?? ($app->jobListing?->program ? "DOLE ({$app->jobListing->program})" : '—'),
            'position'    => $app->jobListing?->title,
            'doleProgram' => $app->jobListing?->program ?: 'Regular / None',
            'industry'    => $app->jobListing?->employer?->industry ?? ($app->jobListing?->program ? 'Government / DOLE' : '—'),
            'status'      => ucfirst($app->status),
            'date'        => $app->applied_at?->format('M d, Y'),
        ]);
    }

    private function getRegistrationData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $type = $filters['regType'] ?? '';
        $rows = collect();

        if ($type === '' || $type === 'Jobseeker') {
            $q = Jobseeker::withTrashed();
            if ($from && $to)             $q->whereBetween('created_at', [$from, $to]);
            if (!empty($filters['city'])) $q->where('address', 'like', '%' . $filters['city'] . '%');

            $rows = $rows->merge(
                $q->get()->map(fn ($js) => [
                    'month'  => $js->created_at->format('F'),
                    'name'   => $js->full_name,
                    'sex'    => $js->sex ? ucfirst($js->sex) : '—',
                    'type'   => 'Jobseeker',
                    'city'   => $js->address ?? '—',
                    'skills' => $js->skills()->exists()
                        ? $js->skills()->pluck('skill')->implode(', ')
                        : '—',
                    'status' => 'Reviewing',
                    'date'   => $js->created_at->format('M d, Y'),
                ])
            );
        }

        if ($type === '' || $type === 'Employer') {
            $q = Employer::withTrashed();
            if ($from && $to)             $q->whereBetween('created_at', [$from, $to]);
            if (!empty($filters['city'])) $q->where('city', $filters['city']);

            $rows = $rows->merge(
                $q->get()->map(fn ($emp) => [
                    'month'  => $emp->created_at->format('F'),
                    'name'   => $emp->company_name,
                    'sex'    => '—',
                    'type'   => 'Employer',
                    'city'   => $emp->city ?? '—',
                    'skills' => $emp->industry ?? '—',
                    'status' => in_array($emp->status, ['pending', 'rejected']) ? 'Reviewing' : 'Processing',
                    'date'   => $emp->created_at->format('M d, Y'),
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
            $postings = JobListing::where(function ($q) use ($row) {
                $q->where('title', 'like', '%' . $row->skill . '%')
                  ->orWhere('description', 'like', '%' . $row->skill . '%')
                  ->orWhereHas('skills', fn ($sq) => $sq->where('skill', 'like', '%' . $row->skill . '%'));
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
        $query = Event::withCount('registrations');
        if ($from && $to)                    $query->whereBetween('event_date', [$from, $to]);
        if (!empty($filters['eventType']))   $query->where('type',   $filters['eventType']);
        if (!empty($filters['eventStatus'])) $query->where('status', strtolower($filters['eventStatus']));

        return $query->get()->map(fn ($e) => [
            'title'    => $e->title,
            'type'     => $e->type,
            'date'     => $e->event_date?->format('M d, Y'),
            'location' => $e->location,
            'slots'    => $e->max_participants ?? 0,
            'attended' => $e->registrations_count ?? 0,
            'status'   => ucfirst($e->status),
        ]);
    }

    private function getEmployerData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $query = Employer::withTrashed();
        if ($from && $to)                            $query->whereBetween('created_at', [$from, $to]);
        if (!empty($filters['verificationStatus']))  $query->where('status', strtolower($filters['verificationStatus']));
        if (!empty($filters['industry']))            $query->where('industry', $filters['industry']);

        return $query->get()->map(fn ($emp) => [
            'company'            => $emp->company_name,
            'employerType'       => ucfirst($emp->employer_type ?? 'local'),
            'industry'           => $emp->industry,
            'city'               => $emp->city,
            'verificationStatus' => ucfirst($emp->status),
            'vacancies'          => $emp->jobListings()->where('status', 'open')->count(),
            'date'               => $emp->created_at->format('M d, Y'),
        ]);
    }

    private function getJobPostingData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $query = JobListing::with(['employer:id,company_name,industry,employer_type'])
            ->withCount([
                'applications',
                'applications as hired_count' => fn ($q) => $q->whereIn('status', ['hired', 'placed']),
            ]);

        if ($from && $to) $query->whereBetween('created_at', [$from, $to]);
        if (!empty($filters['jobStatus']))
            $query->where('status', strtolower($filters['jobStatus']));
        if (!empty($filters['industry']))
            $query->whereHas('employer', fn ($q) => $q->where('industry', $filters['industry']));
        if (!empty($filters['doleProgram'])) {
            $prog = strtolower(trim($filters['doleProgram']));
            if ($prog === 'all_dole' || $prog === 'dole') {
                $query->whereNotNull('program')->where('program', '!=', '')->where('program', '!=', 'none');
            } elseif ($prog === 'regular' || $prog === 'non_dole') {
                $query->where(fn($q) => $q->whereNull('program')->orWhere('program', '')->orWhere('program', 'none'));
            } else {
                $query->where('program', $filters['doleProgram']);
            }
        }

        return $query->get()->map(fn ($jl) => [
            'id'                 => $jl->id,
            'title'              => $jl->title ?? '—',
            'company'            => $jl->employer?->company_name ?? ($jl->program ? 'DOLE / PESO Santiago' : '—'),
            'employerType'       => ($jl->is_overseas || ($jl->employer?->employer_type === 'overseas')) ? 'Overseas' : ($jl->program ? 'DOLE Program' : 'Local'),
            'doleProgram'        => $jl->program ?: 'Regular / None',
            'implementingAgency' => $jl->implementing_agency ?? ($jl->program ? 'DOLE Region II / PESO Santiago' : '—'),
            'duration'           => $jl->program_duration ? ($jl->program_duration . ' Days') : '—',
            'budget'             => $jl->program_budget ?? '—',
            'target'             => $jl->program_target ?? '—',
            'industry'           => $jl->employer?->industry ?? ($jl->program ? 'Public Employment / DOLE' : '—'),
            'vacancies'          => (int)($jl->vacancies ?? $jl->vacancy_count ?? $jl->slots ?? 1),
            'applicants'         => (int)($jl->applications_count ?? 0),
            'hired'              => (int)($jl->hired_count ?? 0),
            'status'             => ucfirst($jl->status ?? 'open'),
            'date'               => $jl->posted_date?->format('M d, Y') ?? $jl->created_at?->format('M d, Y') ?? '—',
            'month'              => $jl->posted_date?->format('F') ?? $jl->created_at?->format('F') ?? '—',
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
            'topSkill'   => $app->jobseeker?->skills()->orderBy('id')->first()?->skill ?? 'â€”',
            'matchScore' => $app->match_score,
            'bestFor'    => $app->jobListing?->title ?? 'â€”',
            'city'       => $app->jobseeker?->address ?? 'â€”',
        ]);
    }

    private function getFeedbackData(?string $from, ?string $to, array $filters): \Illuminate\Support\Collection
    {
        $query = LegsFeedback::query();
        if ($from && $to)                    $query->whereBetween('created_at', [$from, $to]);
        if (!empty($filters['rating']))      $query->where('rating_overall', (int) $filters['rating']);

        return $query->get()->map(fn ($fb) => [
            'name'     => trim($fb->first_name . ' ' . $fb->last_name),
            'type'     => 'Participant',
            'rating'   => $fb->rating_overall,
            'comment'  => $fb->remarks,
            'category' => $fb->program ?? 'â€”',
            'date'     => $fb->created_at->format('M d, Y'),
        ]);
    }

    // â”€â”€ Export helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /**
     * Export as CSV with Excel-compatible content type.
     * Works without any third-party library.
     */
    private function exportCsv(\Illuminate\Support\Collection $data, string $type)
    {
        $filename = "{$type}_report_" . now()->format('Ymd_His') . '.xlsx';
        $tmpPath  = tempnam(sys_get_temp_dir(), 'report_') . '.xlsx';

        $writer = SimpleExcelWriter::create($tmpPath);

        if ($data->isNotEmpty()) {
            $headers = array_keys($data->first());
            // Write header row manually
            $writer->addRow(array_combine(
                $headers,
                array_map(fn ($h) => ucwords(str_replace('_', ' ', $h)), $headers)
            ));
            foreach ($data as $row) {
                $writer->addRow($row);
            }
        }

        $writer->close();
        $xlsxContent = file_get_contents($tmpPath);
        @unlink($tmpPath);

        return response($xlsxContent, 200, [
            'Content-Type'        => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
            'Cache-Control'       => 'no-cache, no-store, must-revalidate',
            'Pragma'              => 'no-cache',
        ]);
    }

    private function exportPdf(\Illuminate\Support\Collection $data, string $type, ?string $from = null, ?string $to = null, array $filters = [])
    {
        $filename  = "{$type}_report_" . now()->format('Ymd_His') . '.pdf';
        
        if ($from && $to) {
            $generated = date('F d, Y', strtotime($from)) . ' to ' . date('F d, Y', strtotime($to));
        } elseif ($from) {
            $generated = 'Since ' . date('F d, Y', strtotime($from));
        } elseif ($to) {
            $generated = 'Up to ' . date('F d, Y', strtotime($to));
        } else {
            $generated = 'All Time (As of ' . now()->format('F Y') . ')';
        }
        
        $genFull   = now()->format('F d, Y H:i');
        $total     = $data->count();

        $intro = '';
        $sectionsHtml = '';

        switch ($type) {

            case 'placement':
                $isDoleFilter = !empty($filters['doleProgram']) && !in_array(strtolower(trim($filters['doleProgram'])), ['', 'regular', 'non_dole']);
                $hired      = $data->filter(fn($r) => in_array(strtolower($r['status'] ?? ''), ['hired','placed']))->count();
                $rejected   = $data->filter(fn($r) => strtolower($r['status'] ?? '') === 'rejected')->count();
                $processing = $total - $hired - $rejected;
                $hiredPct   = $total ? round($hired / $total * 100) : 0;
                $rejPct     = $total ? round($rejected / $total * 100) : 0;
                $procPct    = $total ? round($processing / $total * 100) : 0;

                if ($isDoleFilter) {
                    $doleCode = strtoupper(trim($filters['doleProgram']));
                    $progName = match($doleCode) {
                        'SPES'     => 'Special Program for Employment of Students (SPES)',
                        'GIP'      => 'Government Internship Program (GIP)',
                        'TUPAD'    => 'TUPAD (Tulong Panghanapbuhay)',
                        'JOBSTART' => 'JobStart Philippines',
                        default    => 'DOLE Special Employment Programs',
                    };
                    $shortProg = match($doleCode) {
                        'SPES'     => 'DOLE SPES',
                        'GIP'      => 'DOLE GIP',
                        'TUPAD'    => 'DOLE TUPAD',
                        'JOBSTART' => 'JobStart',
                        default    => 'DOLE Programs',
                    };

                    $title = "{$shortProg} Placement & Beneficiaries Report: {$generated}";
                    $intro = "This report covers beneficiary placements and internship assignments under <strong>{$progName}</strong> facilitated through PESO Santiago City and DOLE Region II. A total of <strong>{$total}</strong> applicant records were processed, resulting in <strong>{$hired}</strong> successful placements ({$hiredPct}% placement rate).";

                    $t1rows = '';
                    foreach ($data as $row) {
                        $t1rows .= $this->tableRow([
                            htmlspecialchars($row['name'] ?? ''),
                            htmlspecialchars($row['doleProgram'] ?? 'DOLE'),
                            htmlspecialchars($row['position'] ?? 'Intern / Beneficiary'),
                            htmlspecialchars($row['company'] ?? 'DOLE / PESO'),
                            $row['status'] ?? 'Processing',
                            $row['date'] ?? '—',
                        ]);
                    }

                    $t2rows = $this->tableRow(['Placed / Hired (Completed Acceptance)', $hired, $hiredPct . '%'])
                            . $this->tableRow(['Processing / Under Review', $processing, $procPct . '%'])
                            . $this->tableRow(['Rejected / Ineligible', $rejected, $rejPct . '%'])
                            . $this->tableRowTotal(['Total Applications', $total, '100%']);

                    $sectionsHtml .= $this->section('I. INTRODUCTION', $intro);
                    $sectionsHtml .= $this->section('II. PROGRAM APPLICANTS & BENEFICIARIES',
                        'Table 1 lists the registered program applicants and their corresponding assignment track and placement status.',
                        $this->table('Table 1. Applicants & Beneficiaries', ['Applicant Name', 'Program', 'Position / Track', 'Assigned Office / Station', 'Status', 'Date Applied'], $t1rows)
                    );
                    $sectionsHtml .= $this->section('III. BENEFICIARY PLACEMENT STATUS',
                        'Table 2 shows the breakdown of program applicants by current placement status.',
                        $this->table('Table 2. Placement Status Summary', ['Status', 'Beneficiaries', 'Percentage'], $t2rows)
                    );

                } else {
                    $byMonth = [];
                    foreach ($data as $row) { $m = $row['month'] ?? 'Unknown'; $byMonth[$m] = ($byMonth[$m] ?? 0) + 1; }

                    $byInd = [];
                    foreach ($data as $row) { $k = $row['industry'] ?? 'Unknown'; $byInd[$k] = ($byInd[$k] ?? 0) + 1; }
                    arsort($byInd);
                    $topInd = array_key_first($byInd) ?: 'General';

                    $title  = "Placement Report: {$generated}";
                    $intro  = "This report covers placement activities for the period ending {$generated}. PESO Santiago City facilitated a total of <strong>{$total}</strong> placement applications, out of which <strong>{$hired}</strong> applicants were successfully hired or placed, representing a placement rate of <strong>{$hiredPct}%</strong>.";

                    $t1rows = $this->tableRow(['Hired / Placed', $hired, $hiredPct . '%'])
                            . $this->tableRow(['Rejected',       $rejected, $rejPct . '%'])
                            . $this->tableRow(['Processing',     $processing, $procPct . '%'])
                            . $this->tableRowTotal(['Total', $total, '100%']);

                    $sectionsHtml .= $this->section('I. INTRODUCTION', $intro);
                    $sectionsHtml .= $this->section('II. PLACEMENT STATUS SUMMARY',
                        "Of the {$total} total applications recorded, {$hired} resulted in successful placements. The majority of placements were in the <strong>{$topInd}</strong> sector.",
                        $this->table('Table 1. Placement Status Summary', ['Status', 'No. of Applicants', 'Percentage'], $t1rows)
                    );

                    $t2rows = '';
                    foreach ($byMonth as $m => $cnt) {
                        $pct = $total ? round($cnt / $total * 100) : 0;
                        $t2rows .= $this->tableRow([$m, $cnt, $pct . '%']);
                    }
                    $t2rows .= $this->tableRowTotal(['Total', $total, '100%']);
                    $sectionsHtml .= $this->section('III. MONTHLY DISTRIBUTION',
                        "The following table shows the monthly breakdown of placement applications within the reporting period.",
                        $this->table('Table 2. Applications by Month', ['Month', 'No. of Applications', 'Percentage'], $t2rows)
                    );

                    $t3rows = '';
                    foreach (array_slice($byInd, 0, 10, true) as $ind => $cnt) {
                        $pct = $total ? round($cnt / $total * 100) : 0;
                        $t3rows .= $this->tableRow([$ind, $cnt, $pct . '%']);
                    }
                    $t3rows .= $this->tableRowTotal(['Total', $total, '100%']);
                    $sectionsHtml .= $this->section('IV. INDUSTRY BREAKDOWN',
                        "The table below presents the distribution of placements across industries.",
                        $this->table('Table 3. Placements by Industry', ['Industry', 'No. of Placements', 'Percentage'], $t3rows)
                    );
                }
                break;

            case 'registration':
                $jobseekers = $data->filter(fn($r) => ($r['type'] ?? '') === 'Jobseeker')->count();
                $employers  = $data->filter(fn($r) => ($r['type'] ?? '') === 'Employer')->count();
                $reviewing  = $data->filter(fn($r) => ($r['status'] ?? '') === 'Reviewing')->count();
                $processing = $data->filter(fn($r) => ($r['status'] ?? '') === 'Processing')->count();

                $jsPct   = $total ? round($jobseekers / $total * 100) : 0;
                $empPct  = $total ? round($employers  / $total * 100) : 0;
                $revPct  = $total ? round($reviewing  / $total * 100) : 0;
                $procPct = $total ? round($processing / $total * 100) : 0;

                $byMonth = [];
                foreach ($data as $row) { $m = $row['month'] ?? 'Unknown'; $byMonth[$m] = ($byMonth[$m] ?? 0) + 1; }

                $title = "Registration Report: {$generated}";
                $intro = "This report summarizes client registration data recorded in PESO Santiago City for the period ending {$generated}. A total of <strong>{$total}</strong> registrants were documented, comprising <strong>{$jobseekers}</strong> jobseekers ({$jsPct}%) and <strong>{$employers}</strong> employers ({$empPct}%).";

                $t1rows = $this->tableRow(['Jobseekers', $jobseekers, $jsPct . '%'])
                        . $this->tableRow(['Employers',  $employers,  $empPct . '%'])
                        . $this->tableRowTotal(['Total', $total, '100%']);

                $sectionsHtml .= $this->section('I. INTRODUCTION', $intro);
                $sectionsHtml .= $this->section('II. REGISTRATIONS BY TYPE',
                    "Through the PESO Employment Information System (PEIS), a total of {$total} registrations were processed.",
                    $this->table('Table 1. Registrations by Type', ['Type', 'Number of Registrants', 'Percentage'], $t1rows)
                );

                $t2rows = $this->tableRow(['Reviewing',  $reviewing,  $revPct . '%'])
                        . $this->tableRow(['Processing', $processing, $procPct . '%'])
                        . $this->tableRowTotal(['Total', $total, '100%']);
                $sectionsHtml .= $this->section('III. REGISTRATION STATUS',
                    "Of the total registrations, {$reviewing} are currently under review and {$processing} are active.",
                    $this->table('Table 2. Registration Status', ['Status', 'Number', 'Percentage'], $t2rows)
                );

                $t3rows = '';
                foreach ($byMonth as $m => $cnt) {
                    $pct = $total ? round($cnt / $total * 100) : 0;
                    $t3rows .= $this->tableRow([$m, $cnt, $pct . '%']);
                }
                $t3rows .= $this->tableRowTotal(['Total', $total, '100%']);
                $sectionsHtml .= $this->section('IV. MONTHLY REGISTRATION TREND',
                    "The following table shows the monthly distribution of new registrations.",
                    $this->table('Table 3. Registrations by Month', ['Month', 'No. of Registrants', 'Percentage'], $t3rows)
                );
                break;

            case 'jobposting':
                $isDoleFilter = !empty($filters['doleProgram']) && !in_array(strtolower(trim($filters['doleProgram'])), ['', 'regular', 'non_dole']);
                $open     = $data->filter(fn($r) => strtolower($r['status'] ?? '') === 'open')->count();
                $closed   = $data->filter(fn($r) => strtolower($r['status'] ?? '') !== 'open')->count();
                $totalVac = $data->sum(fn($r) => (int)($r['vacancies'] ?? 0));

                if ($isDoleFilter) {
                    $doleCode = strtoupper(trim($filters['doleProgram']));
                    $progName = match($doleCode) {
                        'SPES'     => 'Special Program for Employment of Students (SPES)',
                        'GIP'      => 'Government Internship Program (GIP)',
                        'TUPAD'    => 'TUPAD (Tulong Panghanapbuhay)',
                        'JOBSTART' => 'JobStart Philippines',
                        default    => 'DOLE Special Employment Programs',
                    };
                    $shortProg = match($doleCode) {
                        'SPES'     => 'DOLE SPES',
                        'GIP'      => 'DOLE GIP',
                        'TUPAD'    => 'DOLE TUPAD',
                        'JOBSTART' => 'JobStart',
                        default    => 'DOLE Programs',
                    };

                    $title = "{$shortProg} Program Report: {$generated}";

                    $totalSlots      = $data->sum(fn($r) => (int)($r['vacancies'] ?? 0));
                    $totalApplicants = $data->sum(fn($r) => (int)($r['applicants'] ?? 0));
                    $totalHired      = $data->sum(fn($r) => (int)($r['hired'] ?? 0));
                    $hireRate        = $totalSlots ? round($totalHired / $totalSlots * 100) : 0;
                    $remainingSlots  = max(0, $totalSlots - $totalHired);

                    // Table 1 — DOLE Program Tracks & Slots/Hires
                    $t1rows = '';
                    foreach ($data as $row) {
                        $t1rows .= $this->tableRow([
                            htmlspecialchars($row['title'] ?? ''),
                            htmlspecialchars($row['doleProgram'] ?? 'DOLE'),
                            htmlspecialchars($row['implementingAgency'] ?? 'DOLE / PESO Santiago'),
                            $row['vacancies'] ?? 0,
                            $row['applicants'] ?? 0,
                            $row['hired'] ?? 0,
                            $row['status'] ?? 'Open',
                            $row['date'] ?? '—',
                        ]);
                    }

                    // Table 2 — Track breakdown with hired / fill rate
                    $t2rows = '';
                    foreach ($data as $row) {
                        $vac  = (int)($row['vacancies'] ?? 0);
                        $app  = (int)($row['applicants'] ?? 0);
                        $hird = (int)($row['hired'] ?? 0);
                        $pct  = $vac ? round($hird / $vac * 100) : 0;
                        $t2rows .= $this->tableRow([
                            htmlspecialchars($row['title'] ?? 'Program Track'),
                            $vac,
                            $app,
                            $hird,
                            $pct . '%',
                        ]);
                    }
                    $t2rows .= $this->tableRowTotal(['Total', $totalSlots, $totalApplicants, $totalHired, $hireRate . '%']);

                    // Table 3 — Overall Program Summary
                    $t3rows = $this->tableRow(['Total Approved Slots / Target Beneficiaries', $totalSlots, '100%'])
                            . $this->tableRow(['Total Hired / Placed Beneficiaries', $totalHired, $hireRate . '%'])
                            . $this->tableRow(['Total Applicants Processed', $totalApplicants, '—'])
                            . $this->tableRow(['Remaining Open / Unfilled Slots', $remainingSlots, ($totalSlots ? round($remainingSlots / $totalSlots * 100) : 0) . '%'])
                            . $this->tableRow(['Active Program Tracks', $total . ' track(s)', '—']);

                    $sectionsHtml .= $this->section('I. INTRODUCTION',
                        "This report provides an official overview of the <strong>{$progName}</strong> administered by the Public Employment Service Office (PESO) Santiago City in coordination with the Department of Labor and Employment (DOLE Region II). For the reporting period <strong>{$generated}</strong>, a total of <strong>{$total}</strong> program tracks were facilitated with an aggregate of <strong>{$totalSlots}</strong> approved slots. A total of <strong>{$totalApplicants}</strong> applicant applications were received, of which <strong>{$totalHired}</strong> beneficiaries were successfully hired/placed (<strong>{$hireRate}%</strong> placement/fill rate), with <strong>{$remainingSlots}</strong> remaining open slots."
                    );
                    $sectionsHtml .= $this->section('II. PROGRAM TRACKS, SLOTS & HIRES',
                        'Table 1 outlines all registered DOLE program tracks, target slot allocations, applicants, total hired beneficiaries, and recruitment status.',
                        $this->table('Table 1. Program Tracks, Slots & Hires', ['Program Track / Position', 'Program', 'Implementing Agency', 'Approved Slots', 'Applicants', 'Total Hired', 'Status', 'Date Posted'], $t1rows)
                    );
                    $sectionsHtml .= $this->section('III. SLOT ALLOCATION & HIRING SUMMARY BY TRACK',
                        'Table 2 details the target slots versus actual hired beneficiaries per program track.',
                        $this->table('Table 2. Slot Allocation & Hires by Track', ['Program Track', 'Target Slots', 'Applicants', 'Total Hired', 'Fill Rate (%)'], $t2rows)
                    );
                    $sectionsHtml .= $this->section('IV. PROGRAM PLACEMENT & BENEFICIARY METRICS',
                        'Table 3 presents the overall beneficiary placement and hiring performance metrics.',
                        $this->table('Table 3. Program Beneficiary Summary', ['Metric', 'Count / Total', 'Percentage'], $t3rows)
                    );

                } else {
                    // Regular or Combined Job Posting Report
                    $byInd = [];
                    foreach ($data as $row) {
                        $k = $row['industry'] ?? 'General';
                        $byInd[$k] = ($byInd[$k] ?? 0) + (int)($row['vacancies'] ?? 0);
                    }
                    arsort($byInd);

                    $title = "Job Posting Report: {$generated}";

                    $totalSlots      = $data->sum(fn($r) => (int)($r['vacancies'] ?? 0));
                    $totalApplicants = $data->sum(fn($r) => (int)($r['applicants'] ?? 0));
                    $totalHired      = $data->sum(fn($r) => (int)($r['hired'] ?? 0));

                    // Table 1 — all listings
                    $t1rows = '';
                    $t2_filledRows = '';
                    foreach ($data as $row) {
                        $progType = ($row['doleProgram'] ?? '') !== 'Regular / None'
                            ? "DOLE ({$row['doleProgram']})"
                            : ($row['employerType'] ?? 'Local');

                        $tr = $this->tableRow([
                            htmlspecialchars($row['title'] ?? ''),
                            htmlspecialchars($row['company'] ?? ''),
                            $progType,
                            $row['industry'] ?? '—',
                            $row['vacancies'] ?? 0,
                            $row['applicants'] ?? 0,
                            $row['hired'] ?? 0,
                            $row['status'] ?? '—',
                            $row['date'] ?? '—',
                        ]);
                        $t1rows .= $tr;
                        if (strtolower($row['status'] ?? '') !== 'open') {
                            $t2_filledRows .= $tr;
                        }
                    }

                    // Table 2 — status summary
                    $t2rows = $this->tableRow(['Open / Active', $open,   $total ? round($open   / $total * 100) . '%' : '0%'])
                            . $this->tableRow(['Closed',        $closed, $total ? round($closed / $total * 100) . '%' : '0%'])
                            . $this->tableRowTotal(['Total', $total, '100%']);

                    // Table 3 — vacancies by industry
                    $t3rows = '';
                    foreach (array_slice($byInd, 0, 10, true) as $ind => $vac) {
                        $pct     = $totalVac ? round($vac / $totalVac * 100) : 0;
                        $t3rows .= $this->tableRow([$ind, $vac, $pct . '%']);
                    }
                    $t3rows .= $this->tableRowTotal(['Total', $totalVac, '100%']);

                    $sectionsHtml .= $this->section('I. INTRODUCTION',
                        "This report covers job listings posted through PESO Santiago City for the period <strong>{$generated}</strong>. A total of <strong>{$total}</strong> job listings were recorded with <strong>{$totalVac}</strong> total vacancies, <strong>{$totalApplicants}</strong> applicants, and <strong>{$totalHired}</strong> total hires. Of these listings, <strong>{$open}</strong> are currently open and accepting applicants, while <strong>{$closed}</strong> are filled out (closed)."
                    );
                    $sectionsHtml .= $this->section('II. ALL JOB LISTING DETAILS',
                        'Table 1 provides the complete list of job postings within the reporting period, including the hiring organization, program type, industry, number of vacancies, applicants, total hired, and current status.',
                        $this->table('Table 1. All Job Listings', ['Job Title', 'Company / Org', 'Program / Type', 'Industry', 'Vacancies', 'Applicants', 'Total Hired', 'Status', 'Date Posted'], $t1rows)
                    );
                    if ($closed > 0) {
                        $sectionsHtml .= $this->section('III. FILLED OUT (CLOSED) LISTINGS',
                            'Table 2 explicitly lists the job postings that have been filled out and closed.',
                            $this->table('Table 2. Closed Job Listings', ['Job Title', 'Company / Org', 'Program / Type', 'Industry', 'Vacancies', 'Applicants', 'Total Hired', 'Status', 'Date Posted'], $t2_filledRows)
                        );
                    }
                    $sectionsHtml .= $this->section($closed > 0 ? 'IV. LISTING STATUS SUMMARY' : 'III. LISTING STATUS SUMMARY',
                        'Table summary of job listings by their current status.',
                        $this->table('Listing Status Summary', ['Status', 'No. of Listings', 'Percentage'], $t2rows)
                    );
                    $sectionsHtml .= $this->section($closed > 0 ? 'V. VACANCIES BY INDUSTRY' : 'IV. VACANCIES BY INDUSTRY',
                        'Distribution of job vacancies across industry classifications.',
                        $this->table('Vacancies by Industry', ['Industry', 'Total Vacancies', 'Percentage'], $t3rows)
                    );
                }
                break;

            case 'employer':
                $verified  = $data->filter(fn($r) => strtolower($r['verificationStatus'] ?? '') === 'verified')->count();
                $pending   = $data->filter(fn($r) => strtolower($r['verificationStatus'] ?? '') === 'pending')->count();
                $rejected  = $data->filter(fn($r) => strtolower($r['verificationStatus'] ?? '') === 'rejected')->count();
                $suspended = $data->filter(fn($r) => strtolower($r['verificationStatus'] ?? '') === 'suspended')->count();
                $byInd = [];
                foreach ($data as $row) { $k = $row['industry'] ?? 'Unknown'; $byInd[$k] = ($byInd[$k] ?? 0) + 1; }
                arsort($byInd);

                $title = "Employer Report: {$generated}";
                $t1rows = $this->tableRow(['Verified',  $verified,  $total ? round($verified/$total*100).'%' : '0%'])
                        . $this->tableRow(['Pending',   $pending,   $total ? round($pending/$total*100).'%' : '0%'])
                        . $this->tableRow(['Rejected',  $rejected,  $total ? round($rejected/$total*100).'%' : '0%'])
                        . $this->tableRow(['Suspended', $suspended, $total ? round($suspended/$total*100).'%' : '0%'])
                        . $this->tableRowTotal(['Total', $total, '100%']);
                $sectionsHtml .= $this->section('I. INTRODUCTION',
                    "This report covers employer records registered with PESO Santiago City as of {$generated}. A total of <strong>{$total}</strong> employers are on record, with <strong>{$verified}</strong> verified and <strong>{$pending}</strong> currently pending verification."
                );
                $sectionsHtml .= $this->section('II. EMPLOYER VERIFICATION STATUS',
                    "Table 1 presents the breakdown of employer accounts by their verification status.",
                    $this->table('Table 1. Employer Verification Status', ['Status', 'Number of Employers', 'Percentage'], $t1rows)
                );
                $t2rows = '';
                foreach (array_slice($byInd, 0, 10, true) as $ind => $cnt) {
                    $t2rows .= $this->tableRow([$ind, $cnt, $total ? round($cnt/$total*100).'%' : '0%']);
                }
                $t2rows .= $this->tableRowTotal(['Total', $total, '100%']);
                $sectionsHtml .= $this->section('III. EMPLOYERS BY INDUSTRY',
                    "The following table shows the distribution of registered employers by industry classification.",
                    $this->table('Table 2. Employers by Industry', ['Industry', 'Number of Employers', 'Percentage'], $t2rows)
                );
                break;

            case 'events':
                $completed = $data->filter(fn($r) => strtolower($r['status'] ?? '') === 'completed')->count();
                $upcoming  = $data->filter(fn($r) => strtolower($r['status'] ?? '') === 'upcoming')->count();
                $totalSlots    = $data->sum(fn($r) => (int)($r['slots'] ?? 0));
                $totalAttended = $data->sum(fn($r) => (int)($r['attended'] ?? 0));
                $attendRate    = $totalSlots ? round($totalAttended / $totalSlots * 100) : 0;

                $title = "Events Report: {$generated}";
                $t1rows = $this->tableRow(['Completed', $completed, $total ? round($completed/$total*100).'%' : '0%'])
                        . $this->tableRow(['Upcoming',  $upcoming,  $total ? round($upcoming/$total*100).'%' : '0%'])
                        . $this->tableRowTotal(['Total', $total, '100%']);
                $t2rows = '';
                foreach ($data as $row) {
                    $t2rows .= $this->tableRow([
                        htmlspecialchars($row['title'] ?? ''),
                        $row['type'] ?? '',
                        $row['date'] ?? '',
                        $row['slots'] ?? 0,
                        $row['attended'] ?? 0,
                        ucfirst($row['status'] ?? ''),
                    ]);
                }
                $sectionsHtml .= $this->section('I. INTRODUCTION',
                    "PESO Santiago City organized a total of <strong>{$total}</strong> events during the period covered by this report. Of these, <strong>{$completed}</strong> have been completed with an overall attendance rate of <strong>{$attendRate}%</strong> ({$totalAttended} out of {$totalSlots} slots)."
                );
                $sectionsHtml .= $this->section('II. EVENT STATUS SUMMARY', '',
                    $this->table('Table 1. Event Status', ['Status', 'Number of Events', 'Percentage'], $t1rows)
                );
                $sectionsHtml .= $this->section('III. EVENT DETAILS', '',
                    $this->table('Table 2. Events Detail', ['Title', 'Type', 'Date', 'Slots', 'Attended', 'Status'], $t2rows)
                );
                break;

            case 'skills':
                $gapCount  = $data->filter(fn($r) => (int)($r['postings'] ?? 0) > (int)($r['supply'] ?? 0))->count();
                $overCount = $data->filter(fn($r) => (int)($r['supply'] ?? 0) > (int)($r['postings'] ?? 0))->count();
                $balCount  = $data->filter(fn($r) => (int)($r['supply'] ?? 0) === (int)($r['postings'] ?? 0))->count();
                $totalPostings = $data->sum(fn($r) => (int)($r['postings'] ?? 0));
                $totalSupply   = $data->sum(fn($r) => (int)($r['supply'] ?? 0));

                $title = 'Skills & Gaps Report: ' . $generated;

                $t1rows = '';
                foreach ($data as $row) {
                    $demand = (int)($row['postings'] ?? 0);
                    $supply = (int)($row['supply'] ?? 0);
                    if ($demand > $supply)      $status = 'Skill Gap';
                    elseif ($supply > $demand)  $status = 'Oversupplied';
                    else                        $status = 'Balanced';
                    $t1rows .= $this->tableRow([
                        htmlspecialchars($row['skill'] ?? ''),
                        $demand,
                        $supply,
                        $row['gap'] ?? '—',
                        $status,
                    ]);
                }

                $t2rows = $this->tableRow(['Skill Gap (Demand > Supply)', $gapCount, $total ? round($gapCount / $total * 100) . '%' : '0%'])
                        . $this->tableRow(['Oversupplied (Supply > Demand)', $overCount, $total ? round($overCount / $total * 100) . '%' : '0%'])
                        . $this->tableRow(['Balanced', $balCount, $total ? round($balCount / $total * 100) . '%' : '0%'])
                        . $this->tableRowTotal(['Total', $total, '100%']);

                $gapWord = $gapCount === 1 ? 'skill has' : 'skills have';
                $sectionsHtml .= $this->section('I. INTRODUCTION',
                    "This report presents a Skills and Labor Market Gap Analysis for PESO Santiago City covering the period <strong>{$generated}</strong>. A total of <strong>{$total}</strong> skills were tracked across registered jobseekers, with <strong>{$totalPostings}</strong> total job postings requiring these skills. Of the {$total} skills analyzed, <strong>{$gapCount}</strong> {$gapWord} higher employer demand than available jobseeker supply."
                );
                $sectionsHtml .= $this->section('II. SKILLS GAP BREAKDOWN',
                    'Table 1 lists every tracked skill with the number of job postings that require it (Demand) versus the number of registered jobseekers who possess it (Supply). A negative gap means more employers need the skill than jobseekers supply it.',
                    $this->table('Table 1. Skill Demand vs. Supply', ['Skill', 'Job Postings (Demand)', 'Jobseekers (Supply)', 'Gap', 'Status'], $t1rows)
                );
                $sectionsHtml .= $this->section('III. GAP CLASSIFICATION SUMMARY',
                    'Table 2 summarizes the skills by gap category.',
                    $this->table('Table 2. Gap Classification Summary', ['Classification', 'No. of Skills', 'Percentage'], $t2rows)
                );
                break;
            case 'feedback':
                $title = 'Feedback Report: ' . $generated;
                
                $fiveStarCount = $data->filter(fn($r) => (int)($r['rating'] ?? 0) === 5)->count();
                $avgRating = $total > 0 ? round($data->avg('rating'), 1) : 0;
                
                $t1rows = '';
                foreach ($data as $row) {
                    $t1rows .= $this->tableRow([
                        htmlspecialchars($row['name'] ?? ''),
                        $row['type'] ?? '',
                        ($row['rating'] ?? 0) . '★',
                        htmlspecialchars($row['comment'] ?? ''),
                        htmlspecialchars($row['category'] ?? ''),
                        $row['date'] ?? '',
                    ]);
                }
                
                $sectionsHtml .= $this->section('I. SUMMARY',
                    "This report summarizes feedback received by PESO Santiago City during the period <strong>{$generated}</strong>. A total of <strong>{$total}</strong> feedback entries were collected, with an average rating of <strong>{$avgRating}★</strong>. Of these, <strong>{$fiveStarCount}</strong> entries received a perfect 5-star rating."
                );
                $sectionsHtml .= $this->section('II. FEEDBACK DETAILS', '',
                    $this->table('Table 1. Feedback Responses', ['Submitted By', 'Type', 'Rating', 'Comment', 'Category', 'Date'], $t1rows)
                );
                break;

            default:
                $title = ucfirst($type) . " Report: {$generated}";
                $sectionsHtml .= $this->section('I. SUMMARY',
                    "This report contains {$total} records for the {$type} report type generated on {$genFull}."
                );
        }

        // â”€â”€ CSS & layout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        $css = '
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body { font-family: \'DejaVu Sans\', Arial, sans-serif; font-size: 11.5px; color: #1e293b; background: #fff; padding: 36px 44px; }
            .doc-title { text-align: center; font-size: 16px; font-weight: 800; margin-bottom: 4px; }
            .doc-sub { text-align: center; font-size: 11px; color: #64748b; margin-bottom: 6px; }
            .doc-date { text-align: center; font-size: 10px; color: #94a3b8; margin-bottom: 24px; }
            .section { margin-bottom: 22px; }
            .section-heading { font-size: 11.5px; font-weight: 700; color: #1e40af; margin-bottom: 6px; text-transform: uppercase; letter-spacing: .03em; }
            .section-body { font-size: 11px; line-height: 1.65; color: #334155; margin-bottom: 10px; }
            .tbl-label { font-size: 10.5px; font-weight: 700; margin-bottom: 5px; margin-top: 12px; }
            table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }
            th { background: #f1f5f9; padding: 7px 10px; text-align: left; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .04em; border-bottom: 2px solid #cbd5e1; border-top: 2px solid #cbd5e1; }
            td { padding: 6px 10px; border-bottom: 1px solid #e2e8f0; font-size: 11px; }
            tr.total-row td { font-weight: 700; border-top: 2px solid #cbd5e1; background: #f8fafc; }
            tr:nth-child(even) td { background: #f8fafc; }
            .footer { margin-top: 30px; border-top: 1px solid #e2e8f0; padding-top: 8px; font-size: 9px; color: #94a3b8; display: flex; justify-content: space-between; }
        ';

        $html = <<<HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>{$title}</title>
  <style>{$css}</style>
</head>
<body>
  <div class="doc-title">{$title}</div>
  <div class="doc-sub">PESO SANTIAGO CITY</div>
  <div class="doc-date">Generated: {$genFull}</div>

  {$sectionsHtml}

  <div class="footer">
    <span>Public Employment Service Office &bull; Santiago City</span>
    <span>{$genFull}</span>
  </div>
</body>
</html>
HTML;

        $pdf = Pdf::loadHTML($html)->setPaper('a4', 'portrait');
        return $pdf->download($filename);
    }

    // â”€â”€ PDF helper methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    private function section(string $heading, string $body = '', string $tableHtml = ''): string
    {
        $bodyHtml = $body ? "<p class='section-body'>{$body}</p>" : '';
        return "
        <div class='section'>
            <div class='section-heading'>{$heading}</div>
            {$bodyHtml}
            {$tableHtml}
        </div>";
    }

    private function table(string $label, array $headers, string $rows): string
    {
        $ths = implode('', array_map(fn($h) => "<th>{$h}</th>", $headers));
        return "
        <div class='tbl-label'>{$label}</div>
        <table><thead><tr>{$ths}</tr></thead><tbody>{$rows}</tbody></table>";
    }

    private function tableRow(array $cells): string
    {
        $tds = implode('', array_map(fn($c) => '<td>' . htmlspecialchars((string)$c) . '</td>', $cells));
        return "<tr>{$tds}</tr>";
    }

    private function tableRowTotal(array $cells): string
    {
        $tds = implode('', array_map(fn($c) => '<td>' . htmlspecialchars((string)$c) . '</td>', $cells));
        return "<tr class='total-row'>{$tds}</tr>";
    }
}
