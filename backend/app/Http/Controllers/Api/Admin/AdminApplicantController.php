<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ApplicantDocument;
use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AdminApplicantController extends Controller
{
    public function index(Request $request)
    {
        $query = User::with(['documents', 'applications.jobListing.employer']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('peso_status', $request->status);
        }

        if ($request->filled('skill')) {
            $query->whereJsonContains('skills', $request->skill);
        }

        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $applicants = $query->latest()->paginate($request->get('per_page', 15));

        $applicants->getCollection()->transform(function ($u) {
            $latestApp = $u->applications->first();
            return [
                'id'        => $u->id,
                'name'      => $u->name,
                'email'     => $u->email,
                'location'  => $u->address ?? 'N/A',
                'contact'   => $u->phone ?? 'N/A',
                'education' => $u->education,
                'experience'=> $u->experience,
                'skills'    => $u->skills ?? [],
                'jobApplied'=> optional($latestApp?->jobListing)->title ?? 'N/A',
                'employer'  => optional($latestApp?->jobListing?->employer)->company_name ?? 'N/A',
                'date'      => $u->created_at->format('M d, Y'),
                'status'    => $u->peso_status ?? 'processing',
                'notes'     => $u->notes,
                'files'     => $u->documents ? [
                    'resume'    => $u->documents->resume_url,
                    'resumeName'=> $u->documents->resume_name,
                    'cert'      => $u->documents->cert_url,
                    'certName'  => $u->documents->cert_name,
                    'clearance' => $u->documents->clearance_url,
                    'clearanceName' => $u->documents->clearance_name,
                ] : [],
            ];
        });

        return response()->json(['success' => true, 'data' => $applicants]);
    }

    public function show($id)
    {
        $u = User::with(['documents', 'applications.jobListing.employer'])->findOrFail($id);

        $latestApp = $u->applications->first();
        return response()->json([
            'success' => true,
            'data'    => [
                'id'         => $u->id,
                'name'       => $u->name,
                'email'      => $u->email,
                'location'   => $u->address ?? 'N/A',
                'contact'    => $u->phone ?? 'N/A',
                'education'  => $u->education,
                'experience' => $u->experience,
                'skills'     => $u->skills ?? [],
                'jobApplied' => optional($latestApp?->jobListing)->title ?? 'N/A',
                'employer'   => optional($latestApp?->jobListing?->employer)->company_name ?? 'N/A',
                'date'       => $u->created_at->format('M d, Y'),
                'status'     => $u->peso_status ?? 'processing',
                'notes'      => $u->notes,
                'files'      => $u->documents ? [
                    'resume'    => $u->documents->resume_url,
                    'resumeName'=> $u->documents->resume_name,
                    'cert'      => $u->documents->cert_url,
                    'certName'  => $u->documents->cert_name,
                    'clearance' => $u->documents->clearance_url,
                    'clearanceName' => $u->documents->clearance_name,
                ] : [],
            ],
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:processing,placed,hired,rejected',
            'notes'  => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = User::findOrFail($id);
        $user->update([
            'peso_status' => $request->status,
            'notes'       => $request->notes ?? $user->notes,
        ]);

        AuditLog::record(
            'Status Changed', 'Applicants',
            "Applicant {$user->name} status changed to {$request->status}",
            $request, $request->user()
        );

        return response()->json(['success' => true, 'message' => 'Status updated', 'data' => $user]);
    }

    public function uploadFile(Request $request, $id, string $type)
    {
        if (!in_array($type, ['resume', 'cert', 'clearance'])) {
            return response()->json(['message' => 'Invalid file type'], 422);
        }

        $validator = Validator::make($request->all(), [
            'file' => 'required|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = User::findOrFail($id);
        $doc  = ApplicantDocument::firstOrCreate(['user_id' => $id]);

        $file = $request->file('file');
        $path = $file->store("applicant_docs/{$id}", 'public');

        $doc->update([
            "{$type}_url"  => Storage::url($path),
            "{$type}_name" => $file->getClientOriginalName(),
        ]);

        return response()->json(['success' => true, 'message' => 'File uploaded', 'url' => Storage::url($path)]);
    }

    public function archive(Request $request, $id)
    {
        $user = User::findOrFail($id);

        AuditLog::record(
            'Deleted', 'Applicants',
            "Applicant {$user->name} archived",
            $request, $request->user()
        );

        $user->delete();

        return response()->json(['success' => true, 'message' => 'Applicant archived']);
    }
}
