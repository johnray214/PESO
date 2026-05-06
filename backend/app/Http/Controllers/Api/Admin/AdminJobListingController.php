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
    private function normalise(string $value): string
    {
        return strtolower(trim($value));
    }

    private function resolveSkillNames(array $skills): array
    {
        $canonical = [];
        foreach ($skills as $raw) {
            if (!is_string($raw) || trim($raw) === '') continue;
            $name = trim(preg_replace('/\s+/', ' ', $raw));
            
            $slugBase = \Illuminate\Support\Str::slug($name);
            $slug = $slugBase ?: \Illuminate\Support\Str::random(12);

            $skill = \App\Models\Skill::firstOrCreate(
                ['name' => $name],
                ['slug' => $slug, 'is_active' => true]
            );
            
            $canonical[mb_strtolower($skill->name)] = $skill->name;
        }
        return array_values($canonical);
    }

    public function index(Request $request)
    {
        $query = JobListing::query();

        if ($request->has('search') && $request->search !== '') {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('location', 'like', "%{$search}%")
                  ->orWhereHas('employer', fn($q2) => $q2->where('company_name', 'like', "%{$search}%"))
                  ->orWhere('employer_name', 'like', "%{$search}%");
            });
        }

        if ($request->has('status') && $request->status !== '') {
            $query->whereRaw('LOWER(status) = ?', [strtolower($request->status)]);
        }

        if ($request->has('type') && $request->type !== '') {
            $query->whereRaw('LOWER(type) = ?', [strtolower($request->type)]);
        }

        if ($request->has('program') && $request->program !== '') {
            $query->where('program', $request->program);
        }

        if ($request->has('employer_id')) {
            $query->where('employer_id', $request->employer_id);
        }

        $jobListings = $query->with(['employer:id,company_name', 'skills'])
            ->withCount([
                'applications',
                'applications as hired_count' => fn ($q) => $q->where('status', 'hired'),
            ])
            ->orderByDesc('created_at')
            ->paginate(50);

        return response()->json([
            'success' => true,
            'data'    => $jobListings,
        ]);
    }

    public function show($id)
    {
        $jobListing = JobListing::with(['employer', 'skills', 'applications.jobseeker:id,first_name,last_name'])
            ->withCount([
                'applications',
                'applications as hired_count' => fn ($q) => $q->where('status', 'hired'),
            ])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $jobListing,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title'               => 'required|string|max:255',
            'type'                => 'required|string|max:50',
            'location'            => 'required|string|max:255',
            'salary'              => 'nullable|string|max:100',
            'salary_range'        => 'nullable|string|max:100',
            'education_level'     => 'nullable|string|max:80',
            'experience_required' => 'nullable|string|max:80',
            'description'         => 'required|string',
            'slots'               => 'required|integer|min:1',
            'status'              => 'sometimes|string|max:20',
            'posted_date'         => 'nullable|date',
            'deadline'            => 'nullable|date',
            'daysLeft'            => 'nullable|integer|min:0',
            'skills'              => 'nullable|array',
            'skills.*'            => 'string|max:100',
            // DOLE specific fields
            'program'             => 'nullable|string|max:50',
            'program_budget'      => 'nullable|string|max:150',
            'program_duration'    => 'nullable|string|max:150',
            'program_target'      => 'nullable|string|max:150',
            'implementing_agency' => 'nullable|string|max:150',
            'employer_name'       => 'nullable|string|max:255',
            'employer'            => 'nullable|string|max:255', // alias
        ]);

        if (!isset($validated['salary_range']) && isset($validated['salary'])) {
            $validated['salary_range'] = $validated['salary'];
        }
        unset($validated['salary']);

        if (!isset($validated['deadline']) && isset($validated['daysLeft']) && $validated['daysLeft'] > 0) {
            $validated['deadline'] = now()->addDays((int) $validated['daysLeft'])->toDateString();
        }
        unset($validated['daysLeft']);

        if (!isset($validated['employer_name']) && isset($validated['employer'])) {
            $validated['employer_name'] = $validated['employer'];
        }
        unset($validated['employer']);

        $validated['type']   = $this->normalise($validated['type']);
        $validated['status'] = isset($validated['status']) ? $this->normalise($validated['status']) : 'open';

        if ($validated['status'] === 'open' && empty($validated['posted_date'])) {
            $validated['posted_date'] = now();
        }

        \Illuminate\Support\Facades\DB::beginTransaction();
        try {
            $jobListing = JobListing::create($validated);

            if (!empty($validated['skills'])) {
                foreach ($this->resolveSkillNames($validated['skills']) as $skill) {
                    \App\Models\JobSkill::create([
                        'job_listing_id' => $jobListing->id,
                        'skill'          => $skill,
                    ]);
                }
            }

            \Illuminate\Support\Facades\DB::commit();

            $jobListing->refresh();
            $jobListing->load(['skills', 'employer']);
            $jobListing->loadCount([
                'applications',
                'applications as hired_count' => fn ($q) => $q->where('status', 'hired'),
            ]);

            return response()->json([
                'success' => true,
                'data'    => $jobListing,
                'message' => 'Job listing created successfully',
            ], 201);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollback();
            throw $e;
        }
    }

    public function update(Request $request, $id)
    {
        $jobListing = JobListing::findOrFail($id);

        $validated = $request->validate([
            'title'               => 'sometimes|string|max:255',
            'type'                => 'sometimes|string|max:50',
            'location'            => 'sometimes|string|max:255',
            'salary'              => 'nullable|string|max:100',
            'salary_range'        => 'nullable|string|max:100',
            'education_level'     => 'nullable|string|max:80',
            'experience_required' => 'nullable|string|max:80',
            'description'         => 'sometimes|string',
            'slots'               => 'sometimes|integer|min:1',
            'status'              => 'sometimes|string|max:20',
            'posted_date'         => 'nullable|date',
            'deadline'            => 'nullable|date',
            'daysLeft'            => 'nullable|integer|min:0',
            'skills'              => 'nullable|array',
            'skills.*'            => 'string|max:100',
            'program'             => 'nullable|string|max:50',
            'program_budget'      => 'nullable|string|max:150',
            'program_duration'    => 'nullable|string|max:150',
            'program_target'      => 'nullable|string|max:150',
            'implementing_agency' => 'nullable|string|max:150',
            'employer_name'       => 'nullable|string|max:255',
            'employer'            => 'nullable|string|max:255',
        ]);

        if (!isset($validated['salary_range']) && isset($validated['salary'])) {
            $validated['salary_range'] = $validated['salary'];
        }
        unset($validated['salary']);

        if (!isset($validated['deadline']) && isset($validated['daysLeft']) && $validated['daysLeft'] > 0) {
            $validated['deadline'] = now()->addDays((int) $validated['daysLeft'])->toDateString();
        }
        unset($validated['daysLeft']);

        if (array_key_exists('employer', $validated)) {
            $validated['employer_name'] = $validated['employer'];
        }
        unset($validated['employer']);

        if (isset($validated['type']))   $validated['type']   = $this->normalise($validated['type']);
        if (isset($validated['status'])) $validated['status'] = $this->normalise($validated['status']);

        \Illuminate\Support\Facades\DB::beginTransaction();
        try {
            $jobListing->update($validated);

            if (isset($validated['skills'])) {
                $jobListing->skills()->delete();
                foreach ($this->resolveSkillNames($validated['skills']) as $skill) {
                    \App\Models\JobSkill::create([
                        'job_listing_id' => $jobListing->id,
                        'skill'          => $skill,
                    ]);
                }
            }

            \Illuminate\Support\Facades\DB::commit();

            $jobListing->refresh();
            $jobListing->load(['skills', 'employer']);
            $jobListing->loadCount([
                'applications',
                'applications as hired_count' => fn ($q) => $q->where('status', 'hired'),
            ]);

            if ($jobListing->slots > 0 && $jobListing->hired_count >= $jobListing->slots && strtolower($jobListing->status) !== 'closed') {
                $jobListing->update(['status' => 'closed']);
                $jobListing->status = 'Closed';
            }

            return response()->json([
                'success' => true,
                'data'    => $jobListing,
                'message' => 'Job listing updated successfully',
            ]);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollback();
            throw $e;
        }
    }

    public function close(Request $request, $id)
    {
        $jobListing = JobListing::findOrFail($id);
        
        $jobListing->update(['status' => 'closed']);

        return response()->json([
            'success' => true,
            'message' => 'Job listing closed successfully',
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
