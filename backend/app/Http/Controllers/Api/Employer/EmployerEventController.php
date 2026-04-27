<?php

namespace App\Http\Controllers\Api\Employer;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;

class EmployerEventController extends Controller
{
    /**
     * List all events (read-only for employers).
     * Supports: search, status, type, date_from, date_to
     */
    public function index(Request $request)
    {
        $query = Event::query();

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where('title', 'like', "%{$search}%");
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        if ($request->filled('date_from') && $request->filled('date_to')) {
            $query->whereBetween('event_date', [$request->date_from, $request->date_to]);
        }

        $events = $query
            ->withCount(['registrations as participants_count'])
            ->orderByDesc('event_date')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data'    => $events,
        ]);
    }

    /**
     * Show a single event detail (read-only).
     */
    public function show($id)
    {
        $event = Event::query()
            ->withCount(['registrations as participants_count'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $event,
        ]);
    }
}