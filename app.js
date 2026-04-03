const STORAGE_KEY = 'printerShopDB_v2';
const SESSION_KEY = 'printerShopSession_v2';
const ADMIN_CODE = 'MPZ-ADMIN-2026';

function nowIso() {
  return new Date().toISOString();
}

function id(prefix) {
  if (window.crypto && crypto.randomUUID) {
    return `${prefix}-${crypto.randomUUID().slice(0, 8)}`;
  }
  return `${prefix}-${Math.random().toString(36).slice(2, 10)}`;
}

function currency(amount) {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 2,
  }).format(Number(amount || 0));
}

function formatDate(value) {
  if (!value) {
    return '-';
  }
  return new Date(value).toLocaleString('en-IN', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

function localDate(value) {
  const date = value ? new Date(value) : new Date();
  const offset = date.getTimezoneOffset();
  const normalized = new Date(date.getTime() - offset * 60000);
  return normalized.toISOString().slice(0, 10);
}

function seedDatabase() {
  return {
    users: [],
    orders: [],
    notifications: [],
    services: [
      {
        id: id('svc'),
        name: 'Document Printing',
        description: 'Black and white or color document printing for forms, notes, and office files.',
        price: 5,
        unit: 'per copy',
        createdAt: nowIso(),
      },
      {
        id: id('svc'),
        name: 'Photo Printing',
        description: 'Glossy and matte photo prints sized for personal and studio use.',
        price: 30,
        unit: 'per print',
        createdAt: nowIso(),
      },
      {
        id: id('svc'),
        name: 'Binding and Finishing',
        description: 'Spiral binding, cover sheets, and finishing for project submissions.',
        price: 60,
        unit: 'per order',
        createdAt: nowIso(),
      },
    ],
  };
}

function getDatabase() {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (!stored) {
    const fresh = seedDatabase();
    localStorage.setItem(STORAGE_KEY, JSON.stringify(fresh));
    return fresh;
  }

  const parsed = JSON.parse(stored);
  parsed.users = parsed.users || [];
  parsed.orders = parsed.orders || [];
  parsed.notifications = parsed.notifications || [];
  parsed.services = parsed.services && parsed.services.length ? parsed.services : seedDatabase().services;
  return parsed;
}

function saveDatabase(db) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(db));
}

async function hashPassword(password) {
  const encoder = new TextEncoder();
  const data = encoder.encode(password);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hash)).map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

function sanitizeText(value) {
  return String(value || '').trim();
}

function showBanner(message, type = 'info') {
  let banner = document.getElementById('appBanner');
  if (!banner) {
    banner = document.createElement('div');
    banner.id = 'appBanner';
    banner.className = 'banner';
    document.body.appendChild(banner);
  }

  banner.textContent = message;
  banner.className = `banner show ${type}`;
  clearTimeout(showBanner.timer);
  showBanner.timer = setTimeout(() => {
    banner.className = `banner ${type}`;
  }, 2400);
}

function setSession(user) {
  const token = id('session');
  const session = { token, userId: user.id, role: user.role, createdAt: nowIso() };
  localStorage.setItem(SESSION_KEY, JSON.stringify(session));
  return session;
}

function clearSession() {
  localStorage.removeItem(SESSION_KEY);
}

function getSession() {
  const raw = localStorage.getItem(SESSION_KEY);
  return raw ? JSON.parse(raw) : null;
}

function getCurrentUser() {
  const session = getSession();
  if (!session) {
    return null;
  }
  const db = getDatabase();
  return db.users.find((user) => user.id === session.userId) || null;
}

function requireAuth(role) {
  const user = getCurrentUser();
  if (!user) {
    window.location.href = 'auth.html';
    return null;
  }

  if (role && user.role !== role) {
    window.location.href = user.role === 'admin' ? 'admin.html' : 'customer.html';
    return null;
  }

  return user;
}

function upsertNotification(recipientId, message) {
  const db = getDatabase();
  addNotification(db, recipientId, message);
  saveDatabase(db);
}

function addNotification(db, recipientId, message) {
  db.notifications.unshift({
    id: id('note'),
    recipientId,
    message,
    status: 'UNREAD',
    timestamp: nowIso(),
  });
}

