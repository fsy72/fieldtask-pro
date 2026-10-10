<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class InterventionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $technician = User::query()->where('email', 'fieldtask.pro@example.com')->firstOrFail();

        $technician->interventions()->updateOrCreate(
            ['client_uuid' => '10000000-0000-4000-8000-000000000001'],
            [
                'client' => 'Usine de Diamniadio',
                'address' => 'Zone industrielle, Diamniadio',
                'description' => 'Inspection préventive du groupe électrogène.',
                'equipment' => 'Groupe électrogène GE-204',
                'status' => 'pending',
                'priority' => 3,
            ],
        );

        $technician->interventions()->updateOrCreate(
            ['client_uuid' => '10000000-0000-4000-8000-000000000002'],
            [
                'client' => 'Antenne télécom de Rufisque',
                'address' => 'Route de Sangalkam, Rufisque',
                'description' => 'Vérifier les alarmes du local technique.',
                'equipment' => 'Baie radio BTS-17',
                'status' => 'in_progress',
                'priority' => 2,
            ],
        );
    }
}
