<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('job_listings', function (Blueprint $table) {
            $table->unsignedInteger('slots')->default(1)->after('category');
            $table->unsignedInteger('hired_count')->default(0)->after('slots');
            $table->enum('status', ['open', 'draft', 'closed'])->default('open')->after('hired_count');
            $table->date('closes_at')->nullable()->after('status');
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::table('job_listings', function (Blueprint $table) {
            $table->dropColumn(['slots', 'hired_count', 'status', 'closes_at', 'deleted_at']);
        });
    }
};
