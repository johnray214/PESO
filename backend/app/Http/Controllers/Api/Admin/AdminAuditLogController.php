<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\Request;

class AdminAuditLogController extends Controller
{
    public function index(Request $request)
    {
        $query = AuditLog::query();

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('user_name', 'like', "%{$search}%")
                  ->orWhere('detail', 'like', "%{$search}%");
            });
        }

        if ($request->filled('user')) {
            $query->where('user_name', 'like', "%{$request->user}%");
        }

        if ($request->filled('module')) {
            $query->where('module', $request->module);
        }

        if ($request->filled('action')) {
            $query->where('action', $request->action);
        }

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $logs = $query->latest()->paginate($request->get('per_page', 20));

        $logs->getCollection()->transform(fn($log) => [
            'id'     => $log->id,
            'date'   => $log->created_at->format('M d, Y'),
            'time'   => $log->created_at->format('H:i:s'),
            'user'   => $log->user_name ?? 'System',
            'role'   => $log->role ?? 'System',
            'action' => $log->action,
            'module' => $log->module,
            'detail' => $log->detail,
            'ip'     => $log->ip_address,
        ]);

        return response()->json(['success' => true, 'data' => $logs]);
    }
}
