document.addEventListener('DOMContentLoaded', () => {
  const {
    ADMIN_CODE,
    getCurrentUser,
    getDatabase,
    hashPassword,
    sanitizeText,
    saveDatabase,
    setSession,
    showBanner,
  } = window.PrinterShop;

  const current = getCurrentUser();
  if (current) {
    window.location.href = current.role === 'admin' ? 'admin.html' : 'customer.html';
    return;
  }

  const loginTab = document.getElementById('loginTab');
  const registerTab = document.getElementById('registerTab');
  const formTitle = document.getElementById('formTitle');
  const formHint = document.getElementById('formHint');
  const nameWrap = document.getElementById('nameWrap');
  const phoneWrap = document.getElementById('phoneWrap');
  const confirmWrap = document.getElementById('confirmWrap');
  const secretWrap = document.getElementById('secretWrap');
  const nameInput = document.getElementById('nameInput');
  const phoneInput = document.getElementById('phoneInput');
  const emailInput = document.getElementById('emailInput');
  const passInput = document.getElementById('passInput');
  const confirmInput = document.getElementById('confirmInput');
  const roleInput = document.getElementById('roleInput');
  const secretInput = document.getElementById('secretInput');
  const submitBtn = document.getElementById('submitBtn');
  const helperText = document.getElementById('helperText');

  let mode = 'login';

  function updateRoleVisibility() {
    const needsSecret = roleInput.value === 'admin';
    secretWrap.classList.toggle('hidden', !needsSecret);
    if (!needsSecret) {
      secretInput.value = '';
    }
  }

  function renderMode(nextMode) {
    mode = nextMode;
    const isLogin = mode === 'login';

    loginTab.classList.toggle('active', isLogin);
    registerTab.classList.toggle('active', !isLogin);
    loginTab.classList.toggle('active-tab', isLogin);
    registerTab.classList.toggle('active-tab', !isLogin);

    nameWrap.classList.toggle('hidden', isLogin);
    phoneWrap.classList.toggle('hidden', isLogin);
    confirmWrap.classList.toggle('hidden', isLogin);

    formTitle.textContent = isLogin ? 'Login to your account' : 'Create your printer shop account';
    formHint.textContent = isLogin
      ? 'Use your email, password, and role to continue into the dashboard.'
      : 'Register as a customer or an admin. Admin accounts need the secret code.';
    submitBtn.textContent = isLogin ? 'Login' : 'Register';
    helperText.textContent = isLogin
      ? 'Admin login requires a valid secret code.'
      : 'Passwords are hashed in the browser before they are stored in local data.';

    updateRoleVisibility();
  }

  loginTab.addEventListener('click', () => renderMode('login'));
  registerTab.addEventListener('click', () => renderMode('register'));
  roleInput.addEventListener('change', updateRoleVisibility);

  submitBtn.addEventListener('click', async () => {
    const db = getDatabase();
    const name = sanitizeText(nameInput.value);
    const phone = sanitizeText(phoneInput.value);
    const email = sanitizeText(emailInput.value).toLowerCase();
    const password = sanitizeText(passInput.value);
    const confirmPassword = sanitizeText(confirmInput.value);
    const role = roleInput.value;
    const secretCode = sanitizeText(secretInput.value);

    if (!email || !password) {
      showBanner('Email and password are required.', 'error');
      return;
    }

    submitBtn.disabled = true;

    try {
      if (mode === 'register') {
        if (!name || !phone) {
          showBanner('Name and phone are required for registration.', 'error');
          return;
        }

        if (password !== confirmPassword) {
          showBanner('Passwords do not match.', 'error');
          return;
        }

        if (role === 'admin' && secretCode !== ADMIN_CODE) {
          showBanner('Invalid admin secret code.', 'error');
          return;
        }

        const exists = db.users.some((user) => user.email === email && user.role === role);
        if (exists) {
          showBanner(`A ${role} account with this email already exists.`, 'error');
          return;
        }

        const passwordHash = await hashPassword(password);
        db.users.push({
          id: window.PrinterShop.id('usr'),
          name,
          phone,
          email,
          passwordHash,
          role,
          createdAt: window.PrinterShop.nowIso(),
        });
        saveDatabase(db);
        showBanner('Registration successful. You can now login.', 'success');
        passInput.value = '';
        confirmInput.value = '';
        secretInput.value = '';
        renderMode('login');
        return;
      }

      const user = db.users.find((item) => item.email === email && item.role === role);
      if (!user) {
        showBanner(`No ${role} account found for this email.`, 'error');
        return;
      }

      const passwordHash = await hashPassword(password);
      if (user.passwordHash !== passwordHash) {
        showBanner('Invalid password.', 'error');
        return;
      }

      if (user.role === 'admin' && secretCode !== ADMIN_CODE) {
        showBanner('Invalid admin secret code.', 'error');
        return;
      }

      setSession(user);
      showBanner('Login successful.', 'success');
      setTimeout(() => {
        window.location.href = user.role === 'admin' ? 'admin.html' : 'customer.html';
      }, 500);
    } finally {
      submitBtn.disabled = false;
    }
  });

  renderMode('login');
});
