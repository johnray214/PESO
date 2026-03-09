<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\Employer;

class EmployerSeeder extends Seeder
{
    public function run(): void
    {
        $employers = [
            [
                'company_name' => 'Accenture Philippines',
                'email' => 'hr@accenture.ph',
                'password' => Hash::make('password123'),
                'industry' => 'Information Technology',
                'contact' => '+63 2 8888 8888',
                'contact_person' => 'Maria Santos',
                'email_verified_at' => now(),
                'status' => 'active',
                'total_hired' => 45,
            ],
            [
                'company_name' => 'Jollibee Foods Corporation',
                'email' => 'careers@jollibee.com.ph',
                'password' => Hash::make('password123'),
                'industry' => 'Food & Beverage',
                'contact' => '+63 2 8634 1111',
                'contact_person' => 'Juan Dela Cruz',
                'email_verified_at' => now(),
                'status' => 'active',
                'total_hired' => 120,
            ],
            [
                'company_name' => 'SM Supermalls',
                'email' => 'recruitment@smsupermalls.com',
                'password' => Hash::make('password123'),
                'industry' => 'Retail',
                'contact' => '+63 2 8857 8888',
                'contact_person' => 'Rosa Reyes',
                'email_verified_at' => now(),
                'status' => 'active',
                'total_hired' => 200,
            ],
            [
                'company_name' => 'Globe Telecom',
                'email' => 'jobs@globe.com.ph',
                'password' => Hash::make('password123'),
                'industry' => 'Telecommunications',
                'contact' => '+63 2 7730 1000',
                'contact_person' => 'Carlos Martinez',
                'email_verified_at' => now(),
                'status' => 'active',
                'total_hired' => 78,
            ],
            [
                'company_name' => 'BDO Unibank',
                'email' => 'hr@bdo.com.ph',
                'password' => Hash::make('password123'),
                'industry' => 'Banking & Finance',
                'contact' => '+63 2 8631 8000',
                'contact_person' => 'Ana Garcia',
                'email_verified_at' => now(),
                'status' => 'active',
                'total_hired' => 95,
            ],
            [
                'company_name' => 'Ayala Land',
                'email' => 'careers@ayalaland.com.ph',
                'password' => Hash::make('password123'),
                'industry' => 'Real Estate',
                'contact' => '+63 2 8908 8888',
                'contact_person' => 'Pedro Gomez',
                'email_verified_at' => now(),
                'status' => 'active',
                'total_hired' => 62,
            ],
            [
                'company_name' => 'Manila Electric Company',
                'email' => 'recruitment@meralco.com.ph',
                'password' => Hash::make('password123'),
                'industry' => 'Utilities',
                'contact' => '+63 2 16211',
                'contact_person' => 'Linda Torres',
                'email_verified_at' => null,
                'status' => 'pending',
                'total_hired' => 0,
            ],
            [
                'company_name' => 'Philippine Airlines',
                'email' => 'jobs@pal.com.ph',
                'password' => Hash::make('password123'),
                'industry' => 'Aviation',
                'contact' => '+63 2 8855 8888',
                'contact_person' => 'Roberto Cruz',
                'email_verified_at' => now(),
                'status' => 'inactive',
                'total_hired' => 34,
            ],
        ];

        foreach ($employers as $employer) {
            Employer::create($employer);
        }
    }
}
