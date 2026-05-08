<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Models\Employer;
use App\Support\PublicStorageUrl;
use Illuminate\Http\Request;

class PublicMapController extends Controller
{
    /**
     * Lightweight map endpoint for mobile app.
     * Returns employers with coordinates and their open job listings.
     */
    public function employers(Request $request)
    {
        $jobsPerEmployer = max(1, min((int) $request->integer('jobs_per_employer', 8), 20));
        $employerLimit = max(1, min((int) $request->integer('limit', 400), 1000));

        $query = Employer::query()
            ->select([
                'id',
                'company_name',
                'photo',
                'address_full',
                'city',
                'province',
                'latitude',
                'longitude',
                'map_visible',
                'status',
            ])
            ->where('map_visible', true)
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->where('status', 'verified')
            ->with(['jobListings' => function ($q) use ($jobsPerEmployer) {
                $q->where('status', 'open')
                    ->select('id', 'employer_id', 'title', 'type', 'location', 'salary_range', 'description', 'posted_date', 'created_at')
                    ->orderByDesc('posted_date')
                    ->limit($jobsPerEmployer);
            }]);

        $minLat = $request->query('min_lat');
        $maxLat = $request->query('max_lat');
        $minLng = $request->query('min_lng');
        $maxLng = $request->query('max_lng');
        if (
            is_numeric($minLat) &&
            is_numeric($maxLat) &&
            is_numeric($minLng) &&
            is_numeric($maxLng)
        ) {
            $query->whereBetween('latitude', [(float) $minLat, (float) $maxLat])
                ->whereBetween('longitude', [(float) $minLng, (float) $maxLng]);
        }

        $page = $query
            ->orderBy('company_name')
            ->orderBy('id')
            ->cursorPaginate(
                $employerLimit,
                ['*'],
                'cursor',
                $request->query('cursor')
            );

        $employers = $page->getCollection()
            ->map(function ($e) use ($request) {
                return [
                    'id' => $e->id,
                    'company_name' => $e->company_name,
                    'photo' => $e->photo,
                    'photo_url' => PublicStorageUrl::fromRequest($request, $e->photo),
                    'address_full' => $e->address_full,
                    'city' => $e->city,
                    'province' => $e->province,
                    'latitude' => $e->latitude,
                    'longitude' => $e->longitude,
                    'job_listings' => $e->jobListings->values(),
                ];
            })
            ->values();

        return response()->json([
            'success' => true,
            'data' => $employers,
            'meta' => [
                'per_page' => $employerLimit,
                'next_cursor' => optional($page->nextCursor())->encode(),
                'prev_cursor' => optional($page->previousCursor())->encode(),
                'has_more' => $page->nextCursor() !== null,
            ],
        ]);
    }
}

