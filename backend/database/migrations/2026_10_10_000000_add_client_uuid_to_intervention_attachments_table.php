<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('intervention_attachments', function (Blueprint $table): void {
            $table->uuid('client_uuid')->nullable()->after('intervention_id');
            $table->unique(['intervention_id', 'client_uuid']);
        });
    }

    public function down(): void
    {
        Schema::table('intervention_attachments', function (Blueprint $table): void {
            $table->dropUnique(['intervention_id', 'client_uuid']);
            $table->dropColumn('client_uuid');
        });
    }
};
