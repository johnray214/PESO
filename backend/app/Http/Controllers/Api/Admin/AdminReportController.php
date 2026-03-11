<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Employer;
use App\Models\Event;
use App\Models\JobListing;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AdminReportController extends Controller
{
    public function generate(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'reportType' => 'required|in:placement,registration,skills,events,employers,skill_match',
            'dateFrom'   => 'nullable|date',
            'dateTo'     => 'nullable|date|after_or_equal:dateFrom',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = match ($request->reportType) {
            'placement'   => $this->placementReport($request),
            'registration'=> $this->registrationReport($request),
            'skills'      => $this->skillsReport($request),
            'events'      => $this->eventsReport($request),
            'employers'   => $this->employersReport($request),
            'skill_match' => $this->skillMatchReport($request),
            default       => [],
        };

        AuditLog::record('Exported', 'Reports', "Generated {$request->reportType} report", $request, $request->user());

        return response()->json(['success' => true, 'data' => $data]);
    }

    private function applyDateFilter($query, Request $request, string $column = 'created_at')
    {
        if ($request->filled('dateFrom')) {
            $query->whereDate($column, '>=', $request->dateFrom);
        }
        if ($request->filled('dateTo')) {
            $query->whereDate($column, '<=', $request->dateTo);
        }
        return $query;
    }

    private function placementReport(Request $request): array
    {
        $query = User::query();
        $this->applyDateFilter($query, $request);

        if ($request->filled('filters.status')) {
            $query->where('peso_status', $request->input('filters.status'));
        }

        $users = $query->get();

        $summary = [
            'total'      => $users->count(),
            'processing' => $users->where('peso_status', 'processing')->count(),
            'placed'     => $users->where('peso_status', 'placed')->count(),
            'hired'      => $users->where('peso_status', 'hired')->count(),
            'rejected'   => $users->where('peso_status', 'rejected')->count(),
        ];

        $rows = $users->map(fn($u) => [
            'name'       => $u->name,
            'email'      => $u->email,
            'location'   => $u->address,
            'skills'     => is_array($u->skills) ? implode(', ', $u->skills) : '',
            'status'     => $u->peso_status ?? 'processing',
            'registered' => $u->created_at->format('Y-m-d'),
        ])->values()->toArray();

        return compact('summary', 'rows');
    }

    private function registrationReport(Request $request): array
    {
        $query = User::query();
        $this->applyDateFilter($query, $request);

        $users = $query->get();
        $summary = ['total' => $users->count()];

        $rows = $users->map(fn($u) => [
            'name'     => $u->name,
            'email'    => $u->email,
            'gender'   => $u->gender,
            'location' => $u->address,
            'date'     => $u->created_at->format('Y-m-d'),
        ])->values()->toArray();

        return compact('summary', 'rows');
    }

    private function skillsReport(Request $request): array
    {
        $users = User::whereNotNull('skills')->get();
        $counts = [];
        foreach ($users as $u) {
            if (!is_array($u->skills)) continue;
            foreach ($u->skills as $skill) {
                $counts[$skill] = ($counts[$skill] ?? 0) + 1;
            }
        }
        arsort($counts);

        $rows = [];
        foreach ($counts as $skill => $count) {
            $rows[] = ['skill' => $skill, 'count' => $count];
        }

        return ['summary' => ['totalSkills' => count($counts)], 'rows' => $rows];
    }

    private function eventsReport(Request $request): array
    {
        $query = Event::query();
        $this->applyDateFilter($query, $request, 'event_date');

        if ($request->filled('filters.type')) {
            $query->where('event_type', $request->input('filters.type'));
        }
        if ($request->filled('filters.status')) {
            $query->where('status', $request->input('filters.status'));
        }

        $events = $query->get();
        $summary = [
            'total'     => $events->count(),
            'upcoming'  => $events->where('status', 'upcoming')->count(),
            'completed' => $events->where('status', 'completed')->count(),
        ];

        $rows = $events->map(fn($e) => [
            'title'      => $e->title,
            'type'       => $e->event_type,
            'date'       => $e->event_date?->format('Y-m-d'),
            'venue'      => $e->location,
            'slots'      => $e->slots,
            'registered' => $e->registered,
            'status'     => $e->status,
        ])->values()->toArray();

        return compact('summary', 'rows');
    }

    private function employersReport(Request $request): array
    {
        $query = Employer::withCount('jobListings');
        $this->applyDateFilter($query, $request);

        if ($request->filled('filters.status')) {
            $query->where('status', $request->input('filters.status'));
        }

        $employers = $query->get();
        $summary = [
            'total'    => $employers->count(),
            'active'   => $employers->where('status', 'active')->count(),
            'pending'  => $employers->where('status', 'pending')->count(),
            'inactive' => $employers->where('status', 'inactive')->count(),
        ];

        $rows = $employers->map(fn($e) => [
            'company'    => $e->company_name,
            'industry'   => $e->industry,
            'contact'    => $e->contact_person,
            'email'      => $e->email,
            'listings'   => $e->job_listings_count,
            'hired'      => $e->total_hired,
            'status'     => $e->status,
            'joined'     => $e->created_at->format('Y-m-d'),
        ])->values()->toArray();

        return compact('summary', 'rows');
    }

    private function skillMatchReport(Request $request): array
    {
        $jobSkills = [];
        JobListing::where('status', 'open')->get()->each(function ($job) use (&$jobSkills) {
            if (!is_array($job->skills)) return;
            foreach ($job->skills as $skill) {
                $jobSkills[$skill] = ($jobSkills[$skill] ?? 0) + 1;
            }
        });

        $userSkills = [];
        User::whereNotNull('skills')->get()->each(function ($u) use (&$userSkills) {
            if (!is_array($u->skills)) return;
            foreach ($u->skills as $skill) {
                $userSkills[$skill] = ($userSkills[$skill] ?? 0) + 1;
            }
        });

        $allSkills = array_unique(array_merge(array_keys($jobSkills), array_keys($userSkills)));
        sort($allSkills);

        $rows = array_map(fn($skill) => [
            'skill'     => $skill,
            'demand'    => $jobSkills[$skill] ?? 0,
            'available' => $userSkills[$skill] ?? 0,
            'gap'       => ($jobSkills[$skill] ?? 0) - ($userSkills[$skill] ?? 0),
        ], $allSkills);

        return ['summary' => ['totalSkills' => count($allSkills)], 'rows' => $rows];
    }
}
