<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ApplicantDocument extends Model
{
    protected $fillable = [
        'user_id', 'resume_url', 'resume_name',
        'cert_url', 'cert_name', 'clearance_url', 'clearance_name',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
