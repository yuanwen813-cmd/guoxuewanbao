/// 应用环境配置
enum AppEnv {
  development,
  staging,
  production;

  bool get isDev => this == development;
  bool get isStaging => this == staging;
  bool get isProd => this == production;

  String get baseUrl {
    switch (this) {
      case development:
        return 'https://api.deepseek.com';
      case staging:
        return 'https://staging-api.guoxueapp.com';
      case production:
        return 'https://api.guoxueapp.com';
    }
  }

  bool get useLocalKey => isDev; // 开发环境允许本地 API Key
}
