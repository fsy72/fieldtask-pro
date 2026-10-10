<?php

namespace Database\Factories;

use App\Models\Intervention;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Intervention>
 */
class InterventionFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'technician_id' => User::factory(),
            'client' => fake()->company(),
            'address' => fake()->address(),
            'description' => fake()->sentence(),
            'equipment' => fake()->words(2, true),
            'status' => fake()->randomElement(['pending', 'in_progress', 'completed']),
            'priority' => fake()->numberBetween(1, 3),
        ];
    }
}