function getNotificationsForUser(userId, includeAdminInbox = false) {
  const db = getDatabase();
  return db.notifications
    .filter((note) => note.recipientId === userId || (includeAdminInbox && note.recipientId === 'admin'))
    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
}

function markNotificationsRead(userId, includeAdminInbox = false) {
  const db = getDatabase();
  let changed = false;
  db.notifications.forEach((note) => {
    if ((note.recipientId === userId || (includeAdminInbox && note.recipientId === 'admin')) && note.status === 'UNREAD') {
      note.status = 'READ';
      changed = true;
    }
  });
  if (changed) {
    saveDatabase(db);
  }
}

function getCustomers(db) {
  return db.users.filter((user) => user.role === 'customer');
}

function getService(db, serviceId) {
  return db.services.find((service) => service.id === serviceId);
}

function orderAmount(service, quantity) {
  return Number(service.price) * Number(quantity);
}

function orderView(order, db) {
  const user = db.users.find((item) => item.id === order.userId);
  const service = getService(db, order.serviceId);
  return {
    ...order,
    customerName: user ? user.name : 'Unknown customer',
    customerPhone: user ? user.phone : '-',
    customerEmail: user ? user.email : '-',
    serviceName: service ? service.name : 'Removed service',
  };
}

function computeStats(db, filterDate) {
  const orders = filterDate
    ? db.orders.filter((order) => localDate(order.createdAt) === filterDate)
    : db.orders;
  const completed = orders.filter((order) => order.status === 'COMPLETED');
  const pending = orders.filter((order) => order.status === 'PENDING' || order.status === 'ACCEPTED');
  const cancelled = orders.filter((order) => order.status === 'CANCELLED');
  const onlineTotal = completed.filter((order) => order.paymentType === 'ONLINE').reduce((sum, order) => sum + Number(order.amount || 0), 0);
  const offlineTotal = completed.filter((order) => order.paymentType === 'OFFLINE').reduce((sum, order) => sum + Number(order.amount || 0), 0);

  return {
    totalOrders: orders.length,
    pendingOrders: pending.length,
    completedOrders: completed.length,
    cancelledOrders: cancelled.length,
    onlineTotal,
    offlineTotal,
    totalRevenue: onlineTotal + offlineTotal,
    totalCustomers: getCustomers(db).length,
  };
}

function statusBadge(status) {
  const key = String(status || '').toLowerCase();
  return `<span class="status-badge status-${key}">${status || 'UNKNOWN'}</span>`;
}

function paymentBadge(paymentType) {
  const safe = String(paymentType || 'NOT_SELECTED').toLowerCase();
  return `<span class="payment-badge payment-${safe}">${paymentType || 'NOT_SELECTED'}</span>`;
}

function roleBadge(role) {
  const safe = String(role || '').toLowerCase();
  return `<span class="role-badge role-${safe}">${role || '-'}</span>`;
}

function notificationBadge(status) {
  const safe = String(status || '').toLowerCase();
  return `<span class="notice-badge notice-${safe}">${status}</span>`;
}

function toFileName(fileInput) {
  if (!fileInput || !fileInput.files || !fileInput.files.length) {
    return '';
  }
  return fileInput.files[0].name;
}

function ensureAdminRecipient() {
  const db = getDatabase();
  const hasAdmin = db.users.some((user) => user.role === 'admin');
  if (!hasAdmin) {
    return;
  }
  const existingAdminNotes = db.notifications.some((note) => note.recipientId === 'admin');
  if (!existingAdminNotes) {
    saveDatabase(db);
  }
}

window.PrinterShop = {
  ADMIN_CODE,
  addNotification,
  clearSession,
  computeStats,
  currency,
  ensureAdminRecipient,
  formatDate,
  getCurrentUser,
  getCustomers,
  getDatabase,
  getNotificationsForUser,
  getService,
  hashPassword,
  id,
  localDate,
  markNotificationsRead,
  nowIso,
  orderAmount,
  orderView,
  paymentBadge,
  requireAuth,
  roleBadge,
  sanitizeText,
  saveDatabase,
  setSession,
  showBanner,
  statusBadge,
  toFileName,
  upsertNotification,
  notificationBadge,
};
