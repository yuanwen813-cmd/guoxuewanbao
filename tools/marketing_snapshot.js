'use strict';

// Read only aggregate counts. Never select phones, tokens, profiles or reports.
const fs = require('node:fs');
const path = require('node:path');
const { createClient } = require('@supabase/supabase-js');

async function main() {
  process.loadEnvFile(path.join(__dirname, '..', '.env.local'));
  const campaign = process.argv[2] || 'yarrow_20261008';
  const since = process.argv[3] || '2026-10-08T00:00:00+08:00';
  if (!/^[a-z0-9_-]{1,80}$/.test(campaign) || !Number.isFinite(Date.parse(since))) {
    throw new Error('Invalid campaign or start timestamp');
  }
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error('Missing local database configuration');
  const client = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const queries = {
    totalRegisteredAccounts: client.from('app_users').select('id', { count: 'exact', head: true }),
    registeredAccountsSinceStart: client.from('app_users').select('id', { count: 'exact', head: true }).gte('created_at', since),
    firstAttributedCampaignAccounts: client.from('user_attributions').select('user_id', { count: 'exact', head: true }).eq('first_campaign', campaign),
    latestAttributedCampaignAccounts: client.from('user_attributions').select('user_id', { count: 'exact', head: true }).eq('latest_campaign', campaign),
    newAccountsWithFirstCampaign: client.from('user_attributions').select('user_id,app_users!inner(created_at)', { count: 'exact', head: true }).eq('first_campaign', campaign).gte('app_users.created_at', since),
  };
  const snapshot = {
    capturedAt: new Date().toISOString(), campaign, since,
    measurementNote: 'Authenticated attribution only. Counts exclude anonymous visits and do not prove causal acquisition. First and latest attribution are different metrics.',
    counts: {},
  };
  for (const [name, query] of Object.entries(queries)) {
    const { count, error } = await query;
    snapshot.counts[name] = error ? null : count;
    if (error) {
      snapshot.errors ||= {};
      snapshot.errors[name] = { code: error.code || 'query_failed', message: 'Aggregate query unavailable' };
    }
  }
  const output = process.argv[4];
  if (output) {
    const target = path.resolve(output);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, JSON.stringify(snapshot, null, 2) + '\n');
  }
  console.log(JSON.stringify(snapshot, null, 2));
}

main().catch(() => {
  console.error('Marketing aggregate snapshot unavailable; configuration, network or query failed. No credentials were printed.');
  process.exitCode = 1;
});
