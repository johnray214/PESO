<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminNotificationState;
use App\Models\Application;
use App\Models\Employer;
use App\Models\Event;
use App\Models\Jobseeker;
use App\Models\JobListing;
use Illuminate\Http\Request;

/**
 * AdminActivityFeedController
 *
 * Database-backed real-time activity feed for the admin dashboard.
 * Persists read/unread and deleted states per admin user in the database.
 */
class AdminActivityFeedController extends Controller
{
    public function index(Request $request)
    {
        $limit  = (int) $request->get('limit', 500);
        $userId = auth()->id() ?? 1;

        // Auto-prune notification states and records older than 30 days
        try {
            $cutoff = now()->subDays(30);
            AdminNotificationState::where('created_at', '<', $cutoff)->delete();
            \App\Models\NotificationRead::where('created_at', '<', $cutoff)->whereNotNull('read_at')->delete();
        } catch (\Throwable $e) {}

        $states = AdminNotificationState::where('user_id', $userId)->get()->keyBy('notification_id');
        $feed   = collect();

        // 1. New jobseeker registrations
        Jobseeker::select('id', 'first_name', 'last_name', 'created_at', 'status')
            ->orderByDesc('created_at')
            ->limit(100)
            ->get()
            ->each(function ($j) use (&$feed, $states) {
                $notifId = 'js_' . $j->id;
                $state   = $states->get($notifId);
                if ($state && $state->deleted) return;

                $name = trim($j->first_name . ' ' . $j->last_name);
                $feed->push([
                    'id'      => $notifId,
                    'type'    => 'Registration',
                    'title'   => 'New Jobseeker Registered',
                    'message' => "{$name} has registered as a new jobseeker.",
                    'time'    => $j->created_at,
                    'read'    => $state ? $state->read : false,
                ]);
            });

        // 2. New employer registrations
        Employer::select('id', 'company_name', 'status', 'created_at')
            ->orderByDesc('created_at')
            ->limit(100)
            ->get()
            ->each(function ($e) use (&$feed, $states) {
                $notifId = 'emp_' . $e->id;
                $state   = $states->get($notifId);
                if ($state && $state->deleted) return;

                $isPending = $e->status === 'pending';
                $feed->push([
                    'id'      => $notifId,
                    'type'    => 'Registration',
                    'title'   => 'New Employer registered',
                    'message' => "{$e->company_name} signed up and needs verification/approval",
                    'time'    => $e->created_at,
                    'read'    => $state ? $state->read : !$isPending,
                ]);
            });

        // 3. New Job Listing posted
        JobListing::withTrashed()->with('employer:id,company_name')
            ->select('id', 'employer_id', 'title', 'created_at', 'status', 'deleted_at')
            ->orderByDesc('created_at')
            ->limit(100)
            ->get()
            ->each(function ($jl) use (&$feed, $states) {
                $notifId = 'jl_' . $jl->id;
                $state   = $states->get($notifId);
                if ($state && $state->deleted) return;

                $empName = is_null($jl->employer_id) ? 'PESO Staff' : ($jl->employer->company_name ?? 'An employer');

                $feed->push([
                    'id'      => $notifId,
                    'type'    => 'Job',
                    'title'   => 'New Job Listing',
                    'message' => "{$empName} posted a new job listing for {$jl->title}.",
                    'time'    => $jl->created_at,
                    'read'    => $state ? $state->read : false,
                ]);
            });

        // 4 & 5. Recent applications (New and Status Changed)
        Application::with([
                'jobseeker:id,first_name,last_name',
                'jobListing' => function ($q) {
                    $q->withTrashed()->select('id', 'title');
                },
            ])
            ->select('id', 'jobseeker_id', 'job_listing_id', 'status', 'applied_at', 'updated_at', 'created_at')
            ->orderByDesc('updated_at')
            ->limit(100)
            ->get()
            ->each(function ($app) use (&$feed, $states) {
                $js   = $app->jobseeker;
                $name = $js ? trim($js->first_name . ' ' . $js->last_name) : 'A jobseeker';
                $job  = $app->jobListing?->title ?? 'a position';

                // New application
                if ($app->created_at && $app->updated_at && $app->created_at->diffInHours($app->updated_at) < 1 && $app->status === 'pending') {
                    $notifId = 'app_new_' . $app->id;
                    $state   = $states->get($notifId);
                    if ($state && $state->deleted) return;

                    $feed->push([
                        'id'      => $notifId,
                        'type'    => 'Status',
                        'title'   => 'New Application',
                        'message' => "{$name} applied for {$job}.",
                        'time'    => $app->applied_at ?? $app->created_at,
                        'read'    => $state ? $state->read : false,
                    ]);
                } else {
                    $notifId = 'app_upd_' . $app->id;
                    $state   = $states->get($notifId);
                    if ($state && $state->deleted) return;

                    $feed->push([
                        'id'      => $notifId,
                        'type'    => 'Status',
                        'title'   => 'Application status changed',
                        'message' => "Application for {$job} by {$name} is now {$app->status}.",
                        'time'    => $app->updated_at,
                        'read'    => $state ? $state->read : true,
                    ]);
                }
            });

        // 6. Events (upcoming and recent)
        Event::select('id', 'title', 'location', 'event_date', 'created_at', 'status')
            ->orderByDesc('created_at')
            ->limit(100)
            ->get()
            ->each(function ($ev) use (&$feed, $states) {
                $notifId = 'ev_' . $ev->id;
                $state   = $states->get($notifId);
                if ($state && $state->deleted) return;

                try {
                    $dateStr = \Carbon\Carbon::parse($ev->event_date)->format('M d, Y');
                } catch (\Throwable $e) {
                    $dateStr = 'TBD';
                }
                $loc = $ev->location ?? 'Online';
                $feed->push([
                    'id'      => $notifId,
                    'type'    => 'Event',
                    'title'   => "Event: {$ev->title} — {$loc}",
                    'message' => "Event scheduled for {$dateStr}.",
                    'time'    => $ev->created_at,
                    'read'    => $state ? $state->read : ($ev->status === 'completed'),
                ]);
            });

        // Sort by time descending, then format
        $sorted = $feed
            ->sortByDesc(fn($item) => $item['time'])
            ->take($limit)
            ->values()
            ->map(fn($item) => array_merge($item, [
                'time'  => $this->formatRelative($item['time']),
                'title' => $item['title'] ?? 'Notification',
            ]));

        return response()->json([
            'success' => true,
            'data'    => $sorted,
        ]);
    }

