<?php

namespace Database\Seeders;

use App\Models\JobApplication;
use App\Models\JobListing;
use App\Models\User;
use Illuminate\Database\Seeder;

class JobApplicationSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::all();
        $jobs  = JobListing::where('is_active', true)->get();

        if ($users->isEmpty() || $jobs->isEmpty()) {
            $this->command->warn('No users or job listings found. Skipping JobApplicationSeeder.');
            return;
        }

        $applications = [
            // Maria Santos → Software Developer
            [
                'user_email'    => 'maria.santos@email.com',
                'job_title'     => 'Software Developer',
                'status'        => 'Registration',
                'employer_status'=> 'shortlisted',
                'employer_notes'=> 'Strong Vue.js background. Schedule technical interview.',
                'match_score'   => 92,
                'applied_at'    => now()->subDays(12),
            ],
            // Juan dela Cruz → Customer Service
            [
                'user_email'    => 'juan.delacruz@email.com',
                'job_title'     => 'Customer Service Representative',
                'status'        => 'Registration',
                'employer_status'=> 'interview',
                'employer_notes'=> 'Good communication skills. Invited for final interview.',
                'match_score'   => 85,
                'applied_at'    => now()->subDays(8),
            ],
            // Ana Garcia → Accounting
            [
                'user_email'    => 'ana.garcia@email.com',
                'job_title'     => 'Accounting Staff',
                'status'        => 'Hired',
                'employer_status'=> 'hired',
                'employer_notes'=> 'Excellent interview performance. Welcome aboard.',
                'match_score'   => 96,
                'applied_at'    => now()->subDays(25),
            ],
            // Pedro Reyes → Electrician
            [
                'user_email'    => 'pedro.reyes@email.com',
                'job_title'     => 'Electrician',
                'status'        => 'Registration',
                'employer_status'=> 'reviewing',
                'employer_notes'=> null,
                'match_score'   => 78,
                'applied_at'    => now()->subDays(5),
            ],
            // Rosa Mendoza → Food Service
            [
                'user_email'    => 'rosa.mendoza@email.com',
                'job_title'     => 'Restaurant Crew',
                'status'        => 'Hired',
                'employer_status'=> 'hired',
                'employer_notes'=> 'Experienced crew member. Promoted to assistant manager track.',
                'match_score'   => 90,
                'applied_at'    => now()->subDays(30),
            ],
            // Carlos Bautista → IT/Network
            [
                'user_email'    => 'carlos.bautista@email.com',
                'job_title'     => 'Network Administrator',
                'status'        => 'Placed',
                'employer_status'=> 'hired',
                'employer_notes'=> 'Senior level candidate. Immediate placement.',
                'match_score'   => 94,
                'applied_at'    => now()->subDays(18),
            ],
            // Liza Fernandez → Administrative
            [
                'user_email'    => 'liza.fernandez@email.com',
                'job_title'     => 'Administrative Assistant',
                'status'        => 'Registration',
                'employer_status'=> 'reviewing',
                'employer_notes'=> null,
                'match_score'   => 70,
                'applied_at'    => now()->subDays(3),
            ],
            // Mark Villanueva → Graphic Designer
            [
                'user_email'    => 'mark.villanueva@email.com',
                'job_title'     => 'Graphic Designer',
                'status'        => 'Rejected',
                'employer_status'=> 'rejected',
                'employer_notes'=> 'Salary expectation did not match current budget.',
                'match_score'   => 82,
                'applied_at'    => now()->subDays(20),
            ],
            // Elena Cruz → Nurse/Healthcare
            [
                'user_email'    => 'elena.cruz@email.com',
                'job_title'     => 'Registered Nurse',
                'status'        => 'Hired',
                'employer_status'=> 'hired',
                'employer_notes'=> 'Very experienced. Hired immediately.',
                'match_score'   => 98,
                'applied_at'    => now()->subDays(15),
            ],
            // Roberto Tan → Driver/Logistics
            [
                'user_email'    => 'roberto.tan@email.com',
                'job_title'     => 'Delivery Driver',
                'status'        => 'Registration',
                'employer_status'=> 'shortlisted',
                'employer_notes'=> 'Clean driving record. Background check in progress.',
                'match_score'   => 88,
                'applied_at'    => now()->subDays(6),
            ],
            // Jenny Pascual → Social Work/Admin
            [
                'user_email'    => 'jenny.pascual@email.com',
                'job_title'     => 'Administrative Assistant',
                'status'        => 'Placed',
                'employer_status'=> 'hired',
                'employer_notes'=> 'Placed as social welfare assistant.',
                'match_score'   => 76,
                'applied_at'    => now()->subDays(22),
            ],
            // Dennis Agustin → Welding/Construction
            [
                'user_email'    => 'dennis.agustin@email.com',
                'job_title'     => 'Welder',
                'status'        => 'Registration',
                'employer_status'=> 'interview',
                'employer_notes'=> 'Skilled welder. Skills test scheduled.',
                'match_score'   => 91,
                'applied_at'    => now()->subDays(9),
            ],
        ];

        foreach ($applications as $appData) {
            $user = User::where('email', $appData['user_email'])->first();
            if (!$user) continue;

            // Find a matching job by title (partial match)
            $job = $jobs->first(fn($j) => stripos($j->title, explode(' ', $appData['job_title'])[0]) !== false);
            if (!$job) {
                $job = $jobs->random();
            }

            // Avoid duplicate applications (unique constraint on user_id + job_listing_id)
            $exists = JobApplication::where('user_id', $user->id)
                ->where('job_listing_id', $job->id)
                ->exists();

            if (!$exists) {
                JobApplication::create([
                    'user_id'         => $user->id,
                    'job_listing_id'  => $job->id,
                    'status'          => $appData['status'],
                    'employer_status' => $appData['employer_status'],
                    'employer_notes'  => $appData['employer_notes'],
                    'match_score'     => $appData['match_score'],
                    'applied_at'      => $appData['applied_at'],
                ]);
            }
        }
    }
}
