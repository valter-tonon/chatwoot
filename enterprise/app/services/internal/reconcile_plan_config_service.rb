class Internal::ReconcilePlanConfigService
  def perform
    remove_premium_config_reset_warning
  end

  private

  def remove_premium_config_reset_warning
    Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
  end
end
