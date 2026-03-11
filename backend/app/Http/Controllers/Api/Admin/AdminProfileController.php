<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\PesoEmployee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AdminProfileController extends Controller
{
    public function show(Request $request)
    {
        $employee = $request->user();

        return response()->json([
            'success' => true,
            'data'    => [
                'id'          => $employee->id,
                'firstName'   => $employee->first_name,
                'middleName'  => $employee->middle_name,
                'lastName'    => $employee->last_name,
                'email'       => $employee->email,
                'role'        => $employee->role,
                'sex'         => $employee->sex,
                'contact'     => $employee->contact,
                'address'     => $employee->address,
                'status'      => $employee->status ?? 'active',
            ],
        ]);
    }

    public function update(Request $request)
    {
        $employee = $request->user();

        $validator = Validator::make($request->all(), [
            'first_name'  => 'sometimes|required|string|max:100',
            'middle_name' => 'nullable|string|max:100',
            'last_name'   => 'sometimes|required|string|max:100',
            'email'       => 'sometimes|required|email|unique:peso_employees,email,' . $employee->id,
            'sex'         => 'nullable|in:Male,Female,Other',
            'contact'     => 'nullable|string|max:20',
            'address'     => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employee->update($request->only(['first_name', 'middle_name', 'last_name', 'email', 'sex', 'contact', 'address']));

        return response()->json(['success' => true, 'message' => 'Profile updated', 'data' => [
            'id'        => $employee->id,
            'firstName' => $employee->first_name,
            'lastName'  => $employee->last_name,
            'email'     => $employee->email,
        ]]);
    }

    public function changePassword(Request $request)
    {
        $employee = $request->user();

        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'password'         => 'required|string|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        if (!Hash::check($request->current_password, $employee->password)) {
            return response()->json(['message' => 'Current password is incorrect'], 422);
        }

        $employee->update(['password' => Hash::make($request->password)]);

        return response()->json(['success' => true, 'message' => 'Password changed successfully']);
    }
}
