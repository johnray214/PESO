<?php

namespace Database\Seeders;

use App\Models\LegsFeedback;
use Illuminate\Database\Seeder;

class LegsFeedbackSeeder extends Seeder
{
    public function run(): void
    {
        $feedbacks = [
            ['first_name' => 'Maria', 'last_name' => 'Santos', 'program' => 'TUPAD (Tulong Panghanapbuhay sa Ating Disadvantaged/Displaced Workers)', 'venue' => 'Online', 'rating_program_content' => 5, 'rating_interaction' => 5, 'rating_mastery' => 5, 'rating_overall' => 5, 'remarks' => 'Very helpful and easy to use!', 'activity_date' => now()->subDays(30)],
            ['first_name' => 'Nexus', 'last_name' => 'Tech', 'program' => 'Job Fair Services Assistance', 'venue' => 'Online', 'rating_program_content' => 4, 'rating_interaction' => 4, 'rating_mastery' => 4, 'rating_overall' => 4, 'remarks' => 'Good platform, minor UX issues.', 'activity_date' => now()->subDays(25)],
            ['first_name' => 'Ana', 'last_name' => 'Reyes', 'program' => 'LEGP (Livelihood Enhancement and Growth Program)', 'venue' => 'PESO Office', 'rating_program_content' => 5, 'rating_interaction' => 5, 'rating_mastery' => 5, 'rating_overall' => 5, 'remarks' => 'Found a job in less than a week!', 'activity_date' => now()->subDays(20)],
            ['first_name' => 'Pedro', 'last_name' => 'Lim', 'program' => 'PEIS and Philjobnet Services', 'venue' => 'Online', 'rating_program_content' => 3, 'rating_interaction' => 3, 'rating_mastery' => 3, 'rating_overall' => 3, 'remarks' => 'Job listings could be more updated.', 'activity_date' => now()->subDays(15)],
            ['first_name' => 'BrightPath', 'last_name' => 'BPO', 'program' => 'Company Accreditation Services', 'venue' => 'PESO Office', 'rating_program_content' => 4, 'rating_interaction' => 5, 'rating_mastery' => 4, 'rating_overall' => 4, 'remarks' => 'Quality applicants, great filtering.', 'activity_date' => now()->subDays(10)],
            ['first_name' => 'Rosa', 'last_name' => 'Garcia', 'program' => 'Career Guidance for Grade 10', 'venue' => 'Online', 'rating_program_content' => 2, 'rating_interaction' => 2, 'rating_mastery' => 2, 'rating_overall' => 2, 'remarks' => 'Had trouble uploading my resume.', 'activity_date' => now()->subDays(5)],
        ];

        foreach ($feedbacks as $fb) {
            LegsFeedback::create($fb);
        }
        
        $validPrograms = [
            'SRA (Special Recruitment Activity)', 'LRA (Local Recruitment Activity)', 'Job Fair Services Assistance',
            'Career Guidance for Grade 10', 'Career Exploration for Grade 12', 'LEGS', 'Pre Employment Orientation', 'Career Information, Education, and Advocacy', 'TAV/BOSH/OSH Training',
            'PEIS and Philjobnet Services', 'Job Vacancy Solicitation Services', 'Company Accreditation Services',
            'LEGP (Livelihood Enhancement and Growth Program)', 'TUPAD (Tulong Panghanapbuhay sa Ating Disadvantaged/Displaced Workers)', 'GIP (Government Internship Program)', 'SPES (Special Program for Employment of Students)', 'Jobstart PH', 'TESDA Scholarship Program',
            'WODP (Workers Organization Development Program)', 'DILEEP (Developing Industry-Led and Enterprise-based Programs)', 'OFW Reintegration Services'
        ];

        // Generate a bunch of random feedback entries as well to have "numbers"
        for ($i = 0; $i < 20; $i++) {
            $randomScore = rand(3, 5); // mostly positive
            LegsFeedback::create([
                'first_name' => 'User' . $i,
                'last_name' => 'Test',
                'program' => $validPrograms[array_rand($validPrograms)],
                'venue' => ['Online', 'PESO Office', 'Barangay Hall', 'City Hall Auditorium'][array_rand(['Online', 'PESO Office', 'Barangay Hall', 'City Hall Auditorium'])],
                'rating_program_content' => $randomScore,
                'rating_interaction' => $randomScore,
                'rating_mastery' => $randomScore,
                'rating_overall' => $randomScore,
                'remarks' => ['Good', 'Very useful', 'Needs improvement', 'Excellent'][array_rand(['Good', 'Very useful', 'Needs improvement', 'Excellent'])],
                'activity_date' => now()->subDays(rand(1, 40)),
            ]);
        }
    }
}
