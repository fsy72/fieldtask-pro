<?php

namespace App\Models;

use Database\Factories\InterventionFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Intervention extends Model
{
    /** @use HasFactory<InterventionFactory> */
    use HasFactory, HasUuids;

    protected $fillable = [
        'client_uuid',
        'technician_id',
        'client',
        'address',
        'description',
        'equipment',
        'status',
        'priority',
        'latitude',
        'longitude',
        'scheduled_at',
        'notes',
        'sync_version',
    ];

    protected function casts(): array
    {
        return [
            'priority' => 'integer',
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'scheduled_at' => 'datetime',
        ];
    }

    public function technician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'technician_id');
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(InterventionAttachment::class);
    }
}
