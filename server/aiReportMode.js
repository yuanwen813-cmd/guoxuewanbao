function cloudPollingEnabled() {
  return process.env.AI_CLOUD_POLLING_ENABLED !== 'false';
}

function usesNatalWorker(product) {
  return process.env.AI_NATAL_WORKER_ENABLED !== 'false'
    && /^(bazi|ziwei|tieban)_/.test(product.reportType);
}

module.exports = { cloudPollingEnabled, usesNatalWorker };
