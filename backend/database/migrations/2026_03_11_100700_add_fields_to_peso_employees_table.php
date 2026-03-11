<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('peso_employees', function (Blueprint $table) {
            $table->string('contact')->nullable()->after('sex');
            $table->text('address')->nullable()->after('contact');
            $table->enum('status', ['active', 'inactive'])->default('active')->after('address');
        });
    }

    public function down(): void
    {
        Schema::table('peso_employees', function (Blueprint $table) {
            $table->dropColumn(['contact', 'address', 'status']);
        });
    }
};
