<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'two_factor_enabled',
        'two_factor_method',
        'two_factor_secret',
        'two_factor_recovery_codes',
        'two_factor_confirmed_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_secret',
        'two_factor_recovery_codes',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'two_factor_confirmed_at' => 'datetime',
        'two_factor_enabled' => 'boolean',
        'password' => 'hashed',
    ];

    public function verificationCodes()
    {
        return $this->hasMany(VerificationCode::class);
    }

    public function hasTwoFactorEnabled(): bool
    {
        return $this->two_factor_enabled && $this->two_factor_method !== 'none';
    }

    public function getRecoveryCodesArray(): array
    {
        return $this->two_factor_recovery_codes 
            ? json_decode($this->two_factor_recovery_codes, true) 
            : [];
    }

    public function setRecoveryCodesArray(array $codes): void
    {
        $this->two_factor_recovery_codes = json_encode($codes);
    }
}