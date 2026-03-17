<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Application;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminApplicationController extends Controller
{
    public function index(Request $request)
    {
        $query = Application::query();
        
        if ($request->has('search')) {
            $search = $request->search;
            $query->whereHas('jobseeker', function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                  ->orWhere('last_name', 'like', "%{$search}%");
            });
        }
        
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        if ($request->has('job_listing_id')) {
            $query->where('job_listing_id', $request->job_listing_id);
        }
        
        if ($request->has('jobseeker_id')) {
            $query->where('jobseeker_id', $request->jobseeker_id);
        }

        $applications = $query->with(['jobseeker.skills', 'jobListing.employer'])
            ->orderByDesc('applied_at')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $applications,
        ]);
    }

    public function show($id)
    {
        $application = Application::with(['jobseeker.skills', 'jobListing'])->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $application,
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $validated = $request->validate([
            'status' => ['required', Rule::in(['reviewing', 'shortlisted', 'interview', 'hired', 'rejected'])],
        ]);

        $application = Application::findOrFail($id);
        $application->update($validated);

        return response()->json([
            'success' => true,
            'data' => $application,
            'message' => 'Application status updated successfully',
        ]);
    }

    public function destroy($id)
    {
        $application = Application::findOrFail($id);
        $application->delete();

        return response()->json([
            'success' => true,
            'message' => 'Application deleted successfully',
        ]);
    }
}
