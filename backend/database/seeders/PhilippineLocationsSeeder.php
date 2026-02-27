<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PhilippineLocationsSeeder extends Seeder
{
    public function run(): void
    {
        $locationsData = [
            [
                'province' => ['name' => 'Isabela', 'region' => 'Region II (Cagayan Valley)'],
                'cities' => [
                    [
                        'name' => 'Santiago City',
                        'barangays' => [
                            'Abra', 'Ambalatungan', 'Balintocatoc', 'Batal', 'Buenavista',
                            'Cabulay', 'Calao East', 'Calao West', 'Centro East', 'Centro West',
                            'Divisoria', 'Dubinan East', 'Dubinan West', 'Luna', 'Mabini',
                            'Malvar', 'Nabbuan', 'Naggasican', 'Patul', 'Plaridel',
                            'Rizal', 'Rosario', 'Sagana', 'Sinsayon', 'Villa Gonzaga',
                            'Villasis', 'Victory Norte', 'Victory Sur'
                        ]
                    ],
                    [
                        'name' => 'Cauayan City',
                        'barangays' => [
                            'Alicaocao', 'Amobocan', 'Baringin Norte', 'Baringin Sur', 'Buena Suerte',
                            'Cabaruan', 'Cabugao', 'Casalatan', 'Catalina', 'Dabburab',
                            'District I', 'District II', 'District III', 'Gagabutan', 'Guayabal',
                            'Labinab', 'Linglingay', 'Maligaya', 'Manaoag', 'Marabulig I',
                            'Marabulig II', 'Minante I', 'Minante II', 'Naganacan', 'Nagrumbuan',
                            'San Antonio', 'San Fermin', 'San Luis', 'San Pablo', 'Villa Concepcion',
                            'Villa Luna', 'Villa Pereda'
                        ]
                    ],
                    [
                        'name' => 'Ilagan City',
                        'barangays' => [
                            'Alibagu', 'Alinguigan', 'Arusip', 'Bagumbayan', 'Ballig',
                            'Batal', 'Bigao', 'Cadu', 'Cabeseria 23', 'Cabeseria 25',
                            'Centro Poblacion', 'Dalibubon', 'Fugu', 'Fuyo', 'Garita',
                            'Guinatan', 'Lullutan', 'Malalam', 'Manano', 'Marana',
                            'Minabang', 'Naguilian Norte', 'Naguilian Sur', 'Osmena',
                            'Palacian', 'Rugao', 'San Felipe', 'San Juan', 'San Vicente',
                            'Santa Barbara', 'Santa Isabel', 'Santa Victoria', 'Tangcul',
                            'Villa Imelda'
                        ]
                    ]
                ]
            ],
            [
                'province' => ['name' => 'Metro Manila', 'region' => 'National Capital Region (NCR)'],
                'cities' => [
                    [
                        'name' => 'Manila',
                        'barangays' => [
                            'Barangay 1', 'Barangay 2', 'Barangay 3', 'Barangay 4', 'Barangay 5',
                            'Ermita', 'Intramuros', 'Malate', 'Paco', 'Pandacan',
                            'Port Area', 'Quiapo', 'Sampaloc', 'San Miguel', 'San Nicolas',
                            'Santa Ana', 'Santa Cruz', 'Santa Mesa', 'Tondo'
                        ]
                    ],
                    [
                        'name' => 'Quezon City',
                        'barangays' => [
                            'Alicia', 'Amihan', 'Apolonio Samson', 'Aurora', 'Baesa',
                            'Bagbag', 'Bagong Lipunan ng Crame', 'Bagong Pag-asa', 'Bagumbayan',
                            'Bagumbuhay', 'Balingasa', 'Balintawak', 'Batasan Hills',
                            'Commonwealth', 'Culiat', 'Fairview', 'Kamuning', 'Katipunan',
                            'La Loma', 'Libis', 'Loyola Heights', 'Mapayapa', 'Matandang Balara',
                            'Milagrosa', 'Novaliches Proper', 'Old Capitol Site', 'Payatas',
                            'Project 4', 'Project 6', 'Quirino 2-A', 'San Bartolome',
                            'Santa Lucia', 'Sikatuna Village', 'Talipapa', 'Tandang Sora',
                            'U.P. Campus', 'U.P. Village', 'Veterans Village', 'West Triangle',
                            'White Plains'
                        ]
                    ],
                    [
                        'name' => 'Makati',
                        'barangays' => [
                            'Bangkal', 'Bel-Air', 'Carmona', 'Cembo', 'Comembo',
                            'Dasmariñas', 'East Rembo', 'Forbes Park', 'Guadalupe Nuevo',
                            'Guadalupe Viejo', 'Kasilawan', 'La Paz', 'Magallanes',
                            'Olympia', 'Palanan', 'Pembo', 'Pinagkaisahan', 'Pio del Pilar',
                            'Pitogo', 'Poblacion', 'Post Proper Northside', 'Post Proper Southside',
                            'Rizal', 'San Antonio', 'San Isidro', 'San Lorenzo',
                            'Santa Cruz', 'Singkamas', 'South Cembo', 'Tejeros',
                            'Urdaneta', 'Valenzuela', 'West Rembo'
                        ]
                    ]
                ]
            ],
            [
                'province' => ['name' => 'Cebu', 'region' => 'Region VII (Central Visayas)'],
                'cities' => [
                    [
                        'name' => 'Cebu City',
                        'barangays' => [
                            'Adlaon', 'Agsungot', 'Apas', 'Bacayan', 'Banilad',
                            'Basak Pardo', 'Basak San Nicolas', 'Binaliw', 'Budla-an',
                            'Buhisan', 'Busay', 'Calamba', 'Camputhaw', 'Capitol Site',
                            'Cogon Ramos', 'Day-as', 'Guadalupe', 'Guba', 'Hipodromo',
                            'Kalunasan', 'Kasambagan', 'Labangon', 'Lahug', 'Lorega',
                            'Luz', 'Mabini', 'Mabolo', 'Malubog', 'Mambaling',
                            'Pahina Central', 'Pahina San Nicolas', 'Pardo', 'Pari-an',
                            'Pit-os', 'Punta Princesa', 'Quiot', 'Sambag I', 'Sambag II',
                            'San Antonio', 'San Jose', 'San Nicolas Proper', 'San Roque',
                            'Santa Cruz', 'Santo Niño', 'Sapangdaku', 'Sawang Calero',
                            'Sinsin', 'Sirao', 'Suba', 'Sudlon I', 'Sudlon II',
                            'Tabunan', 'Tagba-o', 'Talamban', 'Taptap', 'Tejero',
                            'Tinago', 'Tisa', 'To-ong', 'Zapatera'
                        ]
                    ],
                    [
                        'name' => 'Mandaue City',
                        'barangays' => [
                            'Alang-alang', 'Bakilid', 'Banilad', 'Basak', 'Cabancalan',
                            'Cambaro', 'Canduman', 'Casili', 'Casuntingan', 'Centro',
                            'Cubacub', 'Guizo', 'Ibabao-Estancia', 'Jagobiao', 'Labogon',
                            'Looc', 'Maguikay', 'Mantuyong', 'Opao', 'Pagsabungan',
                            'Pakna-an', 'Subangdaku', 'Tabok', 'Tawason', 'Tingub',
                            'Tipolo', 'Umapad'
                        ]
                    ]
                ]
            ],
            [
                'province' => ['name' => 'Davao del Sur', 'region' => 'Region XI (Davao Region)'],
                'cities' => [
                    [
                        'name' => 'Davao City',
                        'barangays' => [
                            'Acacia', 'Agdao', 'Alambre', 'Angalan', 'Baganihan',
                            'Bago Aplaya', 'Bago Gallera', 'Bago Oshiro', 'Baguio',
                            'Balengaeng', 'Baliok', 'Bantol', 'Biao Escuela', 'Biao Guianga',
                            'Bunawan', 'Buhangin', 'Calinan', 'Catalunan Grande', 'Catalunan Pequeño',
                            'Communal', 'Daliao', 'Dumoy', 'Eden', 'Inayangan',
                            'Lacson', 'Langub', 'Leon Garcia', 'Magtuod', 'Mahayag',
                            'Malabog', 'Malagos', 'Matina Aplaya', 'Matina Crossing',
                            'Matina Pangi', 'Mintal', 'Panacan', 'Paquibato', 'Paradise Embac',
                            'Poblacion', 'San Antonio', 'Sasa', 'Talomo', 'Tamugan',
                            'Tigatto', 'Toril', 'Tugbok', 'Wangan', 'Wilfredo Aquino'
                        ]
                    ],
                    [
                        'name' => 'Digos City',
                        'barangays' => [
                            'Aplaya', 'Balabag', 'Cogon', 'Colorado', 'Dawis',
                            'Dulangan', 'Goma', 'Igpit', 'Kiagot', 'Lungag',
                            'Mahayahay', 'Matti', 'Ruparan', 'San Agustin', 'San Jose',
                            'San Miguel', 'Sinawilan', 'Soong', 'Tiguman', 'Tres de Mayo',
                            'Zone I', 'Zone II', 'Zone III'
                        ]
                    ]
                ]
            ]
        ];

        foreach ($locationsData as $provinceData) {
            $province = DB::table('provinces')->insertGetId([
                'name' => $provinceData['province']['name'],
                'region' => $provinceData['province']['region'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($provinceData['cities'] as $cityData) {
                $city = DB::table('cities')->insertGetId([
                    'province_id' => $province,
                    'name' => $cityData['name'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                foreach ($cityData['barangays'] as $barangayName) {
                    DB::table('barangays')->insert([
                        'city_id' => $city,
                        'name' => $barangayName,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }
        }
    }
}
