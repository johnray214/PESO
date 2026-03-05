<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    protected $fillable = [
        'title',
        'description',
        'location',
        'event_date',
        'event_time',
        'event_type',
        'organizer',
        'image_url',
        'is_active',
    ];

    protected $casts = [
        'event_date' => 'date',
        'is_active'  => 'boolean',
    ];
}
