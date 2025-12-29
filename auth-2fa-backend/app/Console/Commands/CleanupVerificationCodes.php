<?php

namespace App\Console\Commands;

use App\Models\VerificationCode;
use Illuminate\Console\Command;

class CleanupVerificationCodes extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = '2fa:cleanup 
                            {--expired : Clean up expired codes only}
                            {--old : Clean up old codes only}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clean up expired and old verification codes from the database';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $expiredOnly = $this->option('expired');
        $oldOnly = $this->option('old');

        $this->info('Starting 2FA verification codes cleanup...');

        $totalDeleted = 0;

        if (!$oldOnly) {
            $expiredDeleted = VerificationCode::cleanupExpiredCodes();
            $totalDeleted += $expiredDeleted;
            $this->info("Deleted {$expiredDeleted} expired verification codes");
        }

        if (!$expiredOnly) {
            $oldDeleted = VerificationCode::cleanupOldCodes();
            $totalDeleted += $oldDeleted;
            $this->info("Deleted {$oldDeleted} old verification codes (older than 24 hours)");
        }

        if ($totalDeleted > 0) {
            $this->info("Cleanup completed. Total deleted: {$totalDeleted} codes");
        } else {
            $this->info('No codes needed to be cleaned up.');
        }

        return Command::SUCCESS;
    }
}
