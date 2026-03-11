<?php

namespace App\Http\Middleware;

use App\Models\PesoEmployee;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePesoEmployee
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (!$user || !($user instanceof PesoEmployee)) {
            return response()->json(['message' => 'Unauthorized. PESO employee access required.'], 403);
        }

        if (!empty($roles) && !in_array($user->role, $roles)) {
            return response()->json(['message' => 'Forbidden. Insufficient role privileges.'], 403);
        }

        return $next($request);
    }
}
