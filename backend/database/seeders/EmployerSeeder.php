<?php

namespace Database\Seeders;

use App\Models\Employer;
use App\Models\JobListing;
use App\Models\JobSkill;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class EmployerSeeder extends Seeder
{
    private const LEGACY_EMPLOYER_DATA = [
        ['company_name' => 'TechCorp Solutions', 'contact_person' => 'Juan Dela Cruz', 'email' => 'employer1@techcorp.com', 'industry' => 'Other Community, Social and Personal Service Activities', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2015, 'city' => 'Santiago City', 'province' => 'Isabela', 'barangay' => 'Villasis', 'address_full' => 'Villasis, Santiago City, Isabela', 'phone' => '09171234567', 'website' => 'https://techcorp.com', 'latitude' => 16.6916, 'longitude' => 121.5551, 'status' => 'verified', 'verified_days_ago' => 30, 'total_hired' => 4],
        ['company_name' => 'Harvest Foods Inc.', 'contact_person' => 'Ana Reyes', 'email' => 'employer2@harvestfoods.com', 'industry' => 'Hotels and Restaurants', 'company_size' => '11-50', 'business_type' => 'Partnership', 'founded' => 2010, 'city' => 'Cauayan City', 'province' => 'Isabela', 'barangay' => 'Minante', 'address_full' => 'Minante, Cauayan City, Isabela', 'phone' => '09209876543', 'website' => null, 'latitude' => 16.9330, 'longitude' => 121.7728, 'status' => 'verified', 'verified_days_ago' => 60, 'total_hired' => 8],
        ['company_name' => 'BuildRight Construction', 'contact_person' => 'Pedro Santos', 'email' => 'employer3@buildright.com', 'industry' => 'Construction', 'company_size' => '201-500', 'business_type' => 'Corporation', 'founded' => 2008, 'city' => 'Ilagan City', 'province' => 'Isabela', 'barangay' => null, 'address_full' => 'Ilagan City, Isabela', 'phone' => '09351112233', 'website' => null, 'latitude' => 17.1489, 'longitude' => 121.8904, 'status' => 'pending', 'verified_days_ago' => 0, 'total_hired' => 0],
        ['company_name' => 'GlobalTech Marketing', 'contact_person' => 'Sara Lim', 'email' => 'employer4@globaltech.com', 'industry' => 'Wholesale and Retail Trade', 'company_size' => '11-50', 'business_type' => 'Corporation', 'founded' => 2018, 'city' => 'Echague', 'province' => 'Isabela', 'barangay' => null, 'address_full' => 'Echague, Isabela', 'phone' => '09191234567', 'website' => null, 'latitude' => 16.7118, 'longitude' => 121.6167, 'status' => 'verified', 'verified_days_ago' => 15, 'total_hired' => 2],
        ['company_name' => 'GreenValley Orchards', 'contact_person' => 'David Bautista', 'email' => 'employer5@greenvalley.com', 'industry' => 'Agriculture', 'company_size' => '1-10', 'business_type' => 'Sole Proprietorship', 'founded' => 2012, 'city' => 'Cordon', 'province' => 'Isabela', 'barangay' => null, 'address_full' => 'Cordon, Isabela', 'phone' => '09455556666', 'website' => null, 'latitude' => 16.6667, 'longitude' => 121.4500, 'status' => 'verified', 'verified_days_ago' => 45, 'total_hired' => 6],
    ];

    private const LEGACY_JOBS_BY_EMAIL = [
        'employer1@techcorp.com' => [
            ['title' => 'Web Developer', 'type' => 'full-time', 'salary_range' => 'Above Minimum Wage', 'education_level' => 'college_graduate', 'experience_required' => '2_years', 'slots' => 3, 'days_back' => 10, 'days_ahead' => 20, 'description' => 'We are looking for a skilled Web Developer to build and maintain modern web applications using PHP, Laravel, and Vue.js.', 'skills' => ['PHP', 'Laravel', 'JavaScript', 'Vue.js', 'MySQL']],
            ['title' => 'UI/UX Designer', 'type' => 'full-time', 'salary_range' => 'Minimum Wage', 'education_level' => 'college_graduate', 'experience_required' => '1_year', 'slots' => 2, 'days_back' => 5, 'days_ahead' => 25, 'description' => 'Join our creative team as a UI/UX Designer. You will create beautiful and intuitive interfaces for our products.', 'skills' => ['Figma', 'Adobe XD', 'CSS', 'Prototyping', 'User Research']],
        ],
        'employer2@harvestfoods.com' => [
            ['title' => 'Food Processing Worker', 'type' => 'full-time', 'salary_range' => 'Minimum Wage', 'education_level' => 'highschool', 'experience_required' => 'fresh_grad', 'slots' => 10, 'days_back' => 3, 'days_ahead' => 27, 'description' => 'Work in our food processing facility. No experience required, training is provided on-site.', 'skills' => ['Food Safety', 'Quality Control', 'Packaging', 'Sanitation']],
            ['title' => 'Delivery Driver', 'type' => 'full-time', 'salary_range' => 'Minimum Wage', 'education_level' => 'highschool', 'experience_required' => '1_year', 'slots' => 3, 'days_back' => 7, 'days_ahead' => 23, 'description' => 'Deliver fresh goods to partner stores and markets across Isabela. Must have a valid driver\'s license.', 'skills' => ['Driving', 'Route Planning', 'Customer Service', 'Time Management']],
        ],
        'employer3@buildright.com' => [
            ['title' => 'Civil Engineer', 'type' => 'full-time', 'salary_range' => 'Above Minimum Wage', 'education_level' => 'college_graduate', 'experience_required' => '3_years', 'slots' => 2, 'days_back' => 8, 'days_ahead' => 22, 'description' => 'Oversee and manage construction projects in Isabela. Must be a licensed civil engineer with strong project management skills.', 'skills' => ['AutoCAD', 'Project Management', 'Structural Analysis', 'Cost Estimation']],
            ['title' => 'Construction Worker', 'type' => 'full-time', 'salary_range' => 'Minimum Wage', 'education_level' => 'elementary', 'experience_required' => 'fresh_grad', 'slots' => 20, 'days_back' => 2, 'days_ahead' => 28, 'description' => 'Join our construction crew for residential and commercial building projects. Tools and protective equipment provided.', 'skills' => ['Concrete Work', 'Masonry', 'Carpentry', 'Welding']],
        ],
        'employer4@globaltech.com' => [
            ['title' => 'Social Media Manager', 'type' => 'full-time', 'salary_range' => 'Above Minimum Wage', 'education_level' => 'college_graduate', 'experience_required' => '1_year', 'slots' => 2, 'days_back' => 4, 'days_ahead' => 26, 'description' => 'Manage and grow our clients\' brand presence across all social media platforms. Create engaging content and analyze performance.', 'skills' => ['Facebook Ads', 'Copywriting', 'Canva', 'Content Creation', 'SEO']],
            ['title' => 'Graphic Designer', 'type' => 'contract', 'salary_range' => 'Minimum Wage', 'education_level' => 'college_level', 'experience_required' => 'less_than_1', 'slots' => 1, 'days_back' => 6, 'days_ahead' => 24, 'description' => 'Create compelling visual content for digital and print media. Proficient in Adobe products required.', 'skills' => ['Adobe Photoshop', 'Adobe Illustrator', 'Canva', 'Branding']],
        ],
        'employer5@greenvalley.com' => [
            ['title' => 'Farm Worker', 'type' => 'full-time', 'salary_range' => 'Minimum Wage', 'education_level' => 'elementary', 'experience_required' => 'fresh_grad', 'slots' => 15, 'days_back' => 1, 'days_ahead' => 29, 'description' => 'Assist with planting, harvesting, and irrigation of our fruit orchards. Training provided for new hires.', 'skills' => ['Farming', 'Irrigation', 'Pest Control', 'Harvesting']],
            ['title' => 'Agricultural Technician', 'type' => 'full-time', 'salary_range' => 'Above Minimum Wage', 'education_level' => 'college_graduate', 'experience_required' => '2_years', 'slots' => 1, 'days_back' => 12, 'days_ahead' => 18, 'description' => 'Oversee soil testing, crop health monitoring, and yield optimization. Background in agriculture or agronomy required.', 'skills' => ['Soil Science', 'Crop Management', 'Pest Control', 'Data Analysis', 'Farming']],
        ],
    ];

    private const JOB_TEMPLATES = [
        [
            'title' => 'Operations Assistant',
            'type' => 'full-time',
            'salary_range' => 'Minimum Wage',
            'education_level' => 'highschool',
            'experience_required' => 'less_than_1',
            'slots' => 3,
            'days_back' => 14,
            'days_ahead' => 20,
            'description' => 'Support daily business operations, coordinate documentation, and assist frontline teams.',
            'skills' => ['Administrative Support', 'MS Office', 'Data Entry', 'Customer Service'],
        ],
        [
            'title' => 'Sales and Marketing Associate',
            'type' => 'full-time',
            'salary_range' => 'Above Minimum Wage',
            'education_level' => 'college_level',
            'experience_required' => '1_year',
            'slots' => 2,
            'days_back' => 11,
            'days_ahead' => 22,
            'description' => 'Handle field sales, build client relationships, and execute local marketing campaigns.',
            'skills' => ['Sales', 'Negotiation', 'Presentation Skills', 'Social Media Management'],
        ],
        [
            'title' => 'HR and Recruitment Staff',
            'type' => 'full-time',
            'salary_range' => 'Above Minimum Wage',
            'education_level' => 'college_graduate',
            'experience_required' => '2_years',
            'slots' => 1,
            'days_back' => 9,
            'days_ahead' => 25,
            'description' => 'Manage hiring pipelines, employee records, and onboarding processes.',
            'skills' => ['Recruitment', 'Administrative Support', 'Business Writing', 'Documentation'],
        ],
        [
            'title' => 'Warehouse and Logistics Coordinator',
            'type' => 'full-time',
            'salary_range' => 'Minimum Wage',
            'education_level' => 'highschool',
            'experience_required' => '1_year',
            'slots' => 3,
            'days_back' => 8,
            'days_ahead' => 18,
            'description' => 'Oversee inventory movement, dispatch schedules, and delivery coordination.',
            'skills' => ['Warehouse Operations', 'Inventory Management', 'Route Planning', 'Dispatching'],
        ],
        [
            'title' => 'Finance and Bookkeeping Assistant',
            'type' => 'full-time',
            'salary_range' => 'Above Minimum Wage',
            'education_level' => 'college_graduate',
            'experience_required' => '2_years',
            'slots' => 1,
            'days_back' => 12,
            'days_ahead' => 23,
            'description' => 'Prepare financial records, maintain ledgers, and assist in payroll processing.',
            'skills' => ['Bookkeeping', 'Accounting', 'Payroll Processing', 'Report Preparation'],
        ],
        [
            'title' => 'Customer Care Representative',
            'type' => 'full-time',
            'salary_range' => 'Minimum Wage',
            'education_level' => 'highschool',
            'experience_required' => 'fresh_grad',
            'slots' => 4,
            'days_back' => 7,
            'days_ahead' => 19,
            'description' => 'Provide customer support via phone, chat, and email while maintaining service quality.',
            'skills' => ['Customer Service', 'Data Entry', 'Business Writing', 'Problem Solving'],
        ],
        [
            'title' => 'Field Technician',
            'type' => 'full-time',
            'salary_range' => 'Above Minimum Wage',
            'education_level' => 'vocational',
            'experience_required' => '1_year',
            'slots' => 2,
            'days_back' => 6,
            'days_ahead' => 21,
            'description' => 'Perform on-site installation, preventive maintenance, and issue troubleshooting.',
            'skills' => ['Troubleshooting', 'Electrical Installation', 'Safety Compliance', 'Documentation'],
        ],
    ];

    private const EMPLOYER_DATA = [
        // Luzon
        ['company_name' => 'MetroLink Technologies', 'contact_person' => 'Carlos Reyes', 'email' => 'employer1@metrolinkph.com', 'industry' => 'Other Community, Social and Personal Service Activities', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2014, 'city' => 'Quezon City', 'province' => 'Metro Manila', 'barangay' => 'Bagumbayan', 'address_full' => 'Bagumbayan, Quezon City, Metro Manila', 'phone' => '09170010001', 'website' => 'https://metrolinkph.com', 'latitude' => 14.6091, 'longitude' => 121.0223, 'status' => 'verified', 'verified_days_ago' => 45, 'total_hired' => 12],
        ['company_name' => 'Harborline Logistics', 'contact_person' => 'Mica Dizon', 'email' => 'employer2@harborlineph.com', 'industry' => 'Transport, Storage and Communication', 'company_size' => '201-500', 'business_type' => 'Corporation', 'founded' => 2011, 'city' => 'Subic', 'province' => 'Zambales', 'barangay' => 'Asinan Proper', 'address_full' => 'Asinan Proper, Subic, Zambales', 'phone' => '09170010002', 'website' => 'https://harborlineph.com', 'latitude' => 14.8799, 'longitude' => 120.2690, 'status' => 'verified', 'verified_days_ago' => 32, 'total_hired' => 20],
        ['company_name' => 'North Harvest Agri Corp', 'contact_person' => 'Daryl Pascua', 'email' => 'employer3@northharvestph.com', 'industry' => 'Agriculture', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2009, 'city' => 'Tuguegarao City', 'province' => 'Cagayan', 'barangay' => 'Carig Sur', 'address_full' => 'Carig Sur, Tuguegarao City, Cagayan', 'phone' => '09170010003', 'website' => 'https://northharvestph.com', 'latitude' => 17.6132, 'longitude' => 121.7270, 'status' => 'verified', 'verified_days_ago' => 21, 'total_hired' => 15],
        ['company_name' => 'Baguio Peak Hospitality', 'contact_person' => 'Irene Dayag', 'email' => 'employer4@peakhospitalityph.com', 'industry' => 'Hotels and Restaurants', 'company_size' => '11-50', 'business_type' => 'Partnership', 'founded' => 2017, 'city' => 'Baguio City', 'province' => 'Benguet', 'barangay' => 'Engineer\'s Hill', 'address_full' => 'Engineer\'s Hill, Baguio City, Benguet', 'phone' => '09170010004', 'website' => 'https://peakhospitalityph.com', 'latitude' => 16.4023, 'longitude' => 120.5960, 'status' => 'verified', 'verified_days_ago' => 27, 'total_hired' => 9],
        ['company_name' => 'Central Buildworks', 'contact_person' => 'Renato Aquino', 'email' => 'employer5@centralbuildworksph.com', 'industry' => 'Construction', 'company_size' => '201-500', 'business_type' => 'Corporation', 'founded' => 2006, 'city' => 'San Fernando', 'province' => 'Pampanga', 'barangay' => 'Del Pilar', 'address_full' => 'Del Pilar, San Fernando, Pampanga', 'phone' => '09170010005', 'website' => 'https://centralbuildworksph.com', 'latitude' => 15.0343, 'longitude' => 120.6849, 'status' => 'verified', 'verified_days_ago' => 60, 'total_hired' => 30],
        ['company_name' => 'Calabarzon MedAssist', 'contact_person' => 'Jean Ramos', 'email' => 'employer6@medassistph.com', 'industry' => 'Health and Social Work', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2015, 'city' => 'Lipa City', 'province' => 'Batangas', 'barangay' => 'Marawoy', 'address_full' => 'Marawoy, Lipa City, Batangas', 'phone' => '09170010006', 'website' => 'https://medassistph.com', 'latitude' => 13.9411, 'longitude' => 121.1631, 'status' => 'verified', 'verified_days_ago' => 18, 'total_hired' => 11],
        ['company_name' => 'Bicol Prime Foods', 'contact_person' => 'Lea Villanueva', 'email' => 'employer7@bicolprimefoods.com', 'industry' => 'Manufacturing', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2013, 'city' => 'Naga City', 'province' => 'Camarines Sur', 'barangay' => 'Concepcion Pequena', 'address_full' => 'Concepcion Pequena, Naga City, Camarines Sur', 'phone' => '09170010007', 'website' => 'https://bicolprimefoods.com', 'latitude' => 13.6218, 'longitude' => 123.1948, 'status' => 'verified', 'verified_days_ago' => 25, 'total_hired' => 14],
        ['company_name' => 'Palawan Eco Tourism Group', 'contact_person' => 'Mark Sarmiento', 'email' => 'employer8@palawanecotourph.com', 'industry' => 'Hotels and Restaurants', 'company_size' => '11-50', 'business_type' => 'Partnership', 'founded' => 2019, 'city' => 'Puerto Princesa', 'province' => 'Palawan', 'barangay' => 'San Miguel', 'address_full' => 'San Miguel, Puerto Princesa, Palawan', 'phone' => '09170010008', 'website' => 'https://palawanecotourph.com', 'latitude' => 9.7392, 'longitude' => 118.7353, 'status' => 'verified', 'verified_days_ago' => 13, 'total_hired' => 7],
        // Visayas
        ['company_name' => 'Cebu Digital Works', 'contact_person' => 'Paolo Uy', 'email' => 'employer9@cebudigitalworks.com', 'industry' => 'Other Community, Social and Personal Service Activities', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2016, 'city' => 'Cebu City', 'province' => 'Cebu', 'barangay' => 'Lahug', 'address_full' => 'Lahug, Cebu City, Cebu', 'phone' => '09170010009', 'website' => 'https://cebudigitalworks.com', 'latitude' => 10.3157, 'longitude' => 123.8854, 'status' => 'verified', 'verified_days_ago' => 40, 'total_hired' => 18],
        ['company_name' => 'Iloilo Food Manufacturing', 'contact_person' => 'Katrina Mendoza', 'email' => 'employer10@iloilofoodmfg.com', 'industry' => 'Manufacturing', 'company_size' => '201-500', 'business_type' => 'Corporation', 'founded' => 2007, 'city' => 'Iloilo City', 'province' => 'Iloilo', 'barangay' => 'Jaro', 'address_full' => 'Jaro, Iloilo City, Iloilo', 'phone' => '09170010010', 'website' => 'https://iloilofoodmfg.com', 'latitude' => 10.7202, 'longitude' => 122.5621, 'status' => 'verified', 'verified_days_ago' => 48, 'total_hired' => 28],
        ['company_name' => 'Bacolod Sugarfields', 'contact_person' => 'Rico Golez', 'email' => 'employer11@bacolodsugarfields.com', 'industry' => 'Agriculture', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2010, 'city' => 'Bacolod', 'province' => 'Negros Occidental', 'barangay' => 'Mansilingan', 'address_full' => 'Mansilingan, Bacolod, Negros Occidental', 'phone' => '09170010011', 'website' => 'https://bacolodsugarfields.com', 'latitude' => 10.6765, 'longitude' => 122.9509, 'status' => 'verified', 'verified_days_ago' => 34, 'total_hired' => 16],
        ['company_name' => 'Eastern Samar Builders', 'contact_person' => 'Cynthia Loreto', 'email' => 'employer12@esamarbuilders.com', 'industry' => 'Construction', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2012, 'city' => 'Borongan', 'province' => 'Eastern Samar', 'barangay' => 'Songco', 'address_full' => 'Songco, Borongan, Eastern Samar', 'phone' => '09170010012', 'website' => 'https://esamarbuilders.com', 'latitude' => 11.6081, 'longitude' => 125.4319, 'status' => 'verified', 'verified_days_ago' => 29, 'total_hired' => 13],
        ['company_name' => 'Leyte Care Health Services', 'contact_person' => 'Grace Alonzo', 'email' => 'employer13@leytecareph.com', 'industry' => 'Health and Social Work', 'company_size' => '11-50', 'business_type' => 'Partnership', 'founded' => 2018, 'city' => 'Tacloban City', 'province' => 'Leyte', 'barangay' => 'Sagkahan', 'address_full' => 'Sagkahan, Tacloban City, Leyte', 'phone' => '09170010013', 'website' => 'https://leytecareph.com', 'latitude' => 11.2440, 'longitude' => 125.0048, 'status' => 'verified', 'verified_days_ago' => 16, 'total_hired' => 8],
        ['company_name' => 'Bohol Island Resorts', 'contact_person' => 'Nathan Sevilla', 'email' => 'employer14@boholislandresorts.com', 'industry' => 'Hotels and Restaurants', 'company_size' => '11-50', 'business_type' => 'Corporation', 'founded' => 2020, 'city' => 'Tagbilaran City', 'province' => 'Bohol', 'barangay' => 'Cogon', 'address_full' => 'Cogon, Tagbilaran City, Bohol', 'phone' => '09170010014', 'website' => 'https://boholislandresorts.com', 'latitude' => 9.6496, 'longitude' => 123.8530, 'status' => 'verified', 'verified_days_ago' => 10, 'total_hired' => 5],
        // Mindanao
        ['company_name' => 'Davao Agriventures', 'contact_person' => 'Aubrey Tan', 'email' => 'employer15@davaoagriventures.com', 'industry' => 'Agriculture', 'company_size' => '201-500', 'business_type' => 'Corporation', 'founded' => 2008, 'city' => 'Davao City', 'province' => 'Davao del Sur', 'barangay' => 'Buhangin', 'address_full' => 'Buhangin, Davao City, Davao del Sur', 'phone' => '09170010015', 'website' => 'https://davaoagriventures.com', 'latitude' => 7.0731, 'longitude' => 125.6128, 'status' => 'verified', 'verified_days_ago' => 39, 'total_hired' => 24],
        ['company_name' => 'Northern Mindanao Logistics', 'contact_person' => 'Francis Tiu', 'email' => 'employer16@nminlogistics.com', 'industry' => 'Transport, Storage and Communication', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2014, 'city' => 'Cagayan de Oro', 'province' => 'Misamis Oriental', 'barangay' => 'Lapasan', 'address_full' => 'Lapasan, Cagayan de Oro, Misamis Oriental', 'phone' => '09170010016', 'website' => 'https://nminlogistics.com', 'latitude' => 8.4542, 'longitude' => 124.6319, 'status' => 'verified', 'verified_days_ago' => 31, 'total_hired' => 17],
        ['company_name' => 'Zamboanga Marine Foods', 'contact_person' => 'Jasmine Khu', 'email' => 'employer17@zambomarinefoods.com', 'industry' => 'Manufacturing', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2011, 'city' => 'Zamboanga City', 'province' => 'Zamboanga del Sur', 'barangay' => 'Canelar', 'address_full' => 'Canelar, Zamboanga City, Zamboanga del Sur', 'phone' => '09170010017', 'website' => 'https://zambomarinefoods.com', 'latitude' => 6.9214, 'longitude' => 122.0790, 'status' => 'verified', 'verified_days_ago' => 26, 'total_hired' => 14],
        ['company_name' => 'General Santos Cold Chain', 'contact_person' => 'Melvin Gadia', 'email' => 'employer18@gscoldchain.com', 'industry' => 'Transport, Storage and Communication', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2013, 'city' => 'General Santos City', 'province' => 'South Cotabato', 'barangay' => 'Labangal', 'address_full' => 'Labangal, General Santos City, South Cotabato', 'phone' => '09170010018', 'website' => 'https://gscoldchain.com', 'latitude' => 6.1164, 'longitude' => 125.1716, 'status' => 'verified', 'verified_days_ago' => 24, 'total_hired' => 19],
        ['company_name' => 'Butuan Build and Energy', 'contact_person' => 'Louise Manatad', 'email' => 'employer19@butuanbuildenergy.com', 'industry' => 'Construction', 'company_size' => '51-200', 'business_type' => 'Corporation', 'founded' => 2010, 'city' => 'Butuan City', 'province' => 'Agusan del Norte', 'barangay' => 'Bancasi', 'address_full' => 'Bancasi, Butuan City, Agusan del Norte', 'phone' => '09170010019', 'website' => 'https://butuanbuildenergy.com', 'latitude' => 8.9495, 'longitude' => 125.5438, 'status' => 'verified', 'verified_days_ago' => 22, 'total_hired' => 13],
        ['company_name' => 'Cotabato Community Services', 'contact_person' => 'Hannah Samama', 'email' => 'employer20@cotabatocomserve.com', 'industry' => 'Other Community, Social and Personal Service Activities', 'company_size' => '11-50', 'business_type' => 'Non-Profit', 'founded' => 2019, 'city' => 'Cotabato City', 'province' => 'Maguindanao del Norte', 'barangay' => 'Rosary Heights', 'address_full' => 'Rosary Heights, Cotabato City, Maguindanao del Norte', 'phone' => '09170010020', 'website' => 'https://cotabatocomserve.com', 'latitude' => 7.2236, 'longitude' => 124.2464, 'status' => 'verified', 'verified_days_ago' => 15, 'total_hired' => 6],
    ];

    public static array $jobsByEmployer = [];

    public function run(): void
    {
        $baseEmployers = array_merge(self::LEGACY_EMPLOYER_DATA, self::EMPLOYER_DATA);
        $allEmployers = array_merge($baseEmployers, $this->buildNearbyEmployers($baseEmployers));

        foreach ($allEmployers as $index => $seed) {
            $data = [
                'company_name' => $seed['company_name'],
                'contact_person' => $seed['contact_person'],
                'email' => $seed['email'],
                'password' => Hash::make('password123'),
                'industry' => $seed['industry'],
                'company_size' => $seed['company_size'],
                'tagline' => 'Hiring across Luzon, Visayas, and Mindanao.',
                'about' => $seed['company_name'] . ' partners with PESO offices and local communities to provide stable jobs and career growth opportunities.',
                'business_type' => $seed['business_type'],
                'founded' => $seed['founded'],
                'tin' => sprintf('%03d-%03d-%03d-000', $index + 100, $index + 200, $index + 300),
                'city' => $seed['city'],
                'province' => $seed['province'],
                'barangay' => $seed['barangay'],
                'address_full' => $seed['address_full'],
                'phone' => $seed['phone'],
                'website' => $seed['website'],
                'latitude' => $seed['latitude'],
                'longitude' => $seed['longitude'],
                'status' => $seed['status'],
                'verified_at' => ($seed['status'] ?? 'pending') === 'verified'
                    ? now()->subDays($seed['verified_days_ago'])
                    : null,
                'total_hired' => $seed['total_hired'],
            ];

            $employer = Employer::updateOrCreate(['email' => $data['email']], $data);

            if ($employer->status !== 'verified') {
                continue;
            }

            $jobDefs = self::LEGACY_JOBS_BY_EMAIL[$data['email']] ?? $this->jobsForEmployer($index, $data['email']);
            self::$jobsByEmployer[$data['email']] = $jobDefs;

            foreach ($jobDefs as $def) {
                $skills    = $def['skills'];
                $daysBack  = $def['days_back'];
                $daysAhead = $def['days_ahead'];
                unset($def['skills'], $def['days_back'], $def['days_ahead']);

                $barangay = $data['barangay'] ?? '';
                $location = $barangay
                    ? $barangay . ', ' . ucwords(strtolower($data['city'])) . ', ' . ucwords(strtolower($data['province']))
                    : ucwords(strtolower($data['city'])) . ', ' . ucwords(strtolower($data['province']));

                $job = JobListing::updateOrCreate(
                    [
                        'employer_id' => $employer->id,
                        'title' => $def['title'],
                        'location' => $location,
                    ],
                    array_merge($def, [
                        'employer_id' => $employer->id,
                        'location' => $location,
                        'posted_date' => now()->subDays($daysBack),
                        'deadline' => now()->addDays($daysAhead),
                        'status' => (rand(1, 100) > 30) ? 'open' : 'closed', // 70% open, 30% closed
                    ])
                );

                JobSkill::where('job_listing_id', $job->id)->delete();
                foreach ($skills as $skill) {
                    JobSkill::create(['job_listing_id' => $job->id, 'skill' => $skill]);
                }
            }
        }
    }

    private function jobsForEmployer(int $index, string $email): array
    {
        $start = ($index * 2) % count(self::JOB_TEMPLATES);
        $jobs = [
            self::JOB_TEMPLATES[$start],
        ];

        // Keep a few tech-heavy employers with a third role to diversify demand.
        if (in_array($email, ['employer1@metrolinkph.com', 'employer9@cebudigitalworks.com'], true)) {
            $jobs[] = [
                'title' => 'Junior Web Developer',
                'type' => 'full-time',
                'salary_range' => 'Above Minimum Wage',
                'education_level' => 'college_level',
                'experience_required' => 'less_than_1',
                'slots' => 2,
                'days_back' => 5,
                'days_ahead' => 26,
                'description' => 'Build and maintain internal web tools used by operations teams.',
                'skills' => ['PHP', 'Laravel', 'JavaScript', 'MySQL', 'Git'],
            ];
        }

        return $jobs;
    }

    private function buildNearbyEmployers(array $baseEmployers): array
    {
        $nearby = [];
        $sizes = ['1-10', '11-50', '51-200'];
        $types = ['Corporation', 'Partnership', 'Sole Proprietorship'];
        $industries = [
            'Information Technology',
            'Logistics',
            'Retail',
            'Food & Beverage',
            'Construction',
            'Healthcare',
            'Hospitality',
            'Agriculture',
            'Manufacturing',
            'Business Services',
        ];
        $suffixes = ['Hub', 'Works', 'Ventures', 'Solutions'];

        foreach ($baseEmployers as $i => $base) {
            // Reduced: Only 1 nearby company per base company (was 2-4)
            $nearbyCount = 1;
            $baseLat = (float) ($base['latitude'] ?? 0.0);
            $baseLng = (float) ($base['longitude'] ?? 0.0);
            $baseIndustry = (string) ($base['industry'] ?? 'Business Services');
            $baseCitySlug = strtolower(preg_replace('/[^a-z0-9]+/i', '', (string) ($base['city'] ?? 'city')) ?? 'city');

            for ($n = 1; $n <= $nearbyCount; $n++) {
                $idx = $i + $n;
                $latOffset = 0.006 * $n;
                $lngOffset = 0.007 * $n;

                $industry = $industries[$idx % count($industries)];
                if ($n % 2 === 0) {
                    $industry = $baseIndustry;
                }

                $companyName = sprintf(
                    '%s %s %s',
                    preg_replace('/\s+/', ' ', trim((string) $base['company_name'])) ?: 'Regional',
                    $suffixes[$idx % count($suffixes)],
                    chr(64 + $n)
                );
                $email = sprintf(
                    'nearby.%s.%02d.%d@employerseed.ph',
                    $baseCitySlug,
                    $i + 1,
                    $n
                );

                $nearby[] = [
                    'company_name' => $companyName,
                    'contact_person' => 'Local Hiring Manager ' . chr(64 + $n),
                    'email' => $email,
                    'industry' => $industry,
                    'company_size' => $sizes[$idx % count($sizes)],
                    'business_type' => $types[$idx % count($types)],
                    'founded' => 2012 + ($idx % 12),
                    'city' => $base['city'],
                    'province' => $base['province'],
                    'barangay' => $base['barangay'] ?? null,
                    'address_full' => $base['address_full'],
                    'phone' => sprintf('09%09d', 100000000 + (($i + 1) * 1000) + $n),
                    'website' => null,
                    'latitude' => $baseLat + ($n % 2 === 0 ? -$latOffset : $latOffset),
                    'longitude' => $baseLng + ($n % 2 === 0 ? -$lngOffset : $lngOffset),
                    'status' => 'verified',
                    'verified_days_ago' => 7 + (($idx * 3) % 44),
                    'total_hired' => 2 + (($idx + $n) % 15),
                ];
            }
        }

        return $nearby;
    }
}
