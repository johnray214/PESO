<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Employer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AdminEmployerVerificationController extends Controller
{
    public function index(Request $request)
    {
        $query = Employer::withCount('jobListings');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('company_name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('contact_person', 'like', "%{$search}%");
            });
        }

        if ($request->filled('verification_status') && $request->verification_status !== 'all') {
            $query->where('verification_status', $request->verification_status);
        }

        $employers = $query->latest()->paginate($request->get('per_page', 15));
        $employers->getCollection()->transform(fn($e) => $this->formatEmployer($e));

        return response()->json(['success' => true, 'data' => $employers]);
    }

    public function show($id)
    {
        $employer = Employer::withCount('jobListings')->findOrFail($id);
        return response()->json(['success' => true, 'data' => $this->formatEmployer($employer)]);
    }

    public function verify(Request $request, $id)
    {
        $employer = Employer::findOrFail($id);

        $employer->update([
            'verification_status' => 'verified',
            'status'              => 'active',
            'email_verified_at'   => now(),
            'remarks'             => $request->remarks ?? $employer->remarks,
        ]);

        AuditLog::record('Status Changed', 'Employers', "Employer {$employer->company_name} verified", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Employer verified', 'data' => $this->formatEmployer($employer)]);
    }

    public function reject(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'remarks' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employer = Employer::findOrFail($id);

        $employer->update([
            'verification_status' => 'rejected',
            'status'              => 'inactive',
            'remarks'             => $request->remarks,
        ]);

        AuditLog::record('Status Changed', 'Employers', "Employer {$employer->company_name} rejected. Reason: {$request->remarks}", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Employer rejected', 'data' => $this->formatEmployer($employer)]);
    }

    public function revoke(Request $request, $id)
    {
        $employer = Employer::findOrFail($id);

        $employer->update([
            'verification_status' => 'pending',
            'status'              => 'pending',
            'remarks'             => $request->remarks ?? $employer->remarks,
        ]);

        AuditLog::record('Status Changed', 'Employers', "Employer {$employer->company_name} verification revoked", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Employer verification revoked']);
    }

    private function formatEmployer(Employer $e): array
    {
        return [
            'id'                 => $e->id,
            'companyName'        => $e->company_name,
            'legalName'          => $e->legal_name,
            'industry'           => $e->industry,
            'companySize'        => $e->company_size,
            'city'               => $e->city,
            'tin'                => $e->tin,
            'website'            => $e->website,
            'firstName'          => $e->first_name,
            'lastName'           => $e->last_name,
            'email'              => $e->email,
            'phone'              => $e->contact,
            'contactPerson'      => $e->contact_person,
            'registeredDate'     => $e->created_at->format('M d, Y'),
            'status'             => $e->status,
            'verificationStatus' => $e->verification_status ?? 'pending',
            'hasBizPermit'       => !empty($e->biz_permit_url),
            'bizPermitUrl'       => $e->biz_permit_url,
            'hasBirCert'         => !empty($e->bir_cert_url),
            'birCertUrl'         => $e->bir_cert_url,
            'remarks'            => $e->remarks,
            'jobListingsCount'   => $e->job_listings_count ?? 0,
            'totalHired'         => $e->total_hired,
            'emailVerified'      => !is_null($e->email_verified_at),
        ];
    }
}
