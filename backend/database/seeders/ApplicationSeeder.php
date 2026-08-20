<?php

namespace Database\Seeders;

use App\Models\Application;
use App\Models\ApplicationActivityLog;
use App\Models\JobListing;
use App\Models\Jobseeker;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ApplicationSeeder extends Seeder
{
    public function run(): void
    {
        $jobs = JobListing::with(['employer', 'skills'])->get();

        $statuses      = ['reviewing', 'shortlisted', 'interview', 'for_job_offer', 'hired', 'rejected'];
        $statusWeights = [20, 20, 15, 10, 25, 10]; // % distribution

        foreach ($jobs as $job) {
            $jobSkills = $job->skills->pluck('skill')->map(fn($s) => strtolower($s))->toArray();
            if (empty($jobSkills)) {
                continue;
            }

            // Find jobseekers with matching skills
            $matchingSeekers = Jobseeker::whereHas('skills', function ($q) use ($jobSkills) {
                $q->whereIn(DB::raw('LOWER(skill)'), $jobSkills);
            })->with('skills')->get();

            $applied = 0;
            foreach ($matchingSeekers as $seeker) {
                $seekerSkills = $seeker->skills->pluck('skill')->map(fn($s) => strtolower($s))->toArray();
                $intersection = array_intersect($jobSkills, $seekerSkills);
                $matchScore   = (int) round(count($intersection) / count($jobSkills) * 100);

                if ($matchScore < 25) {
                    continue;
                }

                if ($applied >= ($job->slots * 3 + 3)) {
                    break;
                }

                $rand   = rand(1, 100);
                $cumul  = 0;
                $status = 'reviewing';
                foreach ($statuses as $i => $s) {
                    $cumul += $statusWeights[$i];
                    if ($rand <= $cumul) {
                        $status = $s;
                        break;
                    }
                }

                $application = Application::firstOrCreate(
                    ['job_listing_id' => $job->id, 'jobseeker_id' => $seeker->id],
                    [
                        'status'      => $status,
                        'match_score' => $matchScore,
                        'applied_at'  => now()->subDays(rand(1, 20)),
                    ]
                );

                if ($application->wasRecentlyCreated) {
                    ApplicationActivityLog::create([
                        'application_id' => $application->id,
                        'actor_type'     => $job->employer_id ? 'employer' : 'peso',
                        'actor_label'    => $job->employer->company_name ?? 'PESO Santiago',
                        'action'         => $status === 'for_job_offer' ? 'For Job Offer' : ucfirst($status),
                        'created_at'     => $application->applied_at,
                    ]);
                }

                $applied++;
            }
        }
    }
}
