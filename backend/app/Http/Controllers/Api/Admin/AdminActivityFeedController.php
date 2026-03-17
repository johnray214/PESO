<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\Employer;
use App\Models\Event;
use App\Models\Jobseeker;
use Illuminate\Http\Request;

/**
 * AdminActivityFeedController
 *
 * Returns a real-time activity feed for the admin dashboard topbar.
 * Aggregates real system events: registrations, applications, events.
 */
class AdminActivityFeedController extends Controller
{
    public function index(Request $request)
    {
        $limit = (int) $request->get('limit', 30);
        $feed  = collect();

        // 1. New jobseeker registrations
        Jobseeker::select('id', 'first_name', 'last_name', 'created_at', 'status')
            ->orderByDesc('created_at')
            ->limit(10)
            ->get()
            ->each(function ($j) use (&$feed) {
                $name = trim($j->first_name . ' ' . $j->last_name);
                $feed->push([
                    'id'      => 'js_' . $j->id,
                    'type'    => 'Registration',
                    'title'   => 'New Jobseeker Registered',
                    'message' => "{$name} has registered as a new jobseeker.",
                    'time'    => $j->created_at,
                    'read'    => false,
                ]);
            });

        // 2. New employer registrations
        Employer::select('id', 'company_name', 'status', 'created_at')
            ->orderByDesc('created_at')
            ->limit(10)
            ->get()
            ->each(function ($e) use (&$feed) {
                $isPending = $e->status === 'pending';
                $feed->push([
                    'id'      => 'emp_' . $e->id,
                    'type'    => 'Registration',
                    'title'   => 'New Employer Registered',
                    'message' => "{$e->company_name} registered as a new employer." . ($isPending ? ' Pending verification.' : ''),
                    'time'    => $e->created_at,
                    'read'    => !$isPending,
                ]);
            });

        // 3. Recent applications
        Application::with([
                'jobseeker:id,first_name,last_name',
                'jobListing:id,title',
            ])
            ->select('id', 'jobseeker_id', 'job_listing_id', 'status', 'applied_at', 'created_at')
            ->orderByDesc('applied_at')
            ->limit(10)
            ->get()
            ->each(function ($app) use (&$feed) {
                $js   = $app->jobseeker;
                $name = $js ? trim($js->first_name . ' ' . $js->last_name) : 'A jobseeker';
                $job  = $app->jobListing?->title ?? 'a position';
                $feed->push([
                    'id'      => 'app_' . $app->id,
                    'type'    => 'Status',
                    'title'   => 'New Application',
                    'message' => "{$name} applied for {$job}.",
                    'time'    => $app->applied_at ?? $app->created_at,
                    'read'    => in_array($app->status, ['hired', 'rejected']),
                ]);
            });

        // 4. Events (upcoming and recent)
        Event::select('id', 'title', 'event_date', 'created_at', 'status')
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->each(function ($ev) use (&$feed) {
                try {
                    $dateStr = \Carbon\Carbon::parse($ev->event_date)->format('M d, Y');
                } catch (\Throwable $e) {
                    $dateStr = 'TBD';
                }
                $feed->push([
                    'id'      => 'ev_' . $ev->id,
                    'type'    => 'Event',
                    'title'   => 'Event: ' . $ev->title,
                    'message' => "Event scheduled for {$dateStr}.",
                    'time'    => $ev->created_at,
                    'read'    => $ev->status === 'completed',
                ]);
            });

        // Sort by time descending, then format
        $sorted = $feed
            ->sortByDesc(fn($item) => $item['time'])
            ->take($limit)
            ->values()
            ->map(fn($item) => array_merge($item, [
                'time' => $this->formatRelative($item['time']),
            ]));

        return response()->json([
            'success' => true,
            'data'    => $sorted,
        ]);
    }

    public function markRead(Request $request, $id)
    {
        return response()->json(['success' => true]);
    }

    public function markAllRead(Request $request)
    {
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
