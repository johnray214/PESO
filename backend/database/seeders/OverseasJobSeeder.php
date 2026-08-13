<?php

namespace Database\Seeders;

use App\Models\Employer;
use App\Models\JobListing;
use App\Models\JobSkill;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class OverseasJobSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create or get Overseas Recruitment Agency Employers
        $agency1 = Employer::firstOrCreate(
            ['email' => 'contact@globalplacementagency.com'],
            [
                'company_name'   => 'Global Placement Overseas Agency',
                'contact_person' => 'Elena Dela Rosa',
                'password'       => Hash::make('password'),
                'employer_type'  => 'overseas',
                'dmw_license_path' => 'DMW-012-LB-031524-R',
                'industry'       => 'Other Community, Social and Personal Service Activities',
                'company_size'   => '51-200',
                'business_type'  => 'Corporation',
                'founded'        => 2012,
                'city'           => 'Santiago City',
                'province'       => 'Isabela',
                'address_full'   => 'Santiago City, Isabela',
                'phone'          => '09171239999',
                'status'         => 'verified',
                'verified_at'    => now(),
            ]
        );

        $agency2 = Employer::firstOrCreate(
            ['email' => 'recruitment@transasiaoverseas.com'],
            [
                'company_name'   => 'TransAsia Overseas Manpower Services',
                'contact_person' => 'Ricardo Garcia',
                'password'       => Hash::make('password'),
                'employer_type'  => 'overseas',
                'dmw_license_path' => 'DMW-045-LB-082023-R',
                'industry'       => 'Construction',
                'company_size'   => '201-500',
                'business_type'  => 'Corporation',
                'founded'        => 2008,
                'city'           => 'Santiago City',
                'province'       => 'Isabela',
                'address_full'   => 'Santiago City, Isabela',
                'phone'          => '09188887777',
                'status'         => 'verified',
                'verified_at'    => now(),
            ]
        );

        $agency3 = Employer::firstOrCreate(
            ['email' => 'info@pacificrimrecruitment.com'],
            [
                'company_name'   => 'Pacific Rim Manpower Recruitment',
                'contact_person' => 'Maria Victoria Santos',
                'password'       => Hash::make('password'),
                'employer_type'  => 'overseas',
                'dmw_license_path' => 'DMW-089-LB-110222-R',
                'industry'       => 'Hotels and Restaurants',
                'company_size'   => '51-200',
                'business_type'  => 'Corporation',
                'founded'        => 2015,
                'city'           => 'Santiago City',
                'province'       => 'Isabela',
                'address_full'   => 'Santiago City, Isabela',
                'phone'          => '09197776666',
                'status'         => 'verified',
                'verified_at'    => now(),
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
                'posted_date'         => now()->subDays(2),
                'deadline'            => now()->addDays(28),
                'status'              => 'open',
                'description'         => 'Urgent hiring for licensed Staff Nurses for premier tertiary medical centers in Riyadh. Requirements: BSN, valid PRC Nurse License, minimum 2 years hospital bed-capacity experience, DMW/POEA processing clearance ready. Free accommodation, transportation allowance, medical coverage, and round-trip flight tickets provided under DMW contract.',
                'skills' => ['Patient Care', 'ICU / Ward Nursing', 'Basic Life Support (BLS)', 'Medical Documentation', 'Patient Assessment'],
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
                'posted_date'         => now()->subDays(1),
                'deadline'            => now()->addDays(30),
                'status'              => 'open',
                'description'         => 'Hiring qualified Electrical Technicians for commercial tower maintenance in Doha. Requirements: TESDA NC II / NC III in Electrical Installation & Maintenance, at least 2 years industrial or building electrical maintenance experience. Fully compliant DMW employment package.',
                'skills' => ['Electrical Maintenance', 'Circuit Troubleshooting', 'TESDA NC II Electrical', 'Industrial Wiring', 'Safety Compliance'],
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
                'posted_date'         => now(),
                'deadline'            => now()->addDays(25),
                'status'              => 'open',
                'description'         => 'Immediate openings for 5-Star luxury resort in Dubai Marina. Duties include guest food service, order taking, table setup, and maintaining dining area standards. Requirements: HRM / Tourism degree or diploma, 1 year hotel experience, fluent English. Provided: duty meals, shared apartment accommodation, and flight allowance.',
                'skills' => ['Customer Service', 'Food Safety & Hygiene', 'Table Service', 'POS System Operation', 'English Communication'],
            ],
        ];

        foreach ($overseasJobs as $jobData) {
            $skills = $jobData['skills'];
            unset($jobData['skills']);

            $job = JobListing::create($jobData);

            foreach ($skills as $skillName) {
                JobSkill::create([
                    'job_listing_id' => $job->id,
                    'skill'          => $skillName,
                ]);
            }
        }
    }
}
