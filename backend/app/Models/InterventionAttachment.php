<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InterventionAttachment extends Model
{
    use HasUuids;

    protected $fillable = [
        'type',
        'path',
        'caption',
        'mime_type',
        'size_bytes',
    ];

    protected function casts(): array
    {
        return ['size_bytes' => 'integer'];
    }

    public function intervention(): BelongsTo
    {
        return $this->belongsTo(Intervention::class);
    }
}
