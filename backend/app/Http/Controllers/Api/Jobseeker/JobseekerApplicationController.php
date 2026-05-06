<?php

namespace App\Http\Controllers\Api\Jobseeker;

use App\Events\AdminActivityEvent;
use App\Events\EmployerNotificationEvent;
use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\JobListing;
use App\Models\Notification;
use App\Models\NotificationRead;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class JobseekerApplicationController extends Controller
{
    public function index(Request $request)
    {
        $jobseeker = $request->user();
        
        $query = Application::where('jobseeker_id', $jobseeker->id);
        
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $applications = $query->with([
                'jobListing:id,title,type,location,salary_range,description,slots,deadline,posted_date,created_at,employer_id',
                'jobListing.employer:id,company_name',
                'jobListing.skills:id,job_listing_id,skill',
            ])
            ->orderByDesc('applied_at')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $applications,
        ]);
    }

    public function show(Request $request, $id)
    {
        $jobseeker = $request->user();
        
        $application = Application::where('jobseeker_id', $jobseeker->id)
            ->with(['jobListing.employer'])
            ->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $application,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'job_listing_id' => 'required|exists:job_listings,id',
        ]);

        $jobseeker = $request->user();
        $jobListing = JobListing::findOrFail($validated['job_listing_id']);

        // Check if already applied
        $existing = Application::where('job_listing_id', $jobListing->id)
            ->where('jobseeker_id', $jobseeker->id)
            ->first();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'You have already applied for this job',
            ], 422);
        }

        // Check if job is open
        if (!$jobListing->isOpen()) {
            return response()->json([
                'success' => false,
                'message' => 'This job is no longer open for applications',
            ], 422);
        }

        // Calculate match score
        $matchScore = Application::calculateMatchScore($jobseeker, $jobListing);

        $application = Application::create([
            'job_listing_id' => $jobListing->id,
            'jobseeker_id' => $jobseeker->id,
            'status' => 'reviewing',
            'match_score' => $matchScore,
            'applied_at' => now(),
        ]);

        // Create notification for jobseekers: Registration (first time applying)
        $notification = Notification::create([
            'subject'    => 'Application submitted',
            'message'    => "Your application for {$jobListing->title} at {$jobListing->employer->company_name} has been received and is under review.",
            'recipients' => 'jobseekers',
            'scheduled_at' => null,
            'sent_at'    => now(),
            'status'     => 'sent',
            'created_by' => null,
        ]);

        NotificationRead::create([
            'notification_id' => $notification->id,
            'recipient_type'  => 'jobseeker',
            'recipient_id'    => $jobseeker->id,
            'read_at'         => null,
        ]);

        // Create notification for Employer: New Applicant
        $employerNotification = Notification::create([
            'subject'        => 'New Job Applicant',
            'message'        => "{$jobseeker->fullName()} has submitted an application for the {$jobListing->title} position.",
            'type'           => 'applicant',
            'job_listing_id' => $jobListing->id,
            'recipients'     => 'specific',
            'scheduled_at'   => null,
            'sent_at'        => now(),
            'status'         => 'sent',
            'created_by'     => null,
        ]);

        $employerNotifRead = NotificationRead::create([
            'notification_id' => $employerNotification->id,
            'recipient_type'  => 'employer',
            'recipient_id'    => $jobListing->employer_id,
            'read_at'         => null,
        ]);

        // 🔴 Real-time: push to admin feed channel
        event(new AdminActivityEvent(
            'Status',
            'New Application',
            "{$jobseeker->fullName()} applied for {$jobListing->title}.",
            'app_new_' . $application->id
        ));

        // 🔴 Real-time: push to the specific employer's private channel
        event(new EmployerNotificationEvent(
            $jobListing->employer_id,
            $employerNotifRead->id,
            'applicant',
            'New Job Applicant',
            "{$jobseeker->fullName()} has submitted an application for the {$jobListing->title} position."
        ));

        return response()->json([
            'success' => true,
            'data' => $application,
            'message' => 'Application submitted successfully',
        ], 201);
    }

    public function withdraw(Request $request, $id)
    {
        $jobseeker = $request->user();
        
        $application = Application::where('jobseeker_id', $jobseeker->id)
            ->whereIn('status', ['reviewing', 'shortlisted'])
            ->findOrFail($id);
        
        $application->delete();

        return response()->json([
            'success' => true,
            'message' => 'Application withdrawn successfully',
        ]);
    }

    public function respondOffer(Request $request, $id)
    {
        $jobseeker = $request->user();

        $validated = $request->validate([
            'response' => ['required', Rule::in(['accepted', 'declined'])],
        ]);

        $application = Application::where('jobseeker_id', $jobseeker->id)
            ->where('status', 'for_job_offer')
            ->with(['jobListing', 'jobListing.employer'])
            ->findOrFail($id);

        if (!empty($application->offer_response)) {
            return response()->json([
                'success' => false,
                'message' => 'You have already responded to this offer.',
            ], 422);
        }

        $application->update([
            'offer_response' => $validated['response'],
            'offer_response_at' => now(),
        ]);

        $jobListing = $application->jobListing;

        // Notification for Employer
        $employerNotification = Notification::create([
            'subject'        => 'Offer Response Received',
            'message'        => "{$jobseeker->fullName()} has {$validated['response']} your job offer for {$jobListing->title}.",
            'type'           => 'applicant',
            'job_listing_id' => $jobListing->id,
            'recipients'     => 'specific',
            'scheduled_at'   => null,
            'sent_at'        => now(),
            'status'         => 'sent',
            'created_by'     => null,
        ]);

        $employerNotifRead = NotificationRead::create([
            'notification_id' => $employerNotification->id,
            'recipient_type'  => 'employer',
            'recipient_id'    => $jobListing->employer_id,
            'read_at'         => null,
        ]);

        event(new EmployerNotificationEvent(
            $jobListing->employer_id,
            $employerNotifRead->id,
            'applicant',
            'Offer Response Received',
            "{$jobseeker->fullName()} has {$validated['response']} your job offer for {$jobListing->title}."
        ));

        // If declined, send acknowledgment email using Rejected template (7972299)
        if ($validated['response'] === 'declined') {
            try {
                $mj = new \Mailjet\Client(env('MAILJET_API_KEY'), env('MAILJET_SECRET_KEY'), true, ['version' => 'v3.1']);
                $body = [
                    'Messages' => [
                        [
                            'From' => [ 'Email' => env('MAILJET_FROM_EMAIL'), 'Name' => env('MAILJET_FROM_NAME', 'PESO Santiago') ],
                            'To' => [ [ 'Email' => $jobseeker->email, 'Name' => trim($jobseeker->first_name . ' ' . $jobseeker->last_name) ] ],
                            'TemplateID' => 7972299,
                            'TemplateLanguage' => true,
                            'Subject' => 'Acknowledgment: Job Offer Declined',
                            'Variables' => [
                                'first_name'   => $jobseeker->first_name,
                                'company_name' => $jobListing->employer->company_name ?? 'Employer',
                                'job_title'    => $jobListing->title,
                            ]
                        ]
                    ]
                ];
                $response = $mj->post(\Mailjet\Resources::$Email, ['body' => $body]);
                if (!$response->success()) {
                    \Illuminate\Support\Facades\Log::error('Mailjet API Error Decline Ack Email: ' . json_encode($response->getData()));
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::error('Mailjet Exception Decline Ack Email: ' . $e->getMessage());
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Your response has been recorded successfully.',
        ]);
    }
}
