<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\EmployerResource;
use App\Models\Employer;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminEmployerController extends Controller
{
    public function index(Request $request)
    {
        $query = Employer::query();

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('company_name', 'like', "%{$search}%")
                  ->orWhere('contact_person', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('industry') && $request->industry !== '') {
            $query->where('industry', $request->industry);
        }

        // Eager load job listings with counts and hired applicants
        $query->with([
            'jobListings.skills',
            'jobListings' => function ($q) {
                $q->withCount('applications');
            },
            'jobListings.applications' => function ($q) {
                $q->where('status', 'hired')->with(['jobseeker' => function ($q) {
                    $q->withTrashed()->select('id', 'first_name', 'last_name');
                }]);
            }
        ]);

        $employers = $query->orderByDesc('created_at')->paginate(15);

        // Attach derived counts before passing to resource
        $employers->getCollection()->transform(function ($emp) {
            $hiredApplicants = [];
            $totalHired = 0;

            foreach ($emp->jobListings as $listing) {
                foreach ($listing->applications as $app) {
                    if ($app->status === 'hired') {
                        $totalHired++;
                        $name = $app->jobseeker
                            ? trim($app->jobseeker->first_name . ' ' . $app->jobseeker->last_name)
                            : 'Unknown';
                        $hiredApplicants[] = [
                            'name' => $name,
                            'job'  => $listing->title,
                            'date' => $app->updated_at ? $app->updated_at->format('M d, Y') : 'Recently',
                        ];
                    }
                }
            }

            $emp->total_hired      = $totalHired;
            $emp->hired_applicants = $hiredApplicants;
            return $emp;
        });

        return response()->json([
            'success' => true,
            // EmployerResource builds biz_permit_url / bir_cert_url via Storage::url()
            'data' => EmployerResource::collection($employers),
        ]);
    }

    public function show($id)
    {
        $employer = Employer::with('jobListings')->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => new EmployerResource($employer),
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $validated = $request->validate([
            'status'  => ['required', Rule::in(['verified', 'rejected', 'suspended'])],
            'remarks' => ['nullable', 'string', 'max:1000'],
        ]);

        $employer = Employer::findOrFail($id);
        $wasNotVerified  = $employer->status !== 'verified';
        $wasNotRejected  = $employer->status !== 'rejected';
        $wasNotSuspended = $employer->status !== 'suspended';

        if ($validated['status'] === 'verified' && $wasNotVerified) {
            $validated['verified_at'] = now();
        }

        $employer->update($validated);

        try {
            $mj = new \Mailjet\Client(
                env('MAILJET_API_KEY'),
                env('MAILJET_SECRET_KEY'),
                true,
                ['version' => 'v3.1']
            );

            // ── Verified email
            if ($validated['status'] === 'verified' && $wasNotVerified) {
                $mj->post(\Mailjet\Resources::$Email, ['body' => [
                    'Messages' => [[
                        'From'             => ['Email' => env('MAILJET_FROM_EMAIL'), 'Name' => env('MAILJET_FROM_NAME', 'PESO Santiago')],
                        'To'               => [['Email' => $employer->email, 'Name' => trim($employer->contact_person ?: $employer->company_name)]],
                        'TemplateID'       => 7861214,
                        'TemplateLanguage' => true,
                        'Subject'          => 'PESO Santiago: Your Employer Account Has Been Verified',
                        'Variables'        => ['company_name' => $employer->company_name],
                    ]]
                ]]);
            }

            // ── Rejected email
            if ($validated['status'] === 'rejected' && $wasNotRejected) {
                $mj->post(\Mailjet\Resources::$Email, ['body' => [
                    'Messages' => [[
                        'From'             => ['Email' => env('MAILJET_FROM_EMAIL'), 'Name' => env('MAILJET_FROM_NAME', 'PESO Santiago')],
                        'To'               => [['Email' => $employer->email, 'Name' => trim($employer->contact_person ?: $employer->company_name)]],
                        'TemplateID'       => 7919656,
                        'TemplateLanguage' => true,
                        'Subject'          => 'PESO Santiago: Update on Your Employer Account Application',
                        'Variables'        => [
                            'company_name'     => $employer->company_name,
                            'rejection_reason' => $validated['remarks'] ?? 'No specific reason provided. Please contact our office for details.',
                        ],
                    ]]
                ]]);
            }

            // ── Suspended email
            if ($validated['status'] === 'suspended' && $wasNotSuspended) {
                $mj->post(\Mailjet\Resources::$Email, ['body' => [
                    'Messages' => [[
                        'From'             => ['Email' => env('MAILJET_FROM_EMAIL'), 'Name' => env('MAILJET_FROM_NAME', 'PESO Santiago')],
                        'To'               => [['Email' => $employer->email, 'Name' => trim($employer->contact_person ?: $employer->company_name)]],
                        'TemplateID'       => 7919694, 
                        'TemplateLanguage' => true,
                        'Subject'          => 'PESO Santiago: Your Employer Account Has Been Suspended',
                        'Variables'        => [
                            'company_name'      => $employer->company_name,
                            'suspension_reason' => $validated['remarks'] ?? 'No specific reason provided. Please contact our office for details.',
                        ],
                    ]]
                ]]);
            }

        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Mailjet Exception: ' . $e->getMessage());
        }

        return response()->json([
            'success' => true,
            'data'    => new EmployerResource($employer),
            'message' => 'Employer status updated successfully',
        ]);
    }

    public function update(Request $request, $id)
    {
        $employer = Employer::findOrFail($id);

        $validated = $request->validate([
            'latitude'  => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
        ]);

        $employer->update($validated);

        return response()->json([
            'success' => true,
            'data'    => new EmployerResource($employer),
            'message' => 'Employer updated successfully',
        ]);
    }

    public function destroy($id)
    {
        $employer = Employer::findOrFail($id);
        $employer->delete();

        return response()->json([
            'success' => true,
            'message' => 'Employer deleted successfully',
        ]);
    }

    public function counts()
    {
        $statuses = ['verified', 'pending', 'suspended', 'rejected'];
        $counts = ['all' => Employer::count()];
        foreach ($statuses as $s) {
            $counts[$s] = Employer::where('status', $s)->count();
        }
        return response()->json(['success' => true, 'data' => $counts]);
    }
}