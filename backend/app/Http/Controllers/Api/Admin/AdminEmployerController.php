<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Employer;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminEmployerController extends Controller
{
    public function index(Request $request)
    {
        $query = Employer::query();
        
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('company_name', 'like', "%{$search}%")
                  ->orWhere('contact_person', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }
        
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Eager load job listings, their skills, and only hired applications
        $query->with([
            'jobListings.skills',
            'jobListings' => function ($q) {
                // We need the total applications count per listing
                $q->withCount('applications');
            },
            'jobListings.applications' => function ($q) {
                // For the drawer "Hired Applicants" tab
                $q->where('status', 'hired')->with('jobseeker:id,first_name,last_name');
            }
        ]);

        $employers = $query->orderByDesc('created_at')->paginate(15);

        // Transform collection to include derived counts
        $employers->getCollection()->transform(function ($emp) {
            $hiredApplicants = [];
            $totalHired = 0;

            foreach ($emp->jobListings as $listing) {
                foreach ($listing->applications as $app) {
                    if ($app->status === 'hired') {
                        $totalHired++;
                        $name = $app->jobseeker ? trim($app->jobseeker->first_name . ' ' . $app->jobseeker->last_name) : 'Unknown';
                        $hiredApplicants[] = [
                            'name' => $name,
                            'job'  => $listing->title,
                            'date' => $app->updated_at ? $app->updated_at->format('M d, Y') : 'Recently',
                        ];
                    }
                }
            }

            $emp->total_hired = $totalHired;
            $emp->hired_applicants = $hiredApplicants;
            return $emp;
        });

        return response()->json([
            'success' => true,
            'data' => $employers,
        ]);
    }

    public function show($id)
    {
        $employer = Employer::with('jobListings')->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $employer,
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $validated = $request->validate([
            'status' => ['required', Rule::in(['verified', 'rejected', 'suspended'])],
            'remarks' => ['nullable', 'string', 'max:1000'],
        ]);

        $employer = Employer::findOrFail($id);
        
        if ($validated['status'] === 'verified' && $employer->status !== 'verified') {
            $validated['verified_at'] = now();
        }
        
        $employer->update($validated);

        return response()->json([
            'success' => true,
            'data' => $employer,
            'message' => 'Employer status updated successfully',
        ]);
    }

    public function update(Request $request, $id)
    {
        $employer = Employer::findOrFail($id);
        
        $validated = $request->validate([
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
        ]);

        $employer->update($validated);

        return response()->json([
            'success' => true,
            'data' => $employer,
            'message' => 'Employer updated successfully',
        ]);
    }

    public function destroy($id)
    {
        $employer = Employer::findOrFail($id);
        $employer->delete();

        return response()->json([
            'success' => true,
            'message' => 'Employer deleted successfully',
        ]);
    }
}
