<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admin_notification_states', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('notification_id', 100);
            $table->boolean('read')->default(false);
            $table->boolean('deleted')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'notification_id']);
            $table->index(['user_id', 'deleted']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_notification_states');
    }
};
