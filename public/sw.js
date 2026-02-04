/* eslint-disable no-restricted-globals, no-console */
/* globals clients */

// Não interceptar requisições do Vite em desenvolvimento
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  
  // Ignorar requisições do Vite dev server
  if (url.port === '3036' || url.hostname.includes('vite') || url.pathname.startsWith('/@vite')) {
    return; // Deixa passar sem interceptar
  }
  
  // Ignorar WebSocket e outras requisições especiais
  if (event.request.url.startsWith('ws://') || 
      event.request.url.startsWith('wss://') ||
      url.protocol === 'chrome-extension:') {
    return; // Deixa passar sem interceptar
  }
});

self.addEventListener('push', event => {
  let notification = event.data && event.data.json();

  event.waitUntil(
    self.registration.showNotification(notification.title, {
      tag: notification.tag,
      data: {
        url: notification.url,
      },
    })
  );
});

self.addEventListener('notificationclick', event => {
  let notification = event.notification;

  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(windowClients => {
      let matchingWindowClients = windowClients.filter(
        client => client.url === notification.data.url
      );

      if (matchingWindowClients.length) {
        let firstWindow = matchingWindowClients[0];
        if (firstWindow && 'focus' in firstWindow) {
          firstWindow.focus();
          return;
        }
      }
      if (clients.openWindow) {
        clients.openWindow(notification.data.url);
      }
    })
  );
});
