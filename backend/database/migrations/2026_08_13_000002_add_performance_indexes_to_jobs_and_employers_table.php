<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('job_listings', function (Blueprint $table) {
            $table->index(['status', 'created_at'], 'idx_jobs_status_created');
            $table->index(['employer_id', 'status'], 'idx_jobs_employer_status');
            $table->index('is_overseas', 'idx_jobs_overseas');
        });

        Schema::table('employers', function (Blueprint $table) {
            $table->index(['status', 'created_at'], 'idx_emp_status_created');
            $table->index('employer_type', 'idx_emp_type');
        });
    }

    public function down(): void
    {
        Schema::table('job_listings', function (Blueprint $table) {
            $table->dropIndex('idx_jobs_status_created');
            $table->dropIndex('idx_jobs_employer_status');
            $table->dropIndex('idx_jobs_overseas');
        });

        Schema::table('employers', function (Blueprint $table) {
            $table->dropIndex('idx_emp_status_created');
            $table->dropIndex('idx_emp_type');
        });
    }
};
