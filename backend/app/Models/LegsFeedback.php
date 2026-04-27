<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LegsFeedback extends Model
{
    protected $table = 'legs_feedbacks';   // explicit: pluralizer treats "feedback" as uncountable

    protected $fillable = [
        'first_name',
        'last_name',
        'middle_initial',
        'program',
        'venue',
        'activity_date',
        'rating_program_content',
        'rating_interaction',
        'rating_mastery',
        'rating_overall',
        'remarks',
    ];

    protected $casts = [
        'activity_date'          => 'date',
        'rating_program_content' => 'integer',
        'rating_interaction'     => 'integer',
        'rating_mastery'         => 'integer',
        'rating_overall'         => 'integer',
    ];

    /** Full name helper */
    public function getFullNameAttribute(): string
    {
        $mi = $this->middle_initial ? " {$this->middle_initial}" : '';
        return "{$this->first_name}{$mi} {$this->last_name}";
    }
}
