<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Update status ENUM to include 'withdrawn'
        DB::statement("ALTER TABLE applications MODIFY COLUMN status ENUM('reviewing','shortlisted','interview','for_job_offer','hired','rejected','withdrawn') NOT NULL DEFAULT 'reviewing'");

        // 2. Add withdrawal details columns
        Schema::table('applications', function (Blueprint $table) {
            if (!Schema::hasColumn('applications', 'withdrawal_reason')) {
                $table->string('withdrawal_reason')->nullable()->after('status');
            }
            if (!Schema::hasColumn('applications', 'withdrawal_notes')) {
                $table->text('withdrawal_notes')->nullable()->after('withdrawal_reason');
            }
            if (!Schema::hasColumn('applications', 'withdrawn_at')) {
                $table->timestamp('withdrawn_at')->nullable()->after('withdrawal_notes');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('applications', function (Blueprint $table) {
            if (Schema::hasColumn('applications', 'withdrawn_at')) {
                $table->dropColumn('withdrawn_at');
            }
            if (Schema::hasColumn('applications', 'withdrawal_notes')) {
                $table->dropColumn('withdrawal_notes');
            }
            if (Schema::hasColumn('applications', 'withdrawal_reason')) {
                $table->dropColumn('withdrawal_reason');
            }
        });

        DB::statement("ALTER TABLE applications MODIFY COLUMN status ENUM('reviewing','shortlisted','interview','for_job_offer','hired','rejected') NOT NULL DEFAULT 'reviewing'");
    }
};
