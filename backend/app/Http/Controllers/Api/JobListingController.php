<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\JobListing;
use Illuminate\Http\Request;

class JobListingController extends Controller
{
    /**
     * Return all active job listings, newest first.
     */
    public function index()
    {
        $jobs = JobListing::where('is_active', true)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $jobs,
        ]);
    }

    /**
     * Return a single job listing.
     */
    public function show($id)
    {
        $job = JobListing::where('is_active', true)->find($id);

        if (! $job) {
            return response()->json([
                'success' => false,
                'message' => 'Job listing not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => $job,
        ]);
    }

    /**
     * Return active jobs ranked by how well they match the authenticated user's skills.
     */
    public function matched(Request $request)
    {
        $userSkills = $request->user()->skills ?? [];

        if (empty($userSkills)) {
            return response()->json([
                'success' => true,
                'data'    => [],
                'message' => 'Add skills to your profile to see matched jobs.',
            ]);
        }

        $userSkillsLower = array_map('strtolower', $userSkills);

        $jobs = JobListing::where('is_active', true)->get();

        $matched = $jobs->map(function ($job) use ($userSkillsLower) {
            $jobSkills = is_array($job->skills) ? $job->skills : [];
            if (empty($jobSkills)) {
                $job->match_percentage = 0;
                return $job;
            }

            $jobSkillsLower = array_map('strtolower', $jobSkills);
            $matchedCount = count(array_intersect($userSkillsLower, $jobSkillsLower));
            $percentage = (int) round(($matchedCount / count($jobSkillsLower)) * 100);

            $job->match_percentage = $percentage;
            $job->matched_skills = array_values(array_intersect(
                array_map('strtolower', $jobSkills),
                $userSkillsLower,
            ));

            return $job;
        })
        ->filter(fn ($job) => $job->match_percentage > 0)
        ->sortByDesc('match_percentage')
        ->values();

        return response()->json([
            'success' => true,
            'data'    => $matched,
        ]);
    }

    /**
     * Return all unique skills across active job listings, grouped by category.
     */
    public function skillCatalog()
    {
        $jobs = JobListing::where('is_active', true)->get();

        $byCategory = [];
        $allSkills = [];

        foreach ($jobs as $job) {
            $skills = is_array($job->skills) ? $job->skills : [];
            $category = $job->category ?? 'Other';

            if (! isset($byCategory[$category])) {
                $byCategory[$category] = [];
            }

            foreach ($skills as $skill) {
                $byCategory[$category][] = $skill;
                $allSkills[] = $skill;
            }
        }

        foreach ($byCategory as $cat => $skills) {
            $byCategory[$cat] = array_values(array_unique($skills));
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'categories' => $byCategory,
                'all_skills' => array_values(array_unique($allSkills)),
            ],
        ]);
    }
}
