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
                'event_type'  => 'job_fair',
                'organizer'   => 'PESO Santiago City',
            ],
            [
                'title'       => 'Career Development Seminar: Resume Writing',
                'description' => 'Learn how to create a standout resume that gets you noticed by recruiters. Professional trainers will share tips on formatting, keywords, and tailoring your resume for different industries.',
                'location'    => 'SM City Santiago, Function Room 2',
                'event_date'  => Carbon::now()->addDays(7)->toDateString(),
                'event_time'  => '2:00 PM - 5:00 PM',
                'event_type'  => 'seminar',
                'organizer'   => 'PESO Isabela',
            ],
            [
                'title'       => 'Tech Industry Career Fair',
                'description' => 'IT and software companies from Cagayan Valley will be onsite. Opportunities for developers, designers, IT support, and digital marketing. Some companies offer on-the-spot interviews.',
                'location'    => 'Robinsons Place Santiago, Activity Center',
                'event_date'  => Carbon::now()->addDays(21)->toDateString(),
                'event_time'  => '10:00 AM - 6:00 PM',
                'event_type'  => 'job_fair',
                'organizer'   => 'Department of Labor and Employment',
            ],
            [
                'title'       => 'Interview Skills Workshop',
                'description' => 'Boost your confidence for job interviews. Topics include common questions, body language, salary negotiation, and following up. Includes mock interview practice sessions.',
                'location'    => 'PESO Santiago Office, Training Room',
                'event_date'  => Carbon::now()->addDays(10)->toDateString(),
                'event_time'  => '9:00 AM - 12:00 PM',
                'event_type'  => 'seminar',
                'organizer'   => 'PESO Santiago City',
            ],
            [
                'title'       => 'Summer Employment Expo',
                'description' => 'Perfect for students and graduates seeking summer jobs or entry-level positions. Retail, food service, and tourism employers will have booths. Free admission.',
                'location'    => 'Santiago City Public Market, Multi-Purpose Hall',
                'event_date'  => Carbon::now()->addDays(28)->toDateString(),
                'event_time'  => '8:00 AM - 3:00 PM',
                'event_type'  => 'career_event',
                'organizer'   => 'Local Government Unit - Santiago City',
            ],
            [
                'title'       => 'OFW Reintegration Forum',
                'description' => 'Returning OFWs: Learn about local job opportunities, livelihood programs, and skills training. Connect with government agencies offering support for reintegration.',
                'location'    => 'Isabela State University - Santiago Campus',
                'event_date'  => Carbon::now()->addDays(35)->toDateString(),
                'event_time'  => '1:00 PM - 5:00 PM',
                'event_type'  => 'seminar',
                'organizer'   => 'Overseas Workers Welfare Administration (OWWA)',
            ],
        ];

        foreach ($events as $event) {
            Event::create($event);
        }
    }
}
