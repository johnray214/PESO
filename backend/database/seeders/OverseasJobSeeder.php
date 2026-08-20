<?php

namespace Database\Seeders;

use App\Models\Application;
use App\Models\ApplicationActivityLog;
use App\Models\Employer;
use App\Models\JobListing;
use App\Models\JobSkill;
use App\Models\Jobseeker;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class OverseasJobSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create or get Overseas Recruitment Agency Employers
        $agency1 = Employer::updateOrCreate(
            ['email' => 'contact@globalplacementagency.com'],
            [
                'company_name'     => 'Global Placement Overseas Agency',
                'contact_person'   => 'Elena Dela Rosa',
                'password'         => Hash::make('password123'),
                'employer_type'    => 'overseas',
                'dmw_license_path' => 'DMW-012-LB-031524-R',
                'industry'         => 'Other Community, Social and Personal Service Activities',
                'company_size'     => '51-200',
                'business_type'    => 'Corporation',
                'founded'          => 2012,
                'barangay'         => 'Ermita',
                'city'             => 'Manila',
                'province'         => 'Metro Manila',
                'address_full'     => 'Ermita, Manila, Metro Manila',
                'tin'              => '102-349-876-000',
                'website'          => 'https://globalplacementagency.com',
                'phone'            => '09171239999',
                'status'           => 'verified',
                'verified_at'      => now()->subDays(30),
                'total_hired'      => 12,
            ]
        );

        $agency2 = Employer::updateOrCreate(
            ['email' => 'recruitment@transasiaoverseas.com'],
            [
                'company_name'     => 'TransAsia Overseas Manpower Services',
                'contact_person'   => 'Ricardo Garcia',
                'password'         => Hash::make('password123'),
                'employer_type'    => 'overseas',
                'dmw_license_path' => 'DMW-045-LB-082023-R',
                'industry'         => 'Construction',
                'company_size'     => '201-500',
                'business_type'    => 'Corporation',
                'founded'          => 2008,
                'barangay'         => 'Cubao',
                'city'             => 'Quezon City',
                'province'         => 'Metro Manila',
                'address_full'     => 'Cubao, Quezon City, Metro Manila',
                'tin'              => '235-891-440-000',
                'website'          => 'https://transasiaoverseas.com',
                'phone'            => '09188887777',
                'status'           => 'verified',
                'verified_at'      => now()->subDays(45),
                'total_hired'      => 18,
            ]
        );

        $agency3 = Employer::updateOrCreate(
            ['email' => 'info@pacificrimrecruitment.com'],
            [
                'company_name'     => 'Pacific Rim Manpower Recruitment',
                'contact_person'   => 'Maria Victoria Santos',
                'password'         => Hash::make('password123'),
                'employer_type'    => 'overseas',
                'dmw_license_path' => 'DMW-089-LB-110222-R',
                'industry'         => 'Hotels and Restaurants',
                'company_size'     => '51-200',
                'business_type'    => 'Corporation',
                'founded'          => 2015,
                'barangay'         => 'San Antonio',
                'city'             => 'Makati City',
                'province'         => 'Metro Manila',
                'address_full'     => 'San Antonio, Makati City, Metro Manila',
                'tin'              => '421-558-912-000',
                'website'          => 'https://pacificrimrecruitment.com',
                'phone'            => '09197776666',
                'status'           => 'verified',
                'verified_at'      => now()->subDays(20),
                'total_hired'      => 8,
            ]
        );

        // 2. Define Overseas Job Postings
        $overseasJobs = [
            [
                'employer_id'         => $agency1->id,
                'employer_name'       => $agency1->company_name,
                'title'               => 'Staff Nurse (Registered Nurse)',
                'type'                => 'full-time',
                'is_overseas'         => true,
                'salary_range'        => 'SAR 4,500 - 6,000 / month',
                'location'            => 'Riyadh, Saudi Arabia',
                'education_level'     => 'college_graduate',
                'experience_required' => '2_years',
                'slots'               => 15,
                'posted_date'         => now()->subDays(12),
                'deadline'            => now()->addDays(28),
                'status'              => 'open',
                'description'         => 'Urgent hiring for licensed Staff Nurses for premier tertiary medical centers in Riyadh. Requirements: BSN, valid PRC Nurse License, minimum 2 years hospital bed-capacity experience, DMW/POEA processing clearance ready. Free accommodation, transportation allowance, medical coverage, and round-trip flight tickets provided under DMW contract.',
                'skills'              => ['Patient Care', 'ICU / Ward Nursing', 'Basic Life Support (BLS)', 'Medical Documentation', 'Patient Assessment', 'Nursing'],
            ],
            [
                'employer_id'         => $agency2->id,
                'employer_name'       => $agency2->company_name,
                'title'               => 'Electrical Maintenance Technician',
                'type'                => 'full-time',
                'is_overseas'         => true,
                'salary_range'        => 'QAR 3,500 - 4,800 / month',
                'location'            => 'Doha, Qatar',
                'education_level'     => 'vocational',
                'experience_required' => '2_years',
                'slots'               => 20,
                'posted_date'         => now()->subDays(8),
                'deadline'            => now()->addDays(30),
                'status'              => 'open',
                'description'         => 'Hiring qualified Electrical Technicians for commercial tower maintenance in Doha. Requirements: TESDA NC II / NC III in Electrical Installation & Maintenance, at least 2 years industrial or building electrical maintenance experience. Fully compliant DMW employment package.',
                'skills'              => ['Electrical Maintenance', 'Circuit Troubleshooting', 'TESDA NC II Electrical', 'Industrial Wiring', 'Safety Compliance', 'Electrical'],
            ],
            [
                'employer_id'         => $agency3->id,
                'employer_name'       => $agency3->company_name,
                'title'               => 'Hotel Food & Beverage Attendant',
                'type'                => 'full-time',
                'is_overseas'         => true,
                'salary_range'        => 'AED 3,200 - 4,500 / month',
                'location'            => 'Dubai, United Arab Emirates',
                'education_level'     => 'college_level',
                'experience_required' => '1_year',
                'slots'               => 10,
                'posted_date'         => now()->subDays(6),
                'deadline'            => now()->addDays(25),
                'status'              => 'open',
                'description'         => 'Immediate openings for 5-Star luxury resort in Dubai Marina. Duties include guest food service, order taking, table setup, and maintaining dining area standards. Requirements: HRM / Tourism degree or diploma, 1 year hotel experience, fluent English. Provided: duty meals, shared apartment accommodation, and flight allowance.',
                'skills'              => ['Customer Service', 'Food Safety & Hygiene', 'Table Service', 'POS System Operation', 'English Communication', 'Food Safety'],
            ],
        ];

        $createdJobs = [];

        foreach ($overseasJobs as $jobData) {
            $skills = $jobData['skills'];
            unset($jobData['skills']);

            $job = JobListing::updateOrCreate(
                [
                    'employer_id' => $jobData['employer_id'],
                    'title'       => $jobData['title'],
                ],
                $jobData
            );

            JobSkill::where('job_listing_id', $job->id)->delete();
            foreach ($skills as $skillName) {
                JobSkill::create([
                    'job_listing_id' => $job->id,
                    'skill'          => $skillName,
                ]);
            }

            $createdJobs[] = $job;
        }

        // ── Seed Applicants for Overseas Jobs ──
        $jobseekers = Jobseeker::with('skills')->get();
        if ($jobseekers->isEmpty()) {
            return;
        }

        $statuses = ['reviewing', 'shortlisted', 'interview', 'for_job_offer', 'hired', 'rejected'];

        foreach ($createdJobs as $job) {
            $assigned = 0;
            foreach ($jobseekers as $seeker) {
                if ($assigned >= 8) {
                    break;
                }

                $exists = Application::where('job_listing_id', $job->id)
                    ->where('jobseeker_id', $seeker->id)
                    ->exists();

                if ($exists) {
                    continue;
                }

                $matchScore = Application::calculateMatchScore($seeker, $job);
                if ($matchScore === 0) {
                    $matchScore = rand(55, 90);
                }

                $status = $statuses[$assigned % count($statuses)];

                $app = Application::create([
                    'job_listing_id' => $job->id,
                    'jobseeker_id'   => $seeker->id,
                    'status'         => $status,
                    'match_score'    => $matchScore,
                    'applied_at'     => now()->subDays(rand(1, 15)),
                ]);

                ApplicationActivityLog::create([
                    'application_id' => $app->id,
                    'actor_type'     => 'employer',
                    'actor_label'    => $job->employer->company_name ?? 'Overseas Agency',
                    'action'         => $status === 'for_job_offer' ? 'For Job Offer' : ucfirst($status),
                    'created_at'     => $app->applied_at,
                ]);

                $assigned++;
            }
        }
    }
}
