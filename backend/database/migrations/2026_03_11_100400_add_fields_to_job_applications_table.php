<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('job_applications', function (Blueprint $table) {
            $table->enum('employer_status', ['reviewing', 'shortlisted', 'interview', 'hired', 'rejected'])
                  ->default('reviewing')->after('status');
            $table->text('employer_notes')->nullable()->after('employer_status');
            $table->unsignedTinyInteger('match_score')->default(0)->after('employer_notes');
        });
    }

    public function down(): void
    {
        Schema::table('job_applications', function (Blueprint $table) {
            $table->dropColumn(['employer_status', 'employer_notes', 'match_score']);
        });
    }
};
