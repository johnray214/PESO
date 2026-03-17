<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminEventController extends Controller
{
    public function index(Request $request)
    {
        $query = Event::query();
        
        if ($request->has('search')) {
            $search = $request->search;
            $query->where('title', 'like', "%{$search}%");
        }
        
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        if ($request->has('date_from') && $request->has('date_to')) {
            $query->whereBetween('event_date', [$request->date_from, $request->date_to]);
        }

        $events = $query->with('creator:id,first_name,last_name')
            ->orderByDesc('event_date')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $events,
        ]);
    }

    public function show($id)
    {
        $event = Event::with('creator')->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $event,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|string|max:100',
            'location' => 'required|string|max:255',
            'event_date' => 'required|date',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i|after:start_time',
            'organizer' => 'nullable|string|max:255',
            'max_participants' => 'nullable|integer|min:1',
            'status' => ['sometimes', Rule::in(['upcoming', 'ongoing', 'completed', 'cancelled'])],
        ]);

        $validated['created_by'] = $request->user()->id;
        
        $event = Event::create($validated);

        return response()->json([
            'success' => true,
            'data' => $event,
            'message' => 'Event created successfully',
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $event = Event::findOrFail($id);
        
        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'type' => 'sometimes|string|max:100',
            'location' => 'sometimes|string|max:255',
            'event_date' => 'sometimes|date',
            'start_time' => 'sometimes|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i|after:start_time',
            'organizer' => 'nullable|string|max:255',
            'max_participants' => 'nullable|integer|min:1',
            'status' => ['sometimes', Rule::in(['upcoming', 'ongoing', 'completed', 'cancelled'])],
        ]);

        $event->update($validated);

        return response()->json([
            'success' => true,
            'data' => $event,
            'message' => 'Event updated successfully',
        ]);
    }

    public function destroy($id)
    {
        $event = Event::findOrFail($id);
        $event->delete();

        return response()->json([
            'success' => true,
            'message' => 'Event deleted successfully',
        ]);
    }
}
