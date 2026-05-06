<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ApplicationActivityLog;
use App\Models\JobListing;
use App\Models\Jobseeker;
use App\Models\Notification;
use App\Models\NotificationRead;
use Illuminate\Http\Request;

class AdminInvitationController extends Controller
{
    public function sendInvitation(Request $request, $jobseekerId)
    {
        $validated = $request->validate([
            'job_listing_id' => 'required|integer|exists:job_listings,id',
        ]);

        $job = JobListing::with(['employer', 'skills'])->findOrFail($validated['job_listing_id']);

        $jobseeker = Jobseeker::with('skills')
            ->where('id', $jobseekerId)
            ->where('status', 'active')
            ->firstOrFail();

        $company   = $job->employer->company_name ?? 'Employer';
        $topSkills = $jobseeker->skills ? $jobseeker->skills->pluck('skill')->take(3)->implode(', ') : 'your listed skills';
        $applyUrl  = env('FRONTEND_URL', 'http://localhost:5173') . '/jobseeker/jobs/' . $job->id;

        // Calculate match score
        $matchScore = \App\Models\Application::calculateMatchScore($jobseeker, $job);

        // Notification to jobseeker
        $notification = Notification::create([
            'subject'        => "PESO Santiago has endorsed you for a job at {$company}",
            'message'        => "PESO Santiago has reviewed your profile and endorsed you for a job opportunity at {$company} ({$job->title}).",
            'type'           => 'invitation',
            'job_listing_id' => $job->id,
            'recipients'     => 'specific',
            'scheduled_at'   => null,
            'sent_at'        => now(),
            'status'         => 'sent',
            'created_by'     => $request->user()->id ?? null,
        ]);

        NotificationRead::create([
            'notification_id' => $notification->id,
            'recipient_type'  => 'jobseeker',
            'recipient_id'    => $jobseeker->id,
            'read_at'         => null,
        ]);

        // Log activity — find application if exists
        $application = \App\Models\Application::where('jobseeker_id', $jobseeker->id)
            ->where('job_listing_id', $job->id)
            ->first();

        if ($application) {
            ApplicationActivityLog::create([
                'application_id' => $application->id,
                'actor_type'     => 'peso',
                'actor_label'    => 'PESO Santiago',
                'action'         => 'Invited (PESO Santiago)',
            ]);
        }

        // Send Mailjet email
        try {
            $mj = new \Mailjet\Client(env('MAILJET_API_KEY'), env('MAILJET_SECRET_KEY'), true, ['version' => 'v3.1']);

            $invitationText = "PESO Santiago has reviewed your profile and endorsed you for a job opportunity at {$company}.";

            $body = [
                'Messages' => [[
                    'From'             => ['Email' => env('MAILJET_FROM_EMAIL', 'peso@posuechague.site'), 'Name' => env('MAILJET_FROM_NAME', 'PESO Santiago')],
                    'To'               => [['Email' => $jobseeker->email, 'Name' => trim($jobseeker->first_name . ' ' . $jobseeker->last_name)]],
                    'TemplateID'       => 7869914,
                    'TemplateLanguage' => true,
                    'Subject'          => "You're Qualified — {$job->title} at {$company}",
                    'Variables'        => [
                        'first_name'      => $jobseeker->first_name,
                        'invited_by'      => 'PESO Santiago',
                        'hero_subtext'    => 'PESO Santiago has reviewed your profile and is recommending you for this opportunity.',
                        'invitation_text' => $invitationText,
                        'company_name'    => $company,
                        'job_title'       => $job->title,
                        'job_location'    => $job->location ?? 'On-site',
                        'employment_type' => $job->job_type ?? 'Full-time',
                        'salary_range'    => $job->salary_range ?? 'Negotiable',
                        'work_setup'      => $job->work_setup ?? 'On-site',
                        'match_pct'       => (string) round($matchScore),
                        'top_skills'      => $topSkills ?: 'your listed skills',
                        'apply_url'       => $applyUrl,
                    ],
                ]],
            ];

            $response = $mj->post(\Mailjet\Resources::$Email, ['body' => $body]);

            if (!$response->success()) {
                \Illuminate\Support\Facades\Log::error('Mailjet Admin Invite Error: ' . json_encode($response->getData()));
            }
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Mailjet Admin Invite Exception: ' . $e->getMessage());
        }

        return response()->json([
            'success' => true,
            'message' => 'PESO Santiago invitation sent successfully.',
        ]);
    }
}
