<?php

namespace Database\Seeders;

use App\Models\Skill;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class SkillCatalogSeeder extends Seeder
{
    private const PRESET_SKILLS = [
        'Information Technology' => [
            'PHP', 'Laravel', 'JavaScript', 'TypeScript', 'Vue.js', 'React', 'Node.js', 'Python',
            'C#', 'Java', 'MySQL', 'PostgreSQL', 'REST API', 'Git', 'Docker', 'Linux',
            'Quality Assurance', 'Manual Testing', 'Automation Testing', 'Cybersecurity',
            'Network Administration', 'Cloud Computing', 'Data Analysis', 'UI Design', 'UX Research',
        ],
        'Business and Office' => [
            'Administrative Support', 'MS Office', 'Data Entry', 'Bookkeeping', 'Payroll Processing',
            'Accounting', 'Procurement', 'Inventory Management', 'Project Coordination',
            'Customer Service', 'Sales', 'Business Writing', 'Presentation Skills', 'Negotiation',
            'Report Preparation',
        ],
        'Construction and Engineering' => [
            'AutoCAD', 'Civil Engineering', 'Structural Analysis', 'Project Management',
            'Construction Safety', 'Masonry', 'Carpentry', 'Welding', 'Electrical Installation',
            'Plumbing', 'Heavy Equipment Operation', 'Quantity Surveying', 'Site Supervision',
        ],
        'Hospitality and Tourism' => [
            'Front Desk Operations', 'Housekeeping', 'Food and Beverage Service', 'Bartending',
            'Barista', 'Tour Guiding', 'Reservation Management', 'Event Coordination',
            'Guest Relations', 'Kitchen Operations',
        ],
        'Logistics and Transport' => [
            'Driving', 'Defensive Driving', 'Route Planning', 'Fleet Coordination',
            'Warehouse Operations', 'Forklift Operation', 'Dispatching', 'Cargo Handling',
            'Inventory Auditing', 'Supply Chain Coordination',
        ],
        'Healthcare and Wellness' => [
            'Nursing Care', 'Patient Care', 'First Aid', 'Phlebotomy', 'Medical Records',
            'Caregiving', 'Pharmacy Assistance', 'Clinic Administration', 'Health Education',
        ],
        'Agriculture and Fisheries' => [
            'Farming', 'Harvesting', 'Irrigation', 'Pest Control', 'Soil Science', 'Crop Management',
            'Aquaculture', 'Fisheries Operations', 'Post-Harvest Handling', 'Agricultural Machinery',
        ],
        'Creative and Media' => [
            'Graphic Design', 'Adobe Photoshop', 'Adobe Illustrator', 'Canva', 'Video Editing',
            'Photography', 'Copywriting', 'Content Creation', 'Social Media Management',
            'Branding', 'SEO',
        ],
        'Manufacturing and Production' => [
            'Machine Operation', 'Quality Control', 'Food Safety', 'Packaging', 'Sanitation',
            'Production Planning', 'Lean Manufacturing', '5S', 'Safety Compliance',
        ],
        'Public Service and Community' => [
            'Community Organizing', 'Case Management', 'Facilitation', 'Public Communication',
            'Documentation', 'Program Implementation', 'Training Delivery', 'Stakeholder Engagement',
        ],
    ];

    private function normaliseName(string $name): string
    {
        $name = trim(preg_replace('/\s+/', ' ', $name) ?? '');
        return $name;
    }

    private function slugFor(string $name): string
    {
        $slug = Str::slug(mb_strtolower($name));
        return $slug !== '' ? $slug : Str::random(12);
    }

    public function run(): void
    {
        foreach (self::PRESET_SKILLS as $category => $skills) {
            foreach ($skills as $name) {
                $normalized = $this->normaliseName($name);
                if ($normalized === '') {
                    continue;
                }

                $slug = $this->slugFor($normalized);

                $existing = Skill::where('slug', $slug)->first();
                if ($existing && mb_strtolower($existing->name) !== mb_strtolower($normalized)) {
                    $base = $slug;
                    $i = 2;
                    while (Skill::where('slug', $slug)->exists()) {
                        $slug = $base . '-' . $i;
                        $i++;
                    }
                }

                Skill::updateOrCreate(
                    ['name' => $normalized],
                    [
                        'slug' => $slug,
                        'category' => $category,
                        'is_active' => true,
                    ]
                );
            }
        }

        $rawSkills = collect();

        if (Schema::hasTable('job_skills')) {
            $rawSkills = $rawSkills->merge(
                DB::table('job_skills')->select('skill')->pluck('skill')
            );
        }

        if (Schema::hasTable('jobseeker_skills')) {
            $rawSkills = $rawSkills->merge(
                DB::table('jobseeker_skills')->select('skill')->pluck('skill')
            );
        }

        $uniqueNames = $rawSkills
            ->map(fn ($s) => is_string($s) ? $this->normaliseName($s) : '')
            ->filter(fn ($s) => $s !== '')
            ->unique(fn ($s) => mb_strtolower($s))
            ->values();

        $slugToId = [];
        foreach ($uniqueNames as $name) {
            $slug = $this->slugFor($name);

            // Guard against rare slug collisions (e.g. different unicode forms).
            $base = $slug;
            $i = 2;
            while (isset($slugToId[$slug]) || Skill::where('slug', $slug)->exists()) {
                $slug = $base . '-' . $i;
                $i++;
            }

            $skill = Skill::updateOrCreate(
                ['name' => $name],
                [
                    'slug' => $slug,
                    'category' => null,
                    'is_active' => true,
                ]
            );
            $slugToId[$slug] = $skill->id;
        }

        // Backfill new pivot tables from old string tables.
        // (We intentionally keep old tables for backward compatibility.)
        if (Schema::hasTable('job_listing_skill_items') && Schema::hasTable('job_skills')) {
            $jobSkills = DB::table('job_skills')->select('job_listing_id', 'skill')->get();
            foreach ($jobSkills as $row) {
                $name = $this->normaliseName((string) $row->skill);
                if ($name === '') continue;

                $skill = Skill::whereRaw('LOWER(name) = ?', [mb_strtolower($name)])->first();
                if (!$skill) continue;

                DB::table('job_listing_skill_items')->updateOrInsert(
                    ['job_listing_id' => $row->job_listing_id, 'skill_id' => $skill->id],
                    ['updated_at' => now(), 'created_at' => now()]
                );
            }
        }

        if (Schema::hasTable('jobseeker_skill_items') && Schema::hasTable('jobseeker_skills')) {
            $jsSkills = DB::table('jobseeker_skills')->select('jobseeker_id', 'skill')->get();
            foreach ($jsSkills as $row) {
                $name = $this->normaliseName((string) $row->skill);
                if ($name === '') continue;

                $skill = Skill::whereRaw('LOWER(name) = ?', [mb_strtolower($name)])->first();
                if (!$skill) continue;

                DB::table('jobseeker_skill_items')->updateOrInsert(
                    ['jobseeker_id' => $row->jobseeker_id, 'skill_id' => $skill->id],
                    ['updated_at' => now(), 'created_at' => now()]
                );
            }
        }
    }
}

