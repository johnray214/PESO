<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    use \Illuminate\Database\Eloquent\SoftDeletes;

    protected $fillable = [
        'title', 'description', 'location', 'event_date', 'event_time',
        'event_type', 'organizer', 'image_url', 'is_active',
        'slots', 'registered', 'status',
    ];

    protected $casts = [
        'event_date' => 'date',
        'is_active'  => 'boolean',
        'slots'      => 'integer',
        'registered' => 'integer',
    ];
}
