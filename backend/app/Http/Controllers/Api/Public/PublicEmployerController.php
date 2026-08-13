<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Models\Employer;
use App\Support\PublicStorageUrl;
use Illuminate\Http\Request;

class PublicEmployerController extends Controller
{
    /**
     * Public index of verified employers for jobseekers and visitors.
     * Restricts output to safe public profile fields only (no admin metadata, contact emails, or TIN numbers).
     */
    public function index(Request $request)
    {
        $query = Employer::query()
            ->where('status', 'verified')
            ->select([
                'id',
                'company_name',
                'photo',
                'industry',
                'address_full',
                'city',
                'province',
                'latitude',
                'longitude',
                'created_at',
            ]);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where('company_name', 'like', "%{$search}%");
        }

        if ($request->filled('industry')) {
            $query->where('industry', $request->industry);
        }

        $query->withCount(['jobListings' => function ($q) {
            $q->where('status', 'open');
        }]);

        $employers = $query->orderBy('company_name')->paginate(15);

        $employers->getCollection()->transform(function ($emp) use ($request) {
            return [
                'id' => $emp->id,
                'company_name' => $emp->company_name,
                'photo' => $emp->photo,
                'photo_url' => PublicStorageUrl::fromRequest($request, $emp->photo),
                'industry' => $emp->industry,
                'address_full' => $emp->address_full,
                'city' => $emp->city,
                'province' => $emp->province,
                'latitude' => $emp->latitude,
                'longitude' => $emp->longitude,
                'open_jobs_count' => $emp->job_listings_count ?? 0,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $employers->items(),
            'meta' => [
                'current_page' => $employers->currentPage(),
                'last_page' => $employers->lastPage(),
                'per_page' => $employers->perPage(),
                'total' => $employers->total(),
            ],
        ]);
    }

    /**
     * Public show endpoint for a single verified employer and their active job listings.
     */
    public function show(Request $request, $id)
    {
        $employer = Employer::where('status', 'verified')
            ->select([
                'id',
                'company_name',
                'photo',
                'industry',
                'address_full',
                'city',
                'province',
                'latitude',
                'longitude',
            ])
            ->with(['jobListings' => function ($q) {
                $q->where('status', 'open')
                    ->select('id', 'employer_id', 'title', 'type', 'location', 'salary_range', 'description', 'posted_date', 'created_at')
                    ->orderByDesc('posted_date');
            }])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $employer->id,
                'company_name' => $employer->company_name,
                'photo' => $employer->photo,
                'photo_url' => PublicStorageUrl::fromRequest($request, $employer->photo),
                'industry' => $employer->industry,
                'address_full' => $employer->address_full,
                'city' => $employer->city,
                'province' => $employer->province,
                'latitude' => $employer->latitude,
                'longitude' => $employer->longitude,
                'job_listings' => $employer->jobListings,
            ],
        ]);
    }
}
