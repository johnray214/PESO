t<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Adds 'for_job_offer' between 'interview' and 'hired' in the applications status ENUM.
     */
    public function up(): void
    {
        DB::statement("ALTER TABLE applications MODIFY COLUMN status ENUM('reviewing','shortlisted','interview','for_job_offer','hired','rejected') NOT NULL DEFAULT 'reviewing'");
    }

    /**
     * Reverse the migrations.
     * Removes 'for_job_offer' from the applications status ENUM.
     */
    public function down(): void
    {
        DB::statement("ALTER TABLE applications MODIFY COLUMN status ENUM('reviewing','shortlisted','interview','hired','rejected') NOT NULL DEFAULT 'reviewing'");
    }
};
