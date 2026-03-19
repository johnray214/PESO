<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;

class PublicEventController extends Controller
{
    public function index(Request $request)
    {
        $query = Event::query();

        if ($request->has('search')) {
            $search = $request->search;
            $query->where('title', 'like', "%{$search}%");
        }

        // Only show non-cancelled events by default
        $status = $request->get('status');
        if ($status) {
            $query->where('status', $status);
        } else {
            $query->whereIn('status', ['upcoming', 'ongoing', 'completed']);
        }

        $events = $query
            ->orderByDesc('event_date')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $events,
        ]);
    }

    public function show(Request $request, $id)
    {
        $event = Event::findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $event,
        ]);
    }
}

