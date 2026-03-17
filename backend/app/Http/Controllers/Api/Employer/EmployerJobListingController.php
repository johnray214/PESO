<?php

namespace App\Http\Controllers\Api\Employer;

use App\Http\Controllers\Controller;
use App\Models\JobListing;
use App\Models\JobSkill;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class EmployerJobListingController extends Controller
{
    /**
     * Normalise type/status from the frontend to lowercase for DB storage.
     * DB enum was updated to Title Case but we accept both.
     */
    private function normalise(string $value): string
    {
        return strtolower(trim($value));
    }

    public function index(Request $request)
    {
        $employer = $request->user();

        $query = JobListing::where('employer_id', $employer->id);

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('location', 'like', "%{$search}%");
            });
        }

        if ($request->has('status') && $request->status !== '') {
            // Accept both 'open' and 'Open'
            $query->whereRaw('LOWER(status) = ?', [strtolower($request->status)]);
        }

        if ($request->has('type') && $request->type !== '') {
            $query->whereRaw('LOWER(type) = ?', [strtolower($request->type)]);
        }

        $jobListings = $query->withCount('applications')
            ->with('skills')
            ->orderByDesc('created_at')
            ->paginate(50);

        return response()->json([
            'success' => true,
            'data'    => $jobListings,
        ]);
    }

    public function show(Request $request, $id)
    {
        $employer = $request->user();

        $jobListing = JobListing::with(['skills', 'applications.jobseeker:id,first_name,last_name'])
            ->where('employer_id', $employer->id)
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $jobListing,
        ]);
    }

    public function store(Request $request)
    {
        $employer = $request->user();

        $validated = $request->validate([
            'title'        => 'required|string|max:255',
            'type'         => 'required|string|max:50',
            'location'     => 'required|string|max:255',
            'salary_range' => 'nullable|string|max:100',
            'description'  => 'required|string',
            'slots'        => 'required|integer|min:1',
            'status'       => 'sometimes|string|max:20',
            'posted_date'  => 'nullable|date',
            'deadline'     => 'nullable|date',
            'skills'       => 'nullable|array',
            'skills.*'     => 'string|max:100',
        ]);

        // Normalise type and status to lowercase to match DB enum
        $validated['type']   = $this->normalise($validated['type']);
        $validated['status'] = isset($validated['status']) ? $this->normalise($validated['status']) : 'open';

        // Auto-set posted_date when status is open/Open
        if ($validated['status'] === 'open' && empty($validated['posted_date'])) {
            $validated['posted_date'] = now();
        }

        $validated['employer_id'] = $employer->id;

        DB::beginTransaction();
        try {
            $jobListing = JobListing::create($validated);

            if (!empty($validated['skills'])) {
                foreach ($validated['skills'] as $skill) {
                    JobSkill::create([
                        'job_listing_id' => $jobListing->id,
                        'skill'          => trim($skill),
                    ]);
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'data'    => $jobListing->load('skills'),
                'message' => 'Job listing created successfully',
            ], 201);
        } catch (\Exception $e) {
            DB::rollback();
            throw $e;
        }
    }

    public function update(Request $request, $id)
    {
        $employer   = $request->user();
        $jobListing = JobListing::where('employer_id', $employer->id)->findOrFail($id);

        $validated = $request->validate([
            'title'        => 'sometimes|string|max:255',
            'type'         => 'sometimes|string|max:50',
            'location'     => 'sometimes|string|max:255',
            'salary_range' => 'nullable|string|max:100',
            'description'  => 'sometimes|string',
            'slots'        => 'sometimes|integer|min:1',
            'status'       => 'sometimes|string|max:20',
            'posted_date'  => 'nullable|date',
            'deadline'     => 'nullable|date',
            'skills'       => 'nullable|array',
            'skills.*'     => 'string|max:100',
        ]);

        // Normalise type and status
        if (isset($validated['type']))   $validated['type']   = $this->normalise($validated['type']);
        if (isset($validated['status'])) $validated['status'] = $this->normalise($validated['status']);

        DB::beginTransaction();
        try {
            $jobListing->update($validated);

            if (isset($validated['skills'])) {
                $jobListing->skills()->delete();
                foreach ($validated['skills'] as $skill) {
                    JobSkill::create([
                        'job_listing_id' => $jobListing->id,
                        'skill'          => trim($skill),
                    ]);
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'data'    => $jobListing->load('skills'),
                'message' => 'Job listing updated successfully',
            ]);
        } catch (\Exception $e) {
            DB::rollback();
            throw $e;
        }
    }

    public function destroy(Request $request, $id)
    {
        $employer   = $request->user();
        $jobListing = JobListing::where('employer_id', $employer->id)->findOrFail($id);
        $jobListing->delete();

        return response()->json([
            'success' => true,
            'message' => 'Job listing deleted successfully',
        ]);
    }
}
