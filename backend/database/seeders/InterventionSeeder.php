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
        $assignments = [
            'fieldtask.pro@gmail.com' => [
                [
                    'client_uuid' => '10000000-0000-4000-8000-000000000001',
                    'client' => 'Usine de Diamniadio',
                    'address' => 'Zone industrielle, Diamniadio',
                    'description' => 'Inspection préventive du groupe électrogène.',
                    'equipment' => 'Groupe électrogène GE-204',
                    'status' => 'pending',
                    'priority' => 3,
                    'latitude' => 14.72722,
                    'longitude' => -17.22396,
                    'scheduled_at' => now()->addHours(2),
                ],
                [
                    'client_uuid' => '10000000-0000-4000-8000-000000000002',
                    'client' => 'Antenne télécom de Rufisque',
                    'address' => 'Route de Sangalkam, Rufisque',
                    'description' => 'Vérifier les alarmes du local technique.',
                    'equipment' => 'Baie radio BTS-17',
                    'status' => 'in_progress',
                    'priority' => 2,
                    'latitude' => 14.72372,
                    'longitude' => -17.28187,
                    'scheduled_at' => now()->addDay()->setTime(9, 0),
                ],
                [
                    'client_uuid' => '10000000-0000-4000-8000-000000000003',
                    'client' => 'Station-service de Bargny',
                    'address' => 'Route nationale 1, Bargny',
                    'description' => 'Inspecter le système de pompage et contrôler les fuites.',
                    'equipment' => 'Pompe de transfert PT-09',
                    'status' => 'pending',
                    'priority' => 2,
                    'latitude' => 14.6939,
                    'longitude' => -17.2317,
                    'scheduled_at' => now()->addDays(2)->setTime(10, 0),
                ],
                [
                    'client_uuid' => '10000000-0000-4000-8000-000000000004',
                    'client' => 'Lycée technique de Rufisque',
                    'address' => 'Avenue des Écoles, Rufisque',
                    'description' => 'Remettre en service le tableau électrique du laboratoire.',
                    'equipment' => 'Tableau électrique TE-12',
                    'status' => 'pending',
                    'priority' => 1,
                    'latitude' => 14.7168,
                    'longitude' => -17.2735,
                    'scheduled_at' => now()->addDays(3)->setTime(11, 0),
                ],
                [
                    'client_uuid' => '10000000-0000-4000-8000-000000000005',
                    'client' => 'Entrepôt de Keur Massar',
                    'address' => 'Zone de recasement, Keur Massar',
                    'description' => 'Remplacer le point d’accès Wi-Fi de la salle de contrôle.',
                    'equipment' => 'Point d’accès Wi-Fi AP-22',
                    'status' => 'pending',
                    'priority' => 2,
                    'latitude' => 14.7854,
                    'longitude' => -17.3119,
                    'scheduled_at' => now()->addDays(4)->setTime(9, 30),
                ],
            ],
            'fallou.sy@gmail.com' => [
                [
                    'client_uuid' => '20000000-0000-4000-8000-000000000001',
                    'client' => 'Centre médical de Pikine',
                    'address' => 'Avenue 12, Pikine',
                    'description' => 'Diagnostiquer les coupures du système de climatisation.',
                    'equipment' => 'Climatiseur industriel AC-08',
                    'status' => 'pending',
                    'priority' => 3,
                    'latitude' => 14.7645,
                    'longitude' => -17.3907,
                    'scheduled_at' => now()->addHours(4),
                ],
                [
                    'client_uuid' => '20000000-0000-4000-8000-000000000002',
                    'client' => 'Entrepôt de Thiaroye',
                    'address' => 'Route de Mbao, Thiaroye',
                    'description' => 'Remplacer le capteur de température de la chambre froide.',
                    'equipment' => 'Capteur thermique TH-32',
                    'status' => 'pending',
                    'priority' => 2,
                    'latitude' => 14.7505,
                    'longitude' => -17.3338,
                    'scheduled_at' => now()->addDays(2)->setTime(14, 30),
                ],
                [
                    'client_uuid' => '20000000-0000-4000-8000-000000000003',
                    'client' => 'Hôpital de Pikine',
                    'address' => 'Rue 10, Pikine',
                    'description' => 'Vérifier le groupe de secours et effectuer un essai de démarrage.',
                    'equipment' => 'Groupe électrogène GE-118',
                    'status' => 'pending',
                    'priority' => 3,
                    'latitude' => 14.7543,
                    'longitude' => -17.3951,
                    'scheduled_at' => now()->addDays(3)->setTime(8, 30),
                ],
            ],
            'khadidiatou.ndiaye@gmail.com' => [
                [
                    'client_uuid' => '30000000-0000-4000-8000-000000000001',
                    'client' => 'Agence bancaire de Dakar-Plateau',
                    'address' => 'Place de l’Indépendance, Dakar',
                    'description' => 'Contrôler le raccordement réseau du serveur principal.',
                    'equipment' => 'Routeur réseau RT-410',
                    'status' => 'pending',
                    'priority' => 3,
                    'latitude' => 14.6687,
                    'longitude' => -17.4319,
                    'scheduled_at' => now()->addHours(6),
                ],
                [
                    'client_uuid' => '30000000-0000-4000-8000-000000000002',
                    'client' => 'Station de pompage de Guédiawaye',
                    'address' => 'Hamo 4, Guédiawaye',
                    'description' => 'Effectuer la maintenance du coffret de commande.',
                    'equipment' => 'Coffret de commande CP-15',
                    'status' => 'pending',
                    'priority' => 1,
                    'latitude' => 14.7761,
                    'longitude' => -17.3956,
                    'scheduled_at' => now()->addDays(3)->setTime(8, 0),
                ],
                [
                    'client_uuid' => '30000000-0000-4000-8000-000000000003',
                    'client' => 'Dépôt de bus de Ouakam',
                    'address' => 'Route de la Corniche, Ouakam',
                    'description' => 'Diagnostiquer la panne de la caméra de surveillance.',
                    'equipment' => 'Caméra IP CAM-06',
                    'status' => 'pending',
                    'priority' => 2,
                    'latitude' => 14.7223,
                    'longitude' => -17.4902,
                    'scheduled_at' => now()->addDays(4)->setTime(13, 0),
                ],
                [
                    'client_uuid' => '30000000-0000-4000-8000-000000000004',
                    'client' => 'Centre de données de Diamniadio',
                    'address' => 'Pôle urbain, Diamniadio',
                    'description' => 'Contrôler la climatisation de la salle des serveurs.',
                    'equipment' => 'Unité de refroidissement CR-31',
                    'status' => 'pending',
                    'priority' => 3,
                    'latitude' => 14.7179,
                    'longitude' => -17.2029,
                    'scheduled_at' => now()->addDays(5)->setTime(9, 0),
                ],
            ],
            'cheikh.tidiane@gmail.com' => [
                [
                    'client_uuid' => '40000000-0000-4000-8000-000000000001',
                    'client' => 'Atelier de maintenance de Liberté 6',
                    'address' => 'Liberté 6, Dakar',
                    'description' => 'Contrôler le tableau de distribution après une coupure électrique.',
                    'equipment' => 'Tableau électrique TD-28',
                    'status' => 'pending',
                    'priority' => 2,
                    'latitude' => 14.7196,
                    'longitude' => -17.4582,
                    'scheduled_at' => now()->addHours(3),
                ],
                [
                    'client_uuid' => '40000000-0000-4000-8000-000000000002',
                    'client' => 'Résidence des Almadies',
                    'address' => 'Route des Almadies, Dakar',
                    'description' => 'Inspecter la pompe de relevage et tester son système d’alarme.',
                    'equipment' => 'Pompe de relevage PR-11',
                    'status' => 'pending',
                    'priority' => 3,
                    'latitude' => 14.7445,
                    'longitude' => -17.5131,
                    'scheduled_at' => now()->addDays(2)->setTime(10, 0),
                ],
                [
                    'client_uuid' => '40000000-0000-4000-8000-000000000003',
                    'client' => 'École de Yoff',
                    'address' => 'Yoff, Dakar',
                    'description' => 'Vérifier le réseau informatique de la salle multimédia.',
                    'equipment' => 'Commutateur réseau SW-16',
                    'status' => 'pending',
                    'priority' => 1,
                    'latitude' => 14.7552,
                    'longitude' => -17.4897,
                    'scheduled_at' => now()->addDays(4)->setTime(9, 0),
                ],
            ],
        ];

        foreach ($assignments as $email => $interventions) {
            $technician = User::query()->where('email', $email)->firstOrFail();

            foreach ($interventions as $intervention) {
                $clientUuid = $intervention['client_uuid'];
                unset($intervention['client_uuid']);

                $technician->interventions()->updateOrCreate(
                    ['client_uuid' => $clientUuid],
                    $intervention,
                );
            }
        }
    }
}
