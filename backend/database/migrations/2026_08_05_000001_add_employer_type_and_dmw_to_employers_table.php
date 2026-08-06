<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('employers', function (Blueprint $table) {
            if (!Schema::hasColumn('employers', 'employer_type')) {
                $table->enum('employer_type', ['local', 'overseas'])->default('local')->after('company_size');
            }
            if (!Schema::hasColumn('employers', 'dmw_license_path')) {
                $table->string('dmw_license_path', 255)->nullable()->after('bir_cert_path');
            }
        });
    }

    public function down(): void
    {
        Schema::table('employers', function (Blueprint $table) {
            if (Schema::hasColumn('employers', 'employer_type')) {
                $table->dropColumn('employer_type');
            }
            if (Schema::hasColumn('employers', 'dmw_license_path')) {
                $table->dropColumn('dmw_license_path');
            }
        });
    }
};
