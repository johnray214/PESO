<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('applications', function (Blueprint $table) {
            $table->enum('offer_response', ['accepted', 'declined'])->nullable()->after('status');
            $table->timestamp('offer_sent_at')->nullable()->after('offer_response');
            $table->timestamp('offer_response_at')->nullable()->after('offer_sent_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('applications', function (Blueprint $table) {
            $table->dropColumn(['offer_response', 'offer_sent_at', 'offer_response_at']);
        });
    }
};
