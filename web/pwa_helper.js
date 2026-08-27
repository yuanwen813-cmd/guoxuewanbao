(function () {
  'use strict';

  var installPrompt = null;
  var banner = null;

  async function removeLegacyFlutterCache() {
    if ('serviceWorker' in navigator) {
      var registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map(function (registration) {
        var worker = registration.active || registration.waiting || registration.installing;
        if (worker && worker.scriptURL.indexOf('/flutter_service_worker.js') !== -1) {
          return registration.unregister();
        }
        return Promise.resolve(false);
      }));
    }

    if ('caches' in window) {
      var cacheNames = await caches.keys();
      await Promise.all(cacheNames.map(function (name) {
        if (name.indexOf('flutter-app-') === 0 || name.indexOf('flutter-temp-') === 0) {
          return caches.delete(name);
        }
        return Promise.resolve(false);
      }));
    }
  }

  function createBanner() {
    if (banner) return banner;
    banner = document.createElement('div');
    banner.id = 'guoxue-pwa-banner';
    banner.setAttribute('role', 'status');
    banner.style.cssText = [
      'position:fixed',
      'left:12px',
      'right:12px',
      'bottom:88px',
      'z-index:2147483647',
      'display:none',
      'align-items:center',
      'gap:12px',
      'max-width:620px',
      'margin:0 auto',
      'padding:12px 14px',
      'border:1px solid rgba(156,111,37,.35)',
      'border-radius:8px',
      'background:#fffaf2',
      'color:#2d261f',
      'box-shadow:0 10px 28px rgba(45,38,31,.18)',
      'font:14px/1.5 system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif'
    ].join(';');
    document.body.appendChild(banner);
    return banner;
  }

  function showBanner(message, actionText, onAction, dismissKey) {
    if (dismissKey && sessionStorage.getItem(dismissKey) === '1') return;
    var node = createBanner();
    node.innerHTML = '';

    var text = document.createElement('div');
    text.style.cssText = 'flex:1;min-width:0';
    text.textContent = message;

    var action = document.createElement('button');
    action.type = 'button';
    action.textContent = actionText;
    action.style.cssText = 'border:0;border-radius:6px;padding:8px 12px;background:#9c2f2f;color:white;cursor:pointer;white-space:nowrap';
    action.addEventListener('click', onAction);

    var close = document.createElement('button');
    close.type = 'button';
    close.setAttribute('aria-label', '关闭提示');
    close.textContent = '×';
    close.style.cssText = 'border:0;background:transparent;color:#6d6258;font-size:22px;line-height:1;cursor:pointer';
    close.addEventListener('click', function () {
      node.style.display = 'none';
      if (dismissKey) sessionStorage.setItem(dismissKey, '1');
    });

    node.appendChild(text);
    node.appendChild(action);
    node.appendChild(close);
    node.style.display = 'flex';
  }

  window.addEventListener('beforeinstallprompt', function (event) {
    event.preventDefault();
    installPrompt = event;
    showBanner(
      '可将国学万宝匣安装到桌面，打开更方便。',
      '安装',
      async function () {
        if (!installPrompt) return;
        installPrompt.prompt();
        await installPrompt.userChoice;
        installPrompt = null;
        if (banner) banner.style.display = 'none';
      },
      'guoxue-install-dismissed'
    );
  });

  window.addEventListener('appinstalled', function () {
    installPrompt = null;
    if (banner) banner.style.display = 'none';
  });

  async function activateLatestVersion() {
    if ('caches' in window) {
      var cacheNames = await caches.keys();
      await Promise.all(cacheNames.map(function (name) { return caches.delete(name); }));
    }
    if ('serviceWorker' in navigator) {
      var registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map(function (registration) {
        return registration.unregister();
      }));
    }
    location.replace('/?app_update=' + Date.now());
  }

  function watchRegistration(registration) {
    if (!registration) return;
    registration.addEventListener('updatefound', function () {
      var worker = registration.installing;
      if (!worker) return;
      worker.addEventListener('statechange', function () {
        if (worker.state === 'installed' && navigator.serviceWorker.controller) {
          showBanner(
            '发现新版本，更新后可继续使用最新功能。',
            '立即更新',
            activateLatestVersion,
            null
          );
        }
      });
    });
  }

  if ('serviceWorker' in navigator) {
    window.addEventListener('load', async function () {
      await removeLegacyFlutterCache().catch(function () {});
      var registration = await navigator.serviceWorker.getRegistration();
      watchRegistration(registration);
      if (registration) registration.update().catch(function () {});
    });
    document.addEventListener('visibilitychange', async function () {
      if (document.visibilityState !== 'visible') return;
      var registration = await navigator.serviceWorker.getRegistration();
      if (registration) registration.update().catch(function () {});
    });
  }
})();
