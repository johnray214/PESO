<?php

use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
| Private channel for each employer: "employer.{id}"
| The authenticated employer can only subscribe to their own channel.
*/

Broadcast::channel('employer.{id}', function ($employer, $id) {
    // $employer is resolved from the 'employer' guard (sanctum-based)
    return (int) $employer->id === (int) $id;
});
