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
        Schema::create('interventions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('client_uuid')->nullable();
            $table->foreignId('technician_id')->constrained('users')->cascadeOnDelete();
            $table->string('client');
            $table->string('address');
            $table->text('description');
            $table->string('equipment');
            $table->string('status')->default('pending');
            $table->unsignedTinyInteger('priority')->default(1);
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->dateTime('scheduled_at')->nullable();
            $table->text('notes')->nullable();
            $table->unsignedInteger('sync_version')->default(1);
            $table->timestamps();

            $table->unique(['technician_id', 'client_uuid']);
            $table->index(['technician_id', 'status', 'priority']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('interventions');
    }
};
