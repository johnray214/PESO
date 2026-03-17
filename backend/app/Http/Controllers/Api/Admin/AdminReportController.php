<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Report;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminReportController extends Controller
{
    public function index()
    {
        $reports = Report::with('generator:id,first_name,last_name')
            ->orderByDesc('created_at')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $reports,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'type' => ['required', Rule::in(['placement', 'registration', 'skills', 'events', 'employer', 'skillmatch'])],
            'date_from' => 'required|date',
            'date_to' => 'required|date|after_or_equal:date_from',
            'group_by' => 'nullable|string|max:50',
            'columns' => 'nullable|array',
            'export_format' => ['nullable', Rule::in(['pdf', 'csv', 'xlsx'])],
        ]);

        $validated['generated_by'] = $request->user()->id;
        
        $report = Report::create($validated);

        return response()->json([
            'success' => true,
            'data' => $report,
            'message' => 'Report generated successfully',
        ], 201);
    }

    public function show($id)
    {
        $report = Report::with('generator')->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $report,
        ]);
    }

    public function destroy($id)
    {
        $report = Report::findOrFail($id);
        $report->delete();

        return response()->json([
            'success' => true,
            'message' => 'Report deleted successfully',
        ]);
    }

    public function data(Request $request, $type)
    {
        $validated = $request->validate([
            'date_from' => 'required|date',
            'date_to' => 'required|date|after_or_equal:date_from',
        ]);

        $data = [];

        switch ($type) {
            case 'placement':
                $data = $this->getPlacementData($validated['date_from'], $validated['date_to']);
                break;
            case 'registration':
                $data = $this->getRegistrationData($validated['date_from'], $validated['date_to']);
                break;
            case 'skills':
                $data = $this->getSkillsData($validated['date_from'], $validated['date_to']);
                break;
            case 'events':
                $data = $this->getEventsData($validated['date_from'], $validated['date_to']);
                break;
            case 'employer':
                $data = $this->getEmployerData($validated['date_from'], $validated['date_to']);
                break;
            case 'skillmatch':
                $data = $this->getSkillMatchData($validated['date_from'], $validated['date_to']);
                break;
        }

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    private function getPlacementData($from, $to)
    {
        return [
            'hired_count' => \App\Models\Application::where('status', 'hired')
                ->whereBetween('applied_at', [$from, $to])->count(),
            'by_job_type' => \App\Models\JobListing::selectRaw('type, COUNT(*) as count')
                ->whereHas('applications', function ($q) use ($from, $to) {
                    $q->where('status', 'hired')->whereBetween('applied_at', [$from, $to]);
                })->groupBy('type')->pluck('count', 'type'),
        ];
    }

    private function getRegistrationData($from, $to)
    {
        return [
            'jobseekers' => \App\Models\Jobseeker::whereBetween('created_at', [$from, $to])->count(),
            'employers' => \App\Models\Employer::whereBetween('created_at', [$from, $to])->count(),
        ];
    }

    private function getSkillsData($from, $to)
    {
        return \App\Models\JobseekerSkill::selectRaw('skill, COUNT(*) as count')
            ->whereHas('jobseeker', function ($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from, $to]);
            })->groupBy('skill')->orderByDesc('count')->limit(20)->get();
    }

    private function getEventsData($from, $to)
    {
        return \App\Models\Event::whereBetween('event_date', [$from, $to])
            ->select('id', 'title', 'event_date', 'status')
            ->get();
    }

    private function getEmployerData($from, $to)
    {
        return [
            'new_employers' => \App\Models\Employer::whereBetween('created_at', [$from, $to])->count(),
            'by_status' => \App\Models\Employer::selectRaw('status, COUNT(*) as count')
                ->whereBetween('created_at', [$from, $to])
                ->groupBy('status')->pluck('count', 'status'),
        ];
    }

    private function getSkillMatchData($from, $to)
    {
        return \App\Models\Application::whereBetween('applied_at', [$from, $to])
            ->selectRaw('AVG(match_score) as avg_score, COUNT(*) as total')
            ->first();
    }
}
