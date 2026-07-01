const { createClient } = require('@supabase/supabase-js');
const { HttpError } = require('./response');

let serviceClient;
let anonClient;

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) throw new HttpError(500, `服务端缺少环境变量：${name}`);
  return value;
}

function getSupabaseServiceClient() {
  if (!serviceClient) {
    serviceClient = createClient(
      requiredEnv('SUPABASE_URL'),
      requiredEnv('SUPABASE_SERVICE_ROLE_KEY'),
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    );
  }
  return serviceClient;
}

function getSupabaseAnonClient() {
  if (!anonClient) {
    anonClient = createClient(
      requiredEnv('SUPABASE_URL'),
      requiredEnv('SUPABASE_ANON_KEY'),
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    );
  }
  return anonClient;
}

module.exports = {
  getSupabaseAnonClient,
  getSupabaseServiceClient,
};
