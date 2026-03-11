<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class JobApplication extends Model
{
    protected $fillable = [
        'user_id', 'job_listing_id', 'status', 'applied_at',
        'employer_status', 'employer_notes', 'match_score',
    ];

    protected $casts = [
        'applied_at'  => 'datetime',
        'match_score' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function jobListing()
    {
        return $this->belongsTo(JobListing::class);
    }
}

