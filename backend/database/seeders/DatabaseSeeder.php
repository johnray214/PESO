<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            UserSeeder::class,          // Admin & staff accounts
            EmployerSeeder::class,      // Local employers + job listings + job skills
            JobseekerSeeder::class,     // Jobseekers + skills + education/demographics
            OverseasJobSeeder::class,   // Overseas recruitment agencies + overseas job listings + overseas applicants
            DoleProgramSeeder::class,   // DOLE programs (SPES, GIP, TUPAD, JobStart) listings & student applicants
            ApplicationSeeder::class,   // Skill-matched applications with real scores & logs
            NotificationSeeder::class,  // PESO notifications for employers & jobseekers
            EventSeeder::class,         // PESO events (job fairs, trainings, etc.)
            SkillCatalogSeeder::class,  // Skill catalog (auto-built from job_skills & jobseeker_skills)
            LegsFeedbackSeeder::class,  // LEGS Feedback records for reporting
        ]);
    }
}
