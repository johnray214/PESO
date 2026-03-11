<?php

namespace App\Http\Controllers\Api\Employer;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\JobListing;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class EmployerJobController extends Controller
{
    public function index(Request $request)
    {
        $employer = $request->user();
        $query    = $employer->jobListings()->withCount('applications');

        if ($request->filled('search')) {
            $query->where('title', 'like', "%{$request->search}%");
        }

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        if ($request->filled('type')) {
            $query->where('employment_type', $request->type);
        }

        $jobs = $query->latest()->paginate($request->get('per_page', 15));

        $jobs->getCollection()->transform(fn($j) => $this->formatJob($j));

        $stats = [
            'total'      => $employer->jobListings()->count(),
            'open'       => $employer->jobListings()->where('status', 'open')->count(),
            'closed'     => $employer->jobListings()->where('status', 'closed')->count(),
            'draft'      => $employer->jobListings()->where('status', 'draft')->count(),
            'totalSlots' => $employer->jobListings()->sum('slots'),
        ];

        return response()->json(['success' => true, 'data' => $jobs, 'stats' => $stats]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title'       => 'required|string|max:255',
            'type'        => 'required|string',
            'salary'      => 'nullable|string|max:100',
            'slots'       => 'required|integer|min:1',
            'location'    => 'required|string|max:255',
            'description' => 'nullable|string',
            'skills'      => 'nullable|array',
            'status'      => 'nullable|in:open,draft',
            'closes_at'   => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employer = $request->user();

        $job = JobListing::create([
            'employer_id'     => $employer->id,
            'title'           => $request->title,
            'company'         => $employer->company_name,
            'company_initial' => strtoupper(substr($employer->company_name, 0, 2)),
            'employment_type' => $request->type,
            'salary_min'      => $request->salary ?? '',
            'salary_max'      => '',
            'location'        => $request->location,
            'description'     => $request->description ?? '',
            'skills'          => $request->skills ?? [],
            'slots'           => $request->slots,
            'status'          => $request->status ?? 'open',
            'closes_at'       => $request->closes_at,
            'is_active'       => true,
            'experience_level'=> 'Entry Level',
        ]);

        AuditLog::record('Created', 'Job Listings', "Job '{$job->title}' created", $request, $employer);

        return response()->json(['success' => true, 'message' => 'Job listing created', 'data' => $this->formatJob($job)], 201);
    }

    public function show(Request $request, $id)
    {
        $job = $request->user()->jobListings()->withCount('applications')->findOrFail($id);
        return response()->json(['success' => true, 'data' => $this->formatJob($job)]);
    }

    public function update(Request $request, $id)
    {
        $job = $request->user()->jobListings()->findOrFail($id);

        $validator = Validator::make($request->all(), [
            'title'       => 'sometimes|required|string|max:255',
            'type'        => 'sometimes|required|string',
            'salary'      => 'nullable|string|max:100',
            'slots'       => 'sometimes|required|integer|min:1',
            'location'    => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'skills'      => 'nullable|array',
            'status'      => 'nullable|in:open,draft,closed',
            'closes_at'   => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->only(['title', 'location', 'description', 'skills', 'slots', 'status', 'closes_at']);
        if ($request->filled('type')) $data['employment_type'] = $request->type;
        if ($request->filled('salary')) $data['salary_min'] = $request->salary;

        $job->update($data);

        AuditLog::record('Updated', 'Job Listings', "Job '{$job->title}' updated", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Job updated', 'data' => $this->formatJob($job)]);
    }

    public function close(Request $request, $id)
    {
        $job = $request->user()->jobListings()->findOrFail($id);
        $job->update(['status' => 'closed', 'is_active' => false]);

        AuditLog::record('Updated', 'Job Listings', "Job '{$job->title}' closed", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Job listing closed']);
    }

    public function destroy(Request $request, $id)
    {
        $job = $request->user()->jobListings()->findOrFail($id);

        AuditLog::record('Deleted', 'Job Listings', "Job '{$job->title}' deleted", $request, $request->user());

        $job->delete();

        return response()->json(['success' => true, 'message' => 'Job listing deleted']);
    }

    private function formatJob(JobListing $j): array
    {
        $daysLeft = null;
        if ($j->closes_at) {
            $daysLeft = max(0, (int) now()->diffInDays($j->closes_at, false));
        }

        return [
            'id'          => $j->id,
            'title'       => $j->title,
            'type'        => $j->employment_type,
            'location'    => $j->location,
            'salary'      => $j->salary_min,
            'slots'       => $j->slots,
            'applicants'  => $j->applications_count ?? 0,
            'hired'       => $j->hired_count,
            'status'      => $j->status ?? 'open',
            'daysLeft'    => $daysLeft,
            'postedDate'  => $j->created_at->format('M d, Y'),
            'description' => $j->description,
            'skills'      => $j->skills ?? [],
            'closesAt'    => $j->closes_at?->format('Y-m-d'),
        ];
    }
}