    public function markRead(Request $request, $id)
    {
        $userId = auth()->id() ?? 1;
        AdminNotificationState::updateOrCreate(
            ['user_id' => $userId, 'notification_id' => (string)$id],
            ['read' => true, 'read_at' => now()]
        );
        return response()->json(['success' => true]);
    }

    public function markAllRead(Request $request)
    {
        $userId = auth()->id() ?? 1;
        $ids = $request->input('ids', []);
        if (is_array($ids) && count($ids)) {
            foreach ($ids as $id) {
                AdminNotificationState::updateOrCreate(
                    ['user_id' => $userId, 'notification_id' => (string)$id],
                    ['read' => true, 'read_at' => now()]
                );
            }
        } else {
            // Mark all existing states for this user as read
            AdminNotificationState::where('user_id', $userId)->update(['read' => true, 'read_at' => now()]);
        }
        return response()->json(['success' => true]);
    }

    public function destroy(Request $request, $id)
    {
        $userId = auth()->id() ?? 1;
        AdminNotificationState::updateOrCreate(
            ['user_id' => $userId, 'notification_id' => (string)$id],
            ['deleted' => true]
        );
        return response()->json(['success' => true]);
    }

    public function clearRead(Request $request)
    {
        $userId = auth()->id() ?? 1;
        $ids = $request->input('ids', []);
        if (is_array($ids) && count($ids)) {
            foreach ($ids as $id) {
                AdminNotificationState::updateOrCreate(
                    ['user_id' => $userId, 'notification_id' => (string)$id],
                    ['deleted' => true]
                );
            }
        }
        AdminNotificationState::where('user_id', $userId)->where('read', true)->update(['deleted' => true]);
        return response()->json(['success' => true]);
    }

    private function formatRelative($date): string
    {
        if (!$date) return 'just now';
        try {
            $carbon = $date instanceof \Carbon\Carbon
                ? $date
                : \Carbon\Carbon::parse($date);
            $diff = (int) abs(now()->diffInMinutes($carbon));
            if ($diff < 1)       return 'just now';
            if ($diff < 60)      return "{$diff}m ago";
            $h = (int) floor($diff / 60);
            if ($h < 24)         return "{$h}h ago";
            return floor($h / 24) . 'd ago';
        } catch (\Throwable $e) {
            return 'just now';
        }
    }
}
