<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdminNotificationState extends Model
{
    protected $fillable = [
        'user_id',
        'notification_id',
        'read',
        'deleted',
        'read_at',
    ];

    protected $casts = [
        'read' => 'boolean',
        'deleted' => 'boolean',
        'read_at' => 'datetime',
    ];
}
