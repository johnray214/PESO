<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('applications', function (Blueprint $table) {
            $table->date('interview_date')->nullable()->after('status');
            $table->time('interview_time')->nullable()->after('interview_date');
            $table->string('interview_format')->nullable()->after('interview_time');
            $table->string('interview_location')->nullable()->after('interview_format');
            $table->string('interviewer_name')->nullable()->after('interview_location');
        });
    }

    public function down(): void
    {
        Schema::table('applications', function (Blueprint $table) {
            $table->dropColumn([
                'interview_date',
                'interview_time',
                'interview_format',
                'interview_location',
                'interviewer_name',
            ]);
        });
    }
};
