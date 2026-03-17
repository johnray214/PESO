<?php

namespace App\Http\Controllers\Api\Jobseeker;

use App\Http\Controllers\Controller;
use App\Models\NotificationRead;
use Illuminate\Http\Request;

class JobseekerNotificationController extends Controller
{
    public function index(Request $request)
    {
        $jobseeker = $request->user();
        
        $query = NotificationRead::where('recipient_type', 'jobseeker')
            ->where('recipient_id', $jobseeker->id)
            ->with('notification');
        
        if ($request->has('is_read')) {
            if ($request->is_read) {
                $query->whereNotNull('read_at');
            } else {
                $query->whereNull('read_at');
            }
        }

        $notifications = $query->orderByDesc('created_at')->paginate(15);

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
}
