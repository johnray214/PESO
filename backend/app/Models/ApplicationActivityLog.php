<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ApplicationActivityLog extends Model
{
    protected $fillable = [
        'application_id',
        'actor_type',
        'actor_label',
        'action',
    ];

    public function application()
    {
        return $this->belongsTo(Application::class);
    }
}
