<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;

class EventController extends Controller
{
    /**
     * Return all active upcoming events, ordered by event_date.
     */
    public function index()
    {
        $events = Event::where('is_active', true)
            ->where('event_date', '>=', now()->toDateString())
            ->orderBy('event_date')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $events,
        ]);
    }
}
