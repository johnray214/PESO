<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Employer;
use App\Models\Jobseeker;
use App\Models\JobseekerSkill;
use App\Models\JobListing;
use App\Models\JobSkill;
use App\Models\Application;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1 Admin user
        User::create([
            'first_name' => 'System',
            'middle_name' => null,
            'last_name' => 'Administrator',
            'email' => 'admin@peso.gov.ph',
            'password' => Hash::make('password123'),
            'role' => 'admin',
            'sex' => 'male',
            'contact' => '09171234567',
            'address' => 'PESO Main Office, Manila',
            'status' => 'active',
        ]);

        // 3 Staff users
        $staffUsers = [
            ['first_name' => 'Maria', 'last_name' => 'Santos', 'email' => 'maria.santos@peso.gov.ph', 'sex' => 'female'],
            ['first_name' => 'Juan', 'last_name' => 'Dela Cruz', 'email' => 'juan.delacruz@peso.gov.ph', 'sex' => 'male'],
            ['first_name' => 'Ana', 'last_name' => 'Reyes', 'email' => 'ana.reyes@peso.gov.ph', 'sex' => 'female'],
        ];

        foreach ($staffUsers as $staff) {
            User::create([
                'first_name' => $staff['first_name'],
                'middle_name' => null,
                'last_name' => $staff['last_name'],
                'email' => $staff['email'],
                'password' => Hash::make('password123'),
                'role' => 'staff',
                'sex' => $staff['sex'],
                'contact' => '09' . rand(100000000, 999999999),
                'address' => 'PESO Office, Manila',
                'status' => 'active',
            ]);
        }

        // 5 Sample employers (approved)
        $employers = [
            [
                'company_name' => 'Nexus Tech Solutions',
                'contact_person' => 'Carlo Mendoza',
                'email' => 'hr@nexustech.ph',
                'industry' => 'Information Technology',
                'company_size' => '50-200',
                'city' => 'Makati',
                'phone' => '02-8123456',
                'tin' => '123-456-789-000',
                'website' => 'https://nexustech.ph',
                'latitude' => 14.5547,
                'longitude' => 121.0244,
                'address_full' => '123 Ayala Avenue, Makati City',
            ],
            [
                'company_name' => 'Global Innovations Inc.',
                'contact_person' => 'Sarah Lim',
                'email' => 'careers@globalinnovations.com',
                'industry' => 'Software Development',
                'company_size' => '200-500',
                'city' => 'Taguig',
                'phone' => '02-8987654',
                'tin' => '234-567-890-000',
                'website' => 'https://globalinnovations.com',
                'latitude' => 14.5176,
                'longitude' => 121.0500,
                'address_full' => 'Bonifacio Global City, Taguig',
            ],
            [
                'company_name' => 'Creative Designs Studio',
                'contact_person' => 'Liza Tan',
                'email' => 'jobs@creativedesigns.ph',
                'industry' => 'Design & Creative',
                'company_size' => '10-50',
                'city' => 'Quezon City',
                'phone' => '02-7123456',
                'tin' => '345-678-901-000',
                'website' => 'https://creativedesigns.ph',
                'latitude' => 14.6760,
                'longitude' => 121.0437,
                'address_full' => '45 Maginhawa St, Quezon City',
            ],
            [
                'company_name' => 'DataStream Analytics',
                'contact_person' => 'Michael Cruz',
                'email' => 'hiring@datastream.io',
                'industry' => 'Data Analytics',
                'company_size' => '50-200',
                'city' => 'Pasig',
                'phone' => '02-6345678',
                'tin' => '456-789-012-000',
                'website' => 'https://datastream.io',
                'latitude' => 14.5764,
                'longitude' => 121.0851,
                'address_full' => 'Ortigas Center, Pasig City',
            ],
            [
                'company_name' => 'CloudScale Systems',
                'contact_person' => 'Patricia Garcia',
                'email' => 'talent@cloudscale.ph',
                'industry' => 'Cloud Computing',
                'company_size' => '500+',
                'city' => 'Mandaluyong',
                'phone' => '02-7234567',
                'tin' => '567-890-123-000',
                'website' => 'https://cloudscale.ph',
                'latitude' => 14.5853,
                'longitude' => 121.0373,
                'address_full' => 'EDSA Corner Shaw Blvd, Mandaluyong',
            ],
        ];

        $employerModels = [];
        foreach ($employers as $employerData) {
            $employerModels[] = Employer::create([
                ...$employerData,
                'password' => Hash::make('password123'),
                'status' => 'verified',
                'verified_at' => now(),
                'map_visible' => true,
            ]);
        }

        // 10 Sample jobseekers with skills and verified emails
        $jobseekersData = [
            ['first_name' => 'Sofia', 'last_name' => 'Ramos', 'email' => 'sofia.ramos@email.com', 'sex' => 'female', 'skills' => ['Vue.js', 'Nuxt', 'SCSS', 'JavaScript']],
            ['first_name' => 'Marco', 'last_name' => 'Villanueva', 'email' => 'marco.v@email.com', 'sex' => 'male', 'skills' => ['Docker', 'CI/CD', 'Linux', 'AWS']],
            ['first_name' => 'Dante', 'last_name' => 'Cruz', 'email' => 'dante.cruz@email.com', 'sex' => 'male', 'skills' => ['Scrum', 'MS Project', 'Risk Management', 'Agile']],
            ['first_name' => 'Rina', 'last_name' => 'Flores', 'email' => 'rina.flores@email.com', 'sex' => 'female', 'skills' => ['React', 'Tailwind', 'Git', 'TypeScript']],
            ['first_name' => 'Ben', 'last_name' => 'Ocampo', 'email' => 'ben.ocampo@email.com', 'sex' => 'male', 'skills' => ['Laravel', 'PHP', 'MySQL', 'Redis']],
            ['first_name' => 'Grace', 'last_name' => 'Dela Rosa', 'email' => 'grace.delarosa@email.com', 'sex' => 'female', 'skills' => ['Figma', 'Prototyping', 'Sketch', 'Adobe XD']],
            ['first_name' => 'Nico', 'last_name' => 'Santos', 'email' => 'nico.santos@email.com', 'sex' => 'male', 'skills' => ['Kubernetes', 'AWS', 'Terraform', 'Docker']],
            ['first_name' => 'Elle', 'last_name' => 'Reyes', 'email' => 'elle.reyes@email.com', 'sex' => 'female', 'skills' => ['Agile', 'Jira', 'Team Leadership', 'Scrum']],
            ['first_name' => 'Paolo', 'last_name' => 'Garcia', 'email' => 'paolo.garcia@email.com', 'sex' => 'male', 'skills' => ['Python', 'Django', 'PostgreSQL', 'Redis']],
            ['first_name' => 'Maya', 'last_name' => 'Lopez', 'email' => 'maya.lopez@email.com', 'sex' => 'female', 'skills' => ['UI/UX Design', 'Figma', 'User Research', 'Prototyping']],
        ];

        $jobseekerModels = [];
        foreach ($jobseekersData as $jsData) {
            $skills = $jsData['skills'];
            unset($jsData['skills']);

            $jobseeker = Jobseeker::create([
                ...$jsData,
                'password' => Hash::make('password123'),
                'email_verified_at' => now(),
                'contact' => '09' . rand(100000000, 999999999),
                'address' => 'Metro Manila, Philippines',
                'status' => 'active',
                'latitude' => 14.5995 + (rand(-100, 100) / 1000),
                'longitude' => 120.9842 + (rand(-100, 100) / 1000),
            ]);

            foreach ($skills as $skill) {
                JobseekerSkill::create([
                    'jobseeker_id' => $jobseeker->id,
                    'skill' => $skill,
                ]);
            }

            $jobseekerModels[] = $jobseeker;
        }

        // 15 Job listings
        $jobListingsData = [
            ['employer_id' => 1, 'title' => 'Senior Frontend Developer', 'type' => 'full-time', 'location' => 'Makati', 'skills' => ['Vue.js', 'JavaScript', 'CSS']],
            ['employer_id' => 1, 'title' => 'Backend Developer', 'type' => 'full-time', 'location' => 'Makati', 'skills' => ['Laravel', 'PHP', 'MySQL']],
            ['employer_id' => 1, 'title' => 'DevOps Engineer', 'type' => 'full-time', 'location' => 'Makati', 'skills' => ['AWS', 'Docker', 'Kubernetes']],
            ['employer_id' => 2, 'title' => 'Full Stack Developer', 'type' => 'full-time', 'location' => 'Taguig', 'skills' => ['React', 'Node.js', 'MongoDB']],
            ['employer_id' => 2, 'title' => 'UI/UX Designer', 'type' => 'full-time', 'location' => 'Taguig', 'skills' => ['Figma', 'UI/UX', 'Adobe XD']],
            ['employer_id' => 2, 'title' => 'Product Manager', 'type' => 'full-time', 'location' => 'Taguig', 'skills' => ['Agile', 'Scrum', 'JIRA']],
            ['employer_id' => 3, 'title' => 'Graphic Designer', 'type' => 'contract', 'location' => 'Quezon City', 'skills' => ['Adobe Photoshop', 'Illustrator', 'Figma']],
            ['employer_id' => 3, 'title' => 'Web Designer', 'type' => 'part-time', 'location' => 'Quezon City', 'skills' => ['HTML', 'CSS', 'Figma']],
            ['employer_id' => 4, 'title' => 'Data Analyst', 'type' => 'full-time', 'location' => 'Pasig', 'skills' => ['Python', 'SQL', 'Tableau']],
            ['employer_id' => 4, 'title' => 'Data Engineer', 'type' => 'full-time', 'location' => 'Pasig', 'skills' => ['Python', 'PostgreSQL', 'AWS']],
            ['employer_id' => 5, 'title' => 'Cloud Architect', 'type' => 'full-time', 'location' => 'Mandaluyong', 'skills' => ['AWS', 'Terraform', 'Kubernetes']],
            ['employer_id' => 5, 'title' => 'Site Reliability Engineer', 'type' => 'full-time', 'location' => 'Mandaluyong', 'skills' => ['Linux', 'Docker', 'CI/CD']],
            ['employer_id' => 1, 'title' => 'Mobile App Developer', 'type' => 'full-time', 'location' => 'Makati', 'skills' => ['React Native', 'JavaScript', 'Firebase']],
            ['employer_id' => 2, 'title' => 'QA Engineer', 'type' => 'full-time', 'location' => 'Taguig', 'skills' => ['Selenium', 'Testing', 'Automation']],
            ['employer_id' => 3, 'title' => 'Motion Designer', 'type' => 'contract', 'location' => 'Quezon City', 'skills' => ['After Effects', 'Cinema 4D', 'Figma']],
        ];

        $jobListingModels = [];
        foreach ($jobListingsData as $jobData) {
            $skills = $jobData['skills'];
            unset($jobData['skills']);

            $job = JobListing::create([
                ...$jobData,
                'description' => 'We are looking for a talented ' . $jobData['title'] . ' to join our team. The ideal candidate will have strong skills in ' . implode(', ', $skills) . '.',
                'salary_range' => '₱30,000 - ₱80,000',
                'slots' => rand(1, 5),
                'status' => 'open',
                'posted_date' => now()->subDays(rand(1, 30)),
                'deadline' => now()->addDays(rand(15, 60)),
            ]);

            foreach ($skills as $skill) {
                JobSkill::create([
                    'job_listing_id' => $job->id,
                    'skill' => $skill,
                ]);
            }

            $jobListingModels[] = $job;
        }

        // 30 Applications
        $statuses = ['reviewing', 'shortlisted', 'interview', 'hired', 'rejected'];
        $applicationsCreated = 0;

        for ($i = 0; $i < 30; $i++) {
            $jobseeker = $jobseekerModels[array_rand($jobseekerModels)];
            $jobListing = $jobListingModels[array_rand($jobListingModels)];

            // Check if application already exists
            $existing = Application::where('job_listing_id', $jobListing->id)
                ->where('jobseeker_id', $jobseeker->id)
                ->first();

            if (!$existing) {
                $matchScore = Application::calculateMatchScore($jobseeker, $jobListing);

                Application::create([
                    'job_listing_id' => $jobListing->id,
                    'jobseeker_id' => $jobseeker->id,
                    'status' => $statuses[array_rand($statuses)],
                    'match_score' => $matchScore,
                    'applied_at' => now()->subDays(rand(1, 20)),
                ]);

                $applicationsCreated++;
            }
        }

        $this->command->info("Created: 1 admin, 3 staff users, 5 employers, 10 jobseekers, 15 job listings, {$applicationsCreated} applications");

        // Seed notifications for all employers
        $this->call(NotificationSeeder::class);

        // Seed events
        $this->call(EventSeeder::class);
    }
}
