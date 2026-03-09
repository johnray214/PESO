<?php

namespace Database\Seeders;

use App\Models\PesoEmployee;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class PesoEmployeeSeeder extends Seeder
{
    /**
     * Seed one PESO admin for testing login.
     */
    public function run(): void
    {
        PesoEmployee::firstOrCreate(
            ['email' => 'admin@peso.gov.ph'],
            [
                'first_name' => 'Admin',
                'middle_name' => null,
                'last_name' => 'PESO',
                'role' => 'admin',
                'email' => 'admin@peso.gov.ph',
                'password' => Hash::make('admin'),
                'sex' => null,
            ]
        );
    }
}
