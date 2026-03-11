<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\PesoEmployee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AdminUserController extends Controller
{
    public function index(Request $request)
    {
        $query = PesoEmployee::query();

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                  ->orWhere('last_name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $users = $query->latest()->paginate($request->get('per_page', 15));

        $users->getCollection()->transform(fn($e) => $this->formatEmployee($e));

        return response()->json(['success' => true, 'data' => $users]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'first_name'  => 'required|string|max:100',
            'middle_name' => 'nullable|string|max:100',
            'last_name'   => 'required|string|max:100',
            'email'       => 'required|email|unique:peso_employees,email',
            'password'    => 'required|string|min:6|confirmed',
            'role'        => 'required|in:admin,staff',
            'sex'         => 'nullable|in:Male,Female,Other',
            'contact'     => 'nullable|string|max:20',
            'address'     => 'nullable|string|max:500',
            'status'      => 'nullable|in:active,inactive',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employee = PesoEmployee::create([
            'first_name'  => $request->first_name,
            'middle_name' => $request->middle_name,
            'last_name'   => $request->last_name,
            'email'       => $request->email,
            'password'    => Hash::make($request->password),
            'role'        => $request->role,
            'sex'         => $request->sex,
            'contact'     => $request->contact,
            'address'     => $request->address,
            'status'      => $request->status ?? 'active',
        ]);

        AuditLog::record('Created', 'Users', "Staff user {$employee->full_name} created", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Staff user created', 'data' => $this->formatEmployee($employee)], 201);
    }

    public function show($id)
    {
        $employee = PesoEmployee::findOrFail($id);
        return response()->json(['success' => true, 'data' => $this->formatEmployee($employee)]);
    }

    public function update(Request $request, $id)
    {
        $employee = PesoEmployee::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'first_name'  => 'sometimes|required|string|max:100',
            'middle_name' => 'nullable|string|max:100',
            'last_name'   => 'sometimes|required|string|max:100',
            'email'       => 'sometimes|required|email|unique:peso_employees,email,' . $id,
            'password'    => 'nullable|string|min:6|confirmed',
            'role'        => 'sometimes|in:admin,staff',
            'sex'         => 'nullable|in:Male,Female,Other',
            'contact'     => 'nullable|string|max:20',
            'address'     => 'nullable|string|max:500',
            'status'      => 'nullable|in:active,inactive',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->only(['first_name', 'middle_name', 'last_name', 'email', 'role', 'sex', 'contact', 'address', 'status']);

        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $employee->update($data);

        AuditLog::record('Updated', 'Users', "Staff user {$employee->full_name} updated", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Staff user updated', 'data' => $this->formatEmployee($employee)]);
    }

    public function destroy(Request $request, $id)
    {
        $employee = PesoEmployee::findOrFail($id);

        if ($employee->id === $request->user()->id) {
            return response()->json(['message' => 'You cannot delete your own account'], 422);
        }

        AuditLog::record('Deleted', 'Users', "Staff user {$employee->full_name} deleted", $request, $request->user());

        $employee->delete();

        return response()->json(['success' => true, 'message' => 'Staff user deleted']);
    }

    private function formatEmployee(PesoEmployee $e): array
    {
        return [
            'id'          => $e->id,
            'firstName'   => $e->first_name,
            'middleName'  => $e->middle_name,
            'lastName'    => $e->last_name,
            'fullName'    => $e->full_name,
            'email'       => $e->email,
            'role'        => $e->role,
            'sex'         => $e->sex,
            'contact'     => $e->contact,
            'address'     => $e->address,
            'status'      => $e->status ?? 'active',
            'createdAt'   => $e->created_at->format('M d, Y'),
        ];
    }
}
