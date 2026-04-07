<?php

namespace App\Http\Controllers\Api\Admin;

use App\Events\EmployerNotificationEvent;
use App\Http\Controllers\Controller;
use App\Models\JobListing;
use App\Models\Notification;
use App\Models\NotificationRead;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminJobListingController extends Controller
{
    public function index(Request $request)
    {
        $query = JobListing::query();

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('location', 'like', "%{$search}%");
            });
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('employer_id')) {
            $query->where('employer_id', $request->employer_id);
        }

        $jobListings = $query->with('employer:id,company_name')
            ->orderByDesc('created_at')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data'    => $jobListings,
        ]);
    }

    public function show($id)
    {
        $jobListing = JobListing::with(['employer', 'skills'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $jobListing,
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $validated = $request->validate([
            'status' => ['required', Rule::in(['open', 'closed', 'draft'])],
        ]);

        $jobListing = JobListing::findOrFail($id);
        $oldStatus  = $jobListing->status;
        $newStatus  = $validated['status'];

        $jobListing->update($validated);

        // ── Real-time: notify employer via Pusher whenever admin changes the status ──
        if ($oldStatus !== $newStatus && $jobListing->employer_id) {
            [$type, $title, $message] = match ($newStatus) {
                'open'   => [
                    'job',
                    'Job Listing Reactivated',
                    "Your job listing \"{$jobListing->title}\" has been reactivated by the admin and is now open for applications.",
                ],
                'closed' => [
                    'job',
                    'Job Listing Closed',
                    "Your job listing \"{$jobListing->title}\" has been closed by the admin.",
                ],
                default  => [
                    'system',
                    'Job Listing Updated',
                    "Your job listing \"{$jobListing->title}\" status has been changed to {$newStatus} by the admin.",
                ],
            };

            // Persist to DB so it appears in the employer's notifications list
            $notification = Notification::create([
                'subject'        => $title,
                'message'        => $message,
                'type'           => $type,
                'job_listing_id' => $jobListing->id,
                'recipients'     => 'specific',
                'scheduled_at'   => null,
                'sent_at'        => now(),
                'status'         => 'sent',
                'created_by'     => null,
            ]);

            $notifRead = NotificationRead::create([
                'notification_id' => $notification->id,
                'recipient_type'  => 'employer',
                'recipient_id'    => $jobListing->employer_id,
                'read_at'         => null,
            ]);

            // 🔴 Push to the employer's private Pusher channel in real-time
            event(new EmployerNotificationEvent(
                $jobListing->employer_id,
                $notifRead->id,
                $type,
                $title,
                $message
            ));
        }

        return response()->json([
            'success' => true,
            'data'    => $jobListing,
            'message' => 'Job listing status updated successfully',
        ]);
    }

    public function destroy($id)
    {
        $jobListing = JobListing::findOrFail($id);
        $jobListing->delete();

        return response()->json([
            'success' => true,
            'message' => 'Job listing deleted successfully',
        ]);
    }
}
