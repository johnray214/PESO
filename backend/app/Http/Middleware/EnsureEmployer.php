<?php

namespace App\Http\Middleware;

use App\Models\Employer;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureEmployer
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || !($user instanceof Employer)) {
            return response()->json(['message' => 'Unauthorized. Employer access required.'], 403);
        }

        if ($user->status === 'inactive') {
            return response()->json(['message' => 'Your employer account has been deactivated.'], 403);
        }

        return $next($request);
    }
}
