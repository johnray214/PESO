<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $this->call([
            PhilippineLocationsSeeder::class,
            PesoEmployeeSeeder::class,
            EmployerSeeder::class,
            JobListingSeeder::class,
            EventSeeder::class,
            UserSeeder::class,
            JobApplicationSeeder::class,
            AuditLogSeeder::class,
        ]);
    }
}
