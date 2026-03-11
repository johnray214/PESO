<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    protected $fillable = [
        'user_type', 'user_id', 'user_name', 'role',
        'action', 'module', 'detail', 'ip_address',
    ];

    public static function record(string $action, string $module, string $detail, $request = null, $user = null): void
    {
        $userName = null;
        $userType = null;
        $userId = null;
        $role = null;

        if ($user) {
            $userType = get_class($user);
            $userId = $user->id;
            if ($user instanceof PesoEmployee) {
                $userName = trim("{$user->first_name} {$user->last_name}");
                $role = ucfirst($user->role);
            } elseif ($user instanceof Employer) {
                $userName = $user->company_name;
                $role = 'Employer';
            } elseif ($user instanceof User) {
                $userName = $user->name;
                $role = 'Applicant';
            }
        }

        self::create([
            'user_type'  => $userType,
            'user_id'    => $userId,
            'user_name'  => $userName,
            'role'       => $role,
            'action'     => $action,
            'module'     => $module,
            'detail'     => $detail,
            'ip_address' => $request ? $request->ip() : null,
        ]);
    }
}
