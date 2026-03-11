<?php

namespace Database\Seeders;

use App\Models\PesoEmployee;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class PesoEmployeeSeeder extends Seeder
{
    public function run(): void
    {
        $employees = [
            [
                'first_name'  => 'Admin',
                'middle_name' => null,
                'last_name'   => 'PESO',
                'role'        => 'admin',
                'email'       => 'admin@peso.gov.ph',
                'password'    => Hash::make('admin'),
                'sex'         => 'Male',
                'contact'     => '09171000001',
                'address'     => 'PESO Santiago City Office, City Hall Compound, Santiago City, Isabela',
                'status'      => 'active',
            ],
            [
                'first_name'  => 'Carlo',
                'middle_name' => 'B.',
                'last_name'   => 'Reyes',
                'role'        => 'staff',
                'email'       => 'carlo.reyes@peso.gov.ph',
                'password'    => Hash::make('staff123'),
                'sex'         => 'Male',
                'contact'     => '09189000002',
                'address'     => 'Brgy. Centro West, Santiago City, Isabela',
                'status'      => 'active',
            ],
            [
                'first_name'  => 'Maria',
                'middle_name' => 'L.',
                'last_name'   => 'Bautista',
                'role'        => 'staff',
                'email'       => 'maria.bautista@peso.gov.ph',
                'password'    => Hash::make('staff123'),
                'sex'         => 'Female',
                'contact'     => '09201000003',
                'address'     => 'Brgy. Rosario, Santiago City, Isabela',
                'status'      => 'active',
            ],
            [
                'first_name'  => 'Jose',
                'middle_name' => 'R.',
                'last_name'   => 'Dela Cruz',
                'role'        => 'staff',
                'email'       => 'jose.delacruz@peso.gov.ph',
                'password'    => Hash::make('staff123'),
                'sex'         => 'Male',
                'contact'     => '09155000004',
                'address'     => 'Brgy. Malvar, Santiago City, Isabela',
                'status'      => 'inactive',
            ],
        ];

        foreach ($employees as $employee) {
            PesoEmployee::firstOrCreate(
                ['email' => $employee['email']],
                $employee
            );
        }
    }
}
