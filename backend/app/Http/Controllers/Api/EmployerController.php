<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class EmployerController extends Controller
{
    public function index(Request $request)
    {
        $query = Employer::query();

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('company_name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('industry', 'like', "%{$search}%")
                  ->orWhere('contact_person', 'like', "%{$search}%");
            });
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('industry')) {
            $query->where('industry', $request->industry);
        }

        $employers = $query->withCount('jobListings')->latest()->paginate(15);

        return response()->json($employers);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'company_name' => 'required|string|max:255',
            'email' => 'required|email|unique:employers,email',
            'password' => 'required|string|min:6',
            'industry' => 'nullable|string|max:255',
            'contact' => 'nullable|string|max:255',
            'contact_person' => 'nullable|string|max:255',
            'status' => 'in:active,inactive,pending',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employer = Employer::create([
            'company_name' => $request->company_name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'industry' => $request->industry,
            'contact' => $request->contact,
            'contact_person' => $request->contact_person,
            'status' => $request->status ?? 'pending',
        ]);

        return response()->json(['message' => 'Employer created successfully', 'data' => $employer], 201);
    }

    public function show($id)
    {
        $employer = Employer::withCount('jobListings')->findOrFail($id);
        return response()->json($employer);
    }

    public function update(Request $request, $id)
    {
        $employer = Employer::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'company_name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|email|unique:employers,email,' . $id,
            'password' => 'sometimes|nullable|string|min:6',
            'industry' => 'nullable|string|max:255',
            'contact' => 'nullable|string|max:255',
            'contact_person' => 'nullable|string|max:255',
            'status' => 'in:active,inactive,pending',
            'total_hired' => 'sometimes|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->only(['company_name', 'email', 'industry', 'contact', 'contact_person', 'status', 'total_hired']);

        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $employer->update($data);

        return response()->json(['message' => 'Employer updated successfully', 'data' => $employer]);
    }

    public function destroy($id)
    {
        $employer = Employer::findOrFail($id);
        $employer->delete();

        return response()->json(['message' => 'Employer deleted successfully']);
    }

    public function verifyEmail($id)
    {
        $employer = Employer::findOrFail($id);
        $employer->email_verified_at = now();
        $employer->save();

        return response()->json(['message' => 'Email verified successfully', 'data' => $employer]);
    }
}
