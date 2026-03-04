<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SavedJob;
use App\Models\JobListing;
use Illuminate\Http\Request;

class SavedJobController extends Controller
{
    public function index(Request $request)
    {
        $saved = $request->user()->savedJobs()
            ->with('jobListing')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $saved,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'job_listing_id' => 'required|exists:job_listings,id',
        ]);

        $user = $request->user();

        $job = JobListing::findOrFail($validated['job_listing_id']);

        $saved = SavedJob::firstOrCreate([
            'user_id'        => $user->id,
            'job_listing_id' => $job->id,
        ]);

        $saved->load('jobListing');

        return response()->json([
            'success' => true,
            'message' => 'Job saved successfully.',
            'data'    => $saved,
        ], 201);
    }

    public function destroy(Request $request, JobListing $jobListing)
    {
        $user = $request->user();

        $deleted = SavedJob::where('user_id', $user->id)
            ->where('job_listing_id', $jobListing->id)
            ->delete();

        return response()->json([
            'success' => true,
            'message' => $deleted ? 'Job removed from saved.' : 'Job was not saved.',
        ]);
    }
}

