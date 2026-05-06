<?php

namespace App\Http\Controllers\Api\Jobseeker;

use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\NotificationRead;
use Carbon\Carbon;
use Illuminate\Http\Request;

class JobseekerNotificationController extends Controller
{
    private function hydrateInterviewMetaFromApplication(NotificationRead $notificationRead): void
    {
        $notification = $notificationRead->notification;
        if (! $notification) return;

        $type = $notification->type ?? null;

        // ── Interview backfill ───────────────────────────────────────────────
        if ($type === 'status_interview' && empty($notification->meta)) {
            $jobListingId = $notification->job_listing_id;
            if (! $jobListingId) return;

            $app = Application::where('job_listing_id', $jobListingId)
                ->where('jobseeker_id', $notificationRead->recipient_id)
                ->first();
            if (! $app) return;

            $notification->meta = [
                'interview_date'     => ! empty($app->interview_date) ? Carbon::parse($app->interview_date)->format('F d, Y') : 'TBA',
                'interview_time'     => ! empty($app->interview_time) ? Carbon::parse($app->interview_time)->format('h:i A') : 'TBA',
                'interview_format'   => $app->interview_format ?: 'In-person',
                'interview_location' => $app->interview_location ?: 'TBA',
                'interviewer_name'   => $app->interviewer_name ?: 'Hiring Manager',
            ];
        }

        // ── Hired backfill ───────────────────────────────────────────────────
        if ($type === 'status_hired' && empty($notification->meta)) {
            $jobListingId = $notification->job_listing_id;
            if (! $jobListingId) return;

            $jobListing = $notification->jobListing;
            if (! $jobListing) return;

            $notification->meta = [
                'job_title'       => $jobListing->title ?? 'N/A',
                'company_name'    => $jobListing->employer->company_name ?? 'N/A',
                'start_date'      => 'To be discussed',
                'salary'          => $jobListing->salary_range ?? 'Negotiable',
                'employment_type' => $jobListing->job_type ?? 'Full-time',
            ];
        }

        // ── Rejected backfill ────────────────────────────────────────────────
        if ($type === 'status_rejected' && empty($notification->meta)) {
            $jobListing = $notification->jobListing;
            if (! $jobListing) return;

            $notification->meta = [
                'job_title'    => $jobListing->title ?? 'N/A',
                'company_name' => $jobListing->employer->company_name ?? 'N/A',
                'update_date'  => $notification->created_at
                    ? Carbon::parse($notification->created_at)->format('F d, Y')
                    : now()->format('F d, Y'),
            ];
        }

        // ── Job-offer sent backfill (for older notifications missing meta) ──
        if ($type === 'status_for_job_offer_sent') {
            $meta = is_array($notification->meta) ? $notification->meta : [];
            $hasApplicationId = !empty($meta['application_id']);
            if ($hasApplicationId) return;

            $jobListingId = $notification->job_listing_id;
            if (! $jobListingId) return;

            $app = Application::where('job_listing_id', $jobListingId)
                ->where('jobseeker_id', $notificationRead->recipient_id)
                ->where('status', 'for_job_offer')
                ->latest('id')
                ->first();
            if (! $app) return;

            $jobListing = $notification->jobListing;
            $meta['application_id'] = $app->id;
            $meta['job_title'] = $meta['job_title'] ?? ($jobListing->title ?? 'N/A');
            $meta['company_name'] = $meta['company_name'] ?? ($jobListing->employer->company_name ?? 'N/A');
            $meta['start_date'] = $meta['start_date'] ?? 'To be discussed';
            $meta['salary'] = $meta['salary'] ?? ($jobListing->salary_range ?? 'Negotiable');
            $meta['employment_type'] = $meta['employment_type'] ?? ($jobListing->job_type ?? 'Full-time');
            $notification->meta = $meta;
        }
    }

    public function index(Request $request)
    {
        $jobseeker = $request->user();
        
        $query = NotificationRead::where('recipient_type', 'jobseeker')
            ->where('recipient_id', $jobseeker->id)
            ->with([
                'notification',
                'notification.jobListing',
                'notification.jobListing.employer',
                'notification.jobListing.skills',
            ]);
        
        if ($request->has('is_read')) {
            if ($request->is_read) {
                $query->whereNotNull('read_at');
            } else {
                $query->whereNull('read_at');
            }
        }

        $notifications = $query->orderByDesc('created_at')->paginate(15);

        // Backfill interview schedule details for older notifications that have no meta.
        $notifications->getCollection()->transform(function ($nr) {
            if ($nr instanceof NotificationRead) {
                $this->hydrateInterviewMetaFromApplication($nr);
            }
            return $nr;
        });

        return response()->json([
            'success' => true,
            'data' => $notifications,
        ]);
    }

    public function show(Request $request, $id)
    {
        $jobseeker = $request->user();
        
        $notificationRead = NotificationRead::where('recipient_type', 'jobseeker')
            ->where('recipient_id', $jobseeker->id)
            ->with('notification')
            ->findOrFail($id);

        $this->hydrateInterviewMetaFromApplication($notificationRead);
        
        // Mark as read when viewed
        $notificationRead->markAsRead();
        
        return response()->json([
            'success' => true,
            'data' => $notificationRead,
        ]);
    }

    public function unreadCount(Request $request)
    {
        $jobseeker = $request->user();
        
        $count = NotificationRead::where('recipient_type', 'jobseeker')
            ->where('recipient_id', $jobseeker->id)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'success' => true,
            'data' => ['unread_count' => $count],
        ]);
    }

    public function markAllAsRead(Request $request)
    {
        $jobseeker = $request->user();
        
        NotificationRead::where('recipient_type', 'jobseeker')
            ->where('recipient_id', $jobseeker->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'All notifications marked as read',
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $jobseeker = $request->user();

        $notificationRead = NotificationRead::where('recipient_type', 'jobseeker')
            ->where('recipient_id', $jobseeker->id)
            ->findOrFail($id);

        $notificationId = $notificationRead->notification_id;
        $notificationRead->delete();

        // If no other reads reference this notification, hard delete the notification itself
        if (!NotificationRead::where('notification_id', $notificationId)->exists()) {
            \App\Models\Notification::where('id', $notificationId)->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Notification deleted',
        ]);
    }

    public function destroyAllRead(Request $request)
    {
        $jobseeker = $request->user();

        // Collect all notification_ids for this jobseeker before deleting
        $notificationIds = NotificationRead::where('recipient_type', 'jobseeker')
            ->where('recipient_id', $jobseeker->id)
            ->pluck('notification_id')
            ->toArray();

        NotificationRead::where('recipient_type', 'jobseeker')
            ->where('recipient_id', $jobseeker->id)
            ->delete();

        // For each notification, if no reads remain anywhere, delete the notification row
        if (!empty($notificationIds)) {
            $uniqueIds = array_unique($notificationIds);
            foreach ($uniqueIds as $nid) {
                if (!NotificationRead::where('notification_id', $nid)->exists()) {
                    \App\Models\Notification::where('id', $nid)->delete();
                }
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'All notifications deleted',
        ]);
    }
}
