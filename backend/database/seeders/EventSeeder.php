<?php

namespace Database\Seeders;

use App\Models\Event;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class EventSeeder extends Seeder
{
    public function run(): void
    {
        Event::truncate();

        $events = [
            [
                'title'       => 'Santiago City Job Fair 2026',
                'description' => 'Connect with top employers from Isabela and nearby provinces. Over 50 companies will be hiring for various positions including retail, hospitality, manufacturing, and office jobs. Bring your resume and dress professionally.',
                'location'    => 'Santiago City Convention Center',
                'event_date'  => Carbon::now()->addDays(14)->toDateString(),
                'event_time'  => '9:00 AM - 4:00 PM',
                'event_type'  => 'Job Fair',
                'organizer'   => 'PESO Santiago City',
                'slots'       => 500,
                'registered'  => 213,
                'status'      => 'upcoming',
                'is_active'   => true,
            ],
            [
                'title'       => 'Career Development Seminar: Resume Writing',
                'description' => 'Learn how to create a standout resume that gets you noticed by recruiters. Professional trainers will share tips on formatting, keywords, and tailoring your resume for different industries.',
                'location'    => 'SM City Santiago, Function Room 2',
                'event_date'  => Carbon::now()->addDays(7)->toDateString(),
                'event_time'  => '2:00 PM - 5:00 PM',
                'event_type'  => 'Seminar',
                'organizer'   => 'PESO Isabela',
                'slots'       => 80,
                'registered'  => 67,
                'status'      => 'upcoming',
                'is_active'   => true,
            ],
            [
                'title'       => 'Tech Industry Career Fair',
                'description' => 'IT and software companies from Cagayan Valley will be onsite. Opportunities for developers, designers, IT support, and digital marketing. Some companies offer on-the-spot interviews.',
                'location'    => 'Robinsons Place Santiago, Activity Center',
                'event_date'  => Carbon::now()->addDays(21)->toDateString(),
                'event_time'  => '10:00 AM - 6:00 PM',
                'event_type'  => 'Job Fair',
                'organizer'   => 'Department of Labor and Employment',
                'slots'       => 300,
                'registered'  => 88,
                'status'      => 'upcoming',
                'is_active'   => true,
            ],
            [
                'title'       => 'Interview Skills Workshop',
                'description' => 'Boost your confidence for job interviews. Topics include common questions, body language, salary negotiation, and following up. Includes mock interview practice sessions.',
                'location'    => 'PESO Santiago Office, Training Room',
                'event_date'  => Carbon::now()->addDays(10)->toDateString(),
                'event_time'  => '9:00 AM - 12:00 PM',
                'event_type'  => 'Workshop',
                'organizer'   => 'PESO Santiago City',
                'slots'       => 50,
                'registered'  => 50,
                'status'      => 'upcoming',
                'is_active'   => true,
            ],
            [
                'title'       => 'Summer Employment Expo',
                'description' => 'Perfect for students and graduates seeking summer jobs or entry-level positions. Retail, food service, and tourism employers will have booths. Free admission.',
                'location'    => 'Santiago City Public Market, Multi-Purpose Hall',
                'event_date'  => Carbon::now()->addDays(28)->toDateString(),
                'event_time'  => '8:00 AM - 3:00 PM',
                'event_type'  => 'Job Fair',
                'organizer'   => 'Local Government Unit - Santiago City',
                'slots'       => 200,
                'registered'  => 45,
                'status'      => 'upcoming',
                'is_active'   => true,
            ],
            [
                'title'       => 'OFW Reintegration Forum',
                'description' => 'Returning OFWs: Learn about local job opportunities, livelihood programs, and skills training. Connect with government agencies offering support for reintegration.',
                'location'    => 'Isabela State University - Santiago Campus',
                'event_date'  => Carbon::now()->addDays(35)->toDateString(),
                'event_time'  => '1:00 PM - 5:00 PM',
                'event_type'  => 'Seminar',
                'organizer'   => 'Overseas Workers Welfare Administration (OWWA)',
                'slots'       => 150,
                'registered'  => 32,
                'status'      => 'upcoming',
                'is_active'   => true,
            ],
            [
                'title'       => 'Livelihood Skills Training – Basic Baking',
                'description' => 'Free baking skills training funded by DOLE. Participants will learn bread and pastry making, food packaging, and basic business concepts for a livelihood business. Materials provided.',
                'location'    => 'PESO Santiago City Training Center',
                'event_date'  => Carbon::now()->subDays(5)->toDateString(),
                'event_time'  => '8:00 AM - 5:00 PM',
                'event_type'  => 'Livelihood Program',
                'organizer'   => 'DOLE – Region 02',
                'slots'       => 40,
                'registered'  => 40,
                'status'      => 'completed',
                'is_active'   => true,
            ],
            [
                'title'       => 'Isabela Multi-Sector Job Fair',
                'description' => 'A mega job fair covering healthcare, education, construction, BPO, retail, and government sectors. On-site hiring, career counseling, and resume clinic available.',
                'location'    => 'Isabela Sports Complex, Ilagan City',
                'event_date'  => Carbon::now()->subDays(15)->toDateString(),
                'event_time'  => '9:00 AM - 5:00 PM',
                'event_type'  => 'Job Fair',
                'organizer'   => 'PESO Isabela Province',
                'slots'       => 1000,
                'registered'  => 947,
                'status'      => 'completed',
                'is_active'   => true,
            ],
            [
                'title'       => 'Digital Skills for the Workplace',
                'description' => 'A training seminar on essential digital tools: Google Workspace, basic data analysis, social media for business, and remote work tools. Perfect for office workers and fresh graduates.',
                'location'    => 'Santiago City Polytechnic College, Computer Lab',
                'event_date'  => Carbon::now()->toDateString(),
                'event_time'  => '9:00 AM - 4:00 PM',
                'event_type'  => 'Training',
                'organizer'   => 'PESO Santiago City',
                'slots'       => 60,
                'registered'  => 55,
                'status'      => 'ongoing',
                'is_active'   => true,
            ],
        ];

        foreach ($events as $event) {
            Event::create($event);
        }
    }
}
