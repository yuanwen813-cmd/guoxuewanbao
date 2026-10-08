function cloudPollingEnabled() {
  return process.env.AI_CLOUD_POLLING_ENABLED !== 'false';
}

module.exports = { cloudPollingEnabled };
