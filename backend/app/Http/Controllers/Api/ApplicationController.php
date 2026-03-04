<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\JobApplication;
use App\Models\JobListing;
use Illuminate\Http\Request;

class ApplicationController extends Controller
{
    public function index(Request $request)
    {
        $applications = $request->user()->applications()
            ->with('jobListing')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $applications,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'job_listing_id' => 'required|exists:job_listings,id',
        ]);

        $user = $request->user();

        $existing = $user->applications()
            ->where('job_listing_id', $validated['job_listing_id'])
            ->first();

        if ($existing) {
            $existing->load('jobListing');

            return response()->json([
                'success' => true,
                'message' => 'You already applied to this job.',
                'data'    => $existing,
            ]);
        }

        $job = JobListing::findOrFail($validated['job_listing_id']);

        $application = JobApplication::create([
            'user_id'        => $user->id,
            'job_listing_id' => $job->id,
            'status'         => 'Submitted',
            'applied_at'     => now(),
        ]);

        $application->load('jobListing');

        return response()->json([
            'success' => true,
            'message' => 'Application submitted successfully.',
            'data'    => $application,
        ], 201);
    }
}

