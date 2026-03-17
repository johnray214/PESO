<?php

namespace Database\Seeders;

use App\Models\Employer;
use App\Models\Notification;
use App\Models\NotificationRead;
use App\Models\User;
use Illuminate\Database\Seeder;

class NotificationSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::where('role', 'admin')->first();
        $adminId = $admin?->id;

        $employers = Employer::all();

        if ($employers->isEmpty()) {
            $this->command->warn('No employers found — skipping NotificationSeeder.');
            return;
        }

        // ---------- Templates ----------
        // Each notification that targets 'employers' will get a NotificationRead per employer.
        $templates = [
            [
                'subject'    => 'New High-Match Applicant',
                'message'    => 'A jobseeker with a 92% skill match applied to your job listing. Review the application now.',
                'type_hint'  => 'match',
                'recipients' => 'employers',
                'offset_min' => 2,
            ],
            [
                'subject'    => 'New Application Received',
                'message'    => 'A jobseeker has applied to one of your active job listings. Check new applicants in your dashboard.',
                'type_hint'  => 'applicant',
                'recipients' => 'employers',
                'offset_min' => 25,
            ],
            [
                'subject'    => 'Applicant Withdrew Application',
                'message'    => 'An applicant has withdrawn their application from one of your job listings.',
                'type_hint'  => 'applicant',
                'recipients' => 'employers',
                'offset_min' => 80,
            ],
            [
                'subject'    => 'Job Listing Expiring Soon',
                'message'    => 'One of your active job listings is expiring in 3 days. Extend the deadline or close the listing.',
                'type_hint'  => 'job',
                'recipients' => 'employers',
                'offset_min' => 200,
            ],
            [
                'subject'    => 'Profile Verification Complete',
                'message'    => 'Your employer profile has been verified by PESO. Your job listings are now visible to jobseekers.',
                'type_hint'  => 'system',
                'recipients' => 'employers',
                'offset_min' => 1440,
            ],
            [
                'subject'    => 'Potential Applicants Available',
                'message'    => 'There are 5 jobseekers whose skills match your active job listings but have not yet applied.',
                'type_hint'  => 'match',
                'recipients' => 'employers',
                'offset_min' => 480,
            ],
            [
                'subject'    => 'Job Listing is Now Active',
                'message'    => 'Your job listing has been approved and is now live on the portal.',
                'type_hint'  => 'job',
                'recipients' => 'employers',
                'offset_min' => 2880,
            ],
        ];

        $notifCount = 0;
        $readCount  = 0;

        foreach ($templates as $tpl) {
            $notif = Notification::create([
                'subject'    => $tpl['subject'],
                'message'    => $tpl['message'],
                'recipients' => $tpl['recipients'],
                'status'     => 'sent',
                'sent_at'    => now()->subMinutes($tpl['offset_min']),
                'created_by' => $adminId,
            ]);

            // Create a NotificationRead record for every employer
            foreach ($employers as $employer) {
                // Vary read status: older notifications tend to be read
                $isRead = $tpl['offset_min'] > 200;

                NotificationRead::create([
                    'notification_id' => $notif->id,
                    'recipient_type'  => 'employer',
                    'recipient_id'    => $employer->id,
                    'read_at'         => $isRead ? now()->subMinutes($tpl['offset_min'] - 10) : null,
                    'created_at'      => now()->subMinutes($tpl['offset_min']),
                    'updated_at'      => now()->subMinutes($tpl['offset_min']),
                ]);
                $readCount++;
            }

            $notifCount++;
        }

        $this->command->info("NotificationSeeder: created {$notifCount} notifications, {$readCount} notification_reads ({$employers->count()} employers).");
    }
}
