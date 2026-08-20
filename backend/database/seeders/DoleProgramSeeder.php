<?php

namespace Database\Seeders;

use App\Models\Application;
use App\Models\ApplicationActivityLog;
use App\Models\JobListing;
use App\Models\JobSkill;
use App\Models\Jobseeker;
use Illuminate\Database\Seeder;

class DoleProgramSeeder extends Seeder
{
    public function run(): void
    {
        $doleJobs = [
            [
                'title'               => 'Administrative & Document Support Intern (SPES)',
                'type'                => 'internship',
                'program'             => 'SPES',
                'program_budget'      => '₱8,500 / month (60% LGU, 40% DOLE)',
                'program_duration'    => '30',
                'program_target'      => 'High School & College Students from Low-Income Families',
                'implementing_agency' => 'DOLE Region II / PESO Santiago City',
                'employer_name'       => 'Department of Labor and Employment',
                'employer_id'         => null,
                'location'            => 'Santiago City, Isabela',
                'salary_range'        => 'Minimum Wage',
                'education_level'     => 'senior_highschool',
                'experience_required' => 'fresh_grad',
                'slots'               => 30,
                'status'              => 'open',
                'posted_date'         => now()->subDays(10),
                'deadline'            => now()->addDays(20),
                'description'         => 'Special Program for Employment of Students (SPES) assisting enrolled youth and students from disadvantaged families to earn income for schooling through local government office internships, records filing, and document processing assistance.',
                'skills'              => ['Data Entry', 'Administrative Support', 'MS Office', 'Filing & Records Management'],
                'target_applicants'   => 8,
            ],
            [
                'title'               => 'Community Youth & Library Aide (SPES)',
                'type'                => 'internship',
                'program'             => 'SPES',
                'program_budget'      => '₱8,500 / month',
                'program_duration'    => '30',
                'program_target'      => 'Tertiary / College Students',
                'implementing_agency' => 'DOLE Region II / PESO Santiago City',
                'employer_name'       => 'Department of Labor and Employment',
                'employer_id'         => null,
                'location'            => 'Santiago City, Isabela',
                'salary_range'        => 'Minimum Wage',
                'education_level'     => 'college_level',
                'experience_required' => 'fresh_grad',
                'slots'               => 30,
                'status'              => 'open',
                'posted_date'         => now()->subDays(7),
                'deadline'            => now()->addDays(23),
                'description'         => 'Assisting the Santiago City Youth & Community Library in cataloging books, guiding student visitors, organizing learning sessions, and handling digital library inquiries.',
                'skills'              => ['Customer Service', 'Documentation', 'Communication', 'Basic Computer Literacy'],
                'target_applicants'   => 7,
            ],
            [
                'title'               => 'Public Service Intern - Research & Field Monitoring (GIP)',
                'type'                => 'internship',
                'program'             => 'GIP',
                'program_budget'      => '₱11,500 / month (100% Regional Minimum Wage)',
                'program_duration'    => '6',
                'program_target'      => 'College Graduates / Out-of-School Youth aged 18–30',
                'implementing_agency' => 'DOLE Regional Office II',
                'employer_name'       => 'Department of Labor and Employment',
                'employer_id'         => null,
                'location'            => 'Santiago City & Regional Centers',
                'salary_range'        => 'Minimum Wage',
                'education_level'     => 'college_graduate',
                'experience_required' => 'fresh_grad',
                'slots'               => 30,
                'status'              => 'open',
                'posted_date'         => now()->subDays(12),
                'deadline'            => now()->addDays(18),
                'description'         => 'Government Internship Program (GIP) offering youth an opportunity to demonstrate their skills in public administration, field assessment data collection, labor program monitoring, and public frontline service.',
                'skills'              => ['Research', 'Report Writing', 'Public Administration', 'Data Entry', 'MS Office'],
                'target_applicants'   => 6,
            ],
            [
                'title'               => 'Community Sanitation & Green Brigade Worker (TUPAD)',
                'type'                => 'contract',
                'program'             => 'TUPAD',
                'program_budget'      => '₱450 / day with GSIS Micro-Insurance',
                'program_duration'    => '15',
                'program_target'      => 'Displaced, Underemployed, or Seasonal Workers',
                'implementing_agency' => 'DOLE - LGU Santiago City',
                'employer_name'       => 'Department of Labor and Employment',
                'employer_id'         => null,
                'location'            => 'Santiago City, Isabela',
                'salary_range'        => 'Minimum Wage',
                'education_level'     => 'elementary',
                'experience_required' => 'fresh_grad',
                'slots'               => 30,
                'status'              => 'open',
                'posted_date'         => now()->subDays(5),
                'deadline'            => now()->addDays(25),
                'description'         => 'Tulong Panghanapbuhay sa Ating Disadvantaged/Displaced Workers (TUPAD) community-based package providing short-term emergency employment for displaced and seasonal workers in community sanitation and tree planting.',
                'skills'              => ['Physical Labor', 'Community Cleaning', 'Safety Procedures', 'Teamwork'],
                'target_applicants'   => 5,
            ],
            [
                'title'               => 'Customer Care & Technical Support Trainee (JobStart)',
                'type'                => 'internship',
                'program'             => 'JobStart',
                'program_budget'      => '₱350 / day Life Skills & Internship Allowance',
                'program_duration'    => '90',
                'program_target'      => 'Youth Jobseekers aged 18–24 (Not in Education or Employment)',
                'implementing_agency' => 'DOLE - Asian Development Bank (ADB)',
                'employer_name'       => 'Department of Labor and Employment',
                'employer_id'         => null,
                'location'            => 'Santiago City, Isabela',
                'salary_range'        => 'Minimum Wage',
                'education_level'     => 'senior_highschool',
                'experience_required' => 'fresh_grad',
                'slots'               => 30,
                'status'              => 'open',
                'posted_date'         => now()->subDays(8),
                'deadline'            => now()->addDays(22),
                'description'         => 'JobStart Philippines full-cycle employment bridging program providing life skills training, technical vocational skills enhancement, and company-matched internship placement for at-risk youth.',
                'skills'              => ['Customer Service', 'Call Handling', 'Problem Solving', 'English Communication'],
                'target_applicants'   => 4,
            ],
        ];

        $createdListings = [];

        foreach ($doleJobs as $jobData) {
            $skills = $jobData['skills'];
            $targetCount = $jobData['target_applicants'];
            unset($jobData['skills'], $jobData['target_applicants']);

            $job = JobListing::updateOrCreate(
                [
                    'title'   => $jobData['title'],
                    'program' => $jobData['program'],
                ],
                $jobData
            );

            JobSkill::where('job_listing_id', $job->id)->delete();
            foreach ($skills as $skill) {
                JobSkill::create([
                    'job_listing_id' => $job->id,
                    'skill'          => $skill,
                ]);
            }

            $createdListings[] = ['job' => $job, 'target' => $targetCount];
        }

        // ── Seed Exactly 30 Applicants across DOLE Programs ──
        $jobseekers = Jobseeker::with('skills')->get();
        if ($jobseekers->isEmpty()) {
            return;
        }

        // Clean existing DOLE program applications before reseeding
        $doleJobIds = array_map(fn($item) => $item['job']->id, $createdListings);
        Application::whereIn('job_listing_id', $doleJobIds)->delete();

        $statuses = ['reviewing', 'shortlisted', 'interview', 'for_job_offer', 'hired', 'rejected'];
        $globalCount = 0;

        foreach ($createdListings as $item) {
            $listing = $item['job'];
            $targetCount = $item['target'];
            $assigned = 0;

            foreach ($jobseekers as $seeker) {
                if ($assigned >= $targetCount || $globalCount >= 30) {
                    break;
                }

                $exists = Application::where('job_listing_id', $listing->id)
                    ->where('jobseeker_id', $seeker->id)
                    ->exists();

                if ($exists) {
                    continue;
                }

                $matchScore = Application::calculateMatchScore($seeker, $listing);
                if ($matchScore === 0) {
                    $matchScore = rand(50, 95);
                }

                $status = $statuses[$globalCount % count($statuses)];

                $app = Application::create([
                    'job_listing_id' => $listing->id,
                    'jobseeker_id'   => $seeker->id,
                    'status'         => $status,
                    'match_score'    => $matchScore,
                    'applied_at'     => now()->subDays(rand(1, 14)),
                ]);

                ApplicationActivityLog::create([
                    'application_id' => $app->id,
                    'actor_type'     => 'peso',
                    'actor_label'    => 'PESO Santiago',
                    'action'         => $status === 'for_job_offer' ? 'For Job Offer' : ucfirst($status),
                    'created_at'     => $app->applied_at,
                ]);

                $assigned++;
                $globalCount++;
            }
        }
    }
}
