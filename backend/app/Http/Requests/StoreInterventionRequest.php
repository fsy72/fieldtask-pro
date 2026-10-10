<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreInterventionRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'client_uuid' => ['nullable', 'uuid'],
            'client' => ['required', 'string', 'max:255'],
            'address' => ['required', 'string', 'max:500'],
            'description' => ['required', 'string', 'max:5000'],
            'equipment' => ['required', 'string', 'max:255'],
            'status' => ['sometimes', 'in:pending,in_progress,completed'],
            'priority' => ['sometimes', 'integer', 'between:1,3'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'scheduled_at' => ['nullable', 'date'],
            'notes' => ['nullable', 'string', 'max:5000'],
        ];
    }
}
