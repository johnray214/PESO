<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('employers', function (Blueprint $table) {
            $table->string('first_name')->nullable()->after('contact_person');
            $table->string('last_name')->nullable()->after('first_name');
            $table->string('contact_role')->nullable()->after('last_name');
            $table->string('legal_name')->nullable()->after('contact_role');
            $table->string('tagline')->nullable()->after('legal_name');
            $table->text('about')->nullable()->after('tagline');
            $table->string('company_size')->nullable()->after('about');
            $table->string('founded')->nullable()->after('company_size');
            $table->string('business_type')->nullable()->after('founded');
            $table->string('tin')->nullable()->after('business_type');
            $table->string('city')->nullable()->after('tin');
            $table->string('address')->nullable()->after('city');
            $table->string('website')->nullable()->after('address');
            $table->json('perks')->nullable()->after('website');
            $table->enum('verification_status', ['pending', 'verified', 'rejected'])->default('pending')->after('perks');
            $table->string('biz_permit_url')->nullable()->after('verification_status');
            $table->string('bir_cert_url')->nullable()->after('biz_permit_url');
            $table->text('remarks')->nullable()->after('bir_cert_url');
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::table('employers', function (Blueprint $table) {
            $table->dropColumn([
                'first_name', 'last_name', 'contact_role', 'legal_name', 'tagline',
                'about', 'company_size', 'founded', 'business_type', 'tin', 'city',
                'address', 'website', 'perks', 'verification_status',
                'biz_permit_url', 'bir_cert_url', 'remarks', 'deleted_at',
            ]);
        });
    }
};
