<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Event;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AdminEventController extends Controller
{
    public function index(Request $request)
    {
        $query = Event::withTrashed(false);

        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('title', 'like', "%{$request->search}%")
                  ->orWhere('location', 'like', "%{$request->search}%");
            });
        }

        if ($request->filled('type')) {
            $query->where('event_type', $request->type);
        }

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $events = $query->orderBy('event_date')->paginate($request->get('per_page', 15));

        $events->getCollection()->transform(fn($e) => $this->formatEvent($e));

        return response()->json(['success' => true, 'data' => $events]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title'       => 'required|string|max:255',
            'type'        => 'required|string',
            'description' => 'nullable|string',
            'date'        => 'required|date',
            'time'        => 'nullable|string|max:50',
            'venue'       => 'required|string|max:255',
            'slots'       => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $event = Event::create([
            'title'       => $request->title,
            'description' => $request->description ?? '',
            'location'    => $request->venue,
            'event_date'  => $request->date,
            'event_time'  => $request->time,
            'event_type'  => $request->type,
            'slots'       => $request->slots,
            'registered'  => 0,
            'status'      => 'upcoming',
            'is_active'   => true,
        ]);

        AuditLog::record('Created', 'Events', "Event '{$event->title}' created", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Event created', 'data' => $this->formatEvent($event)], 201);
    }

    public function show($id)
    {
        $event = Event::findOrFail($id);
        return response()->json(['success' => true, 'data' => $this->formatEvent($event)]);
    }

    public function update(Request $request, $id)
    {
        $event = Event::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'title'       => 'sometimes|required|string|max:255',
            'type'        => 'sometimes|required|string',
            'description' => 'nullable|string',
            'date'        => 'sometimes|required|date',
            'time'        => 'nullable|string|max:50',
            'venue'       => 'sometimes|required|string|max:255',
            'slots'       => 'sometimes|required|integer|min:0',
            'status'      => 'sometimes|in:upcoming,ongoing,completed,cancelled',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $event->update([
            'title'       => $request->title ?? $event->title,
            'description' => $request->description ?? $event->description,
            'location'    => $request->venue ?? $event->location,
            'event_date'  => $request->date ?? $event->event_date,
            'event_time'  => $request->time ?? $event->event_time,
            'event_type'  => $request->type ?? $event->event_type,
            'slots'       => $request->slots ?? $event->slots,
            'status'      => $request->status ?? $event->status,
        ]);

        AuditLog::record('Updated', 'Events', "Event '{$event->title}' updated", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Event updated', 'data' => $this->formatEvent($event)]);
    }

    public function destroy(Request $request, $id)
    {
        $event = Event::findOrFail($id);

        AuditLog::record('Deleted', 'Events', "Event '{$event->title}' archived", $request, $request->user());

        $event->delete();

        return response()->json(['success' => true, 'message' => 'Event archived']);
    }

    private function formatEvent(Event $e): array
    {
        return [
            'id'          => $e->id,
            'title'       => $e->title,
            'type'        => $e->event_type,
            'description' => $e->description,
            'day'         => $e->event_date ? $e->event_date->format('d') : null,
            'month'       => $e->event_date ? $e->event_date->format('M') : null,
            'year'        => $e->event_date ? $e->event_date->format('Y') : null,
            'date'        => $e->event_date ? $e->event_date->format('Y-m-d') : null,
            'time'        => $e->event_time,
            'venue'       => $e->location,
            'slots'       => $e->slots,
            'registered'  => $e->registered,
            'status'      => $e->status,
            'is_active'   => $e->is_active,
        ];
    }
}
