self.addEventListener("push", (event) => {
  let data = {}
  try {
    data = event.data ? event.data.json() : {}
  } catch (_error) {
    data = { body: event.data ? event.data.text() : "" }
  }

  const title = data.title || "Flipflapp"
  const options = {
    body: data.body || "",
    icon: "/favicons/android-chrome-192x192.png",
    badge: "/favicons/favicon-32x32.png",
    data: { path: data.path || "/list" }
  }

  event.waitUntil(self.registration.showNotification(title, options))
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const path = (event.notification.data && event.notification.data.path) || "/list"

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        const clientPath = new URL(client.url).pathname
        if (clientPath === path && "focus" in client) {
          return client.focus()
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(path)
      }
    })
  )
})
