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
        Schema::create('intervention_attachments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('intervention_id')->constrained()->cascadeOnDelete();
            $table->string('type');
            $table->string('path');
            $table->string('caption')->nullable();
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('size_bytes');
            $table->timestamps();

            $table->index(['intervention_id', 'type']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('intervention_attachments');
    }
};
