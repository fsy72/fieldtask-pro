<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $technicians = [
            [
                'name' => 'Fieldtask Pro',
                'email' => 'fieldtask.pro@gmail.com',
                'password' => 'password_pro123',
            ],
            [
                'name' => 'Fallou SY',
                'email' => 'fallou.sy@gmail.com',
                'password' => 'technicien123',
            ],
            [
                'name' => 'Khadidiatou NDIAYE',
                'email' => 'khadidiatou.ndiaye@gmail.com',
                'password' => 'technicien123',
            ],
            [
                'name' => 'Cheikh Tidiane',
                'email' => 'cheikh.tidiane@gmail.com',
                'password' => 'technicien123',
            ],
        ];

        User::query()
            ->whereIn('email', ['awa.fall@gmail.com', 'mamadou.diop@gmail.com'])
            ->delete();

        foreach ($technicians as $technician) {
            User::query()->updateOrCreate(
                ['email' => $technician['email']],
                [
                    'name' => $technician['name'],
                    'password' => Hash::make($technician['password']),
                ],
            );
        }

        $this->call(InterventionSeeder::class);
    }
}
